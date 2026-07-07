# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.core_api
# --   Reusable APIs for advanced experiment programs.
# --
# --   The GUI still owns SPI controls, filter controls, and sequence file loading.
# --   This module accepts already-loaded sequence dictionaries and provides common
# --   building blocks for pulse-generator programming, tracing/DMA configuration,
# --   per-scan sequence transforms, phase cycling, acquisition and visualization.
# ----------------------------------------------------------------------------------

from __future__ import annotations

from dataclasses import dataclass
import time 
import copy
import json
import math
import os
import tempfile
from typing import Callable, Iterable

import numpy as np

from . import fpga_mri
from .experiment_control import ExperimentConfig, sleep_for_tr


BASE_CLOCK_HZ = 100_000_000.0


@dataclass(frozen=True)
class TracingConfig:
    """Tracing/DMA acquisition settings derived from sequence + clock divider."""

    clock_div: int
    nr_rx: int
    nr_samples: int
    total_rx_us: float = 0.0
    total_rx_samples: int = 0
    trigger_mode: int = 1

    @property
    def sample_rate_hz(self) -> float:
        return BASE_CLOCK_HZ / max(1, int(self.clock_div))

    @property
    def dt_us(self) -> float:
        return max(1, int(self.clock_div)) / 100.0

    @property
    def dma_words(self) -> int:
        return max(1, int(self.nr_rx) * int(self.nr_samples) * 2)

    @property
    def dma_samples_per_channel(self) -> int:
        return max(1, int(self.nr_rx) * int(self.nr_samples))


@dataclass(frozen=True)
class ScanContext:
    """Per-scan context passed into user sequence-transform callbacks."""

    loop_idx: int
    avg_idx: int
    scan_idx: int
    total_scans: int
    config: ExperimentConfig
    tracing: TracingConfig


@dataclass
class ScanResult:
    """Acquisition data after one hardware sequence execution."""

    context: ScanContext
    ch0: np.ndarray
    ch1: np.ndarray
    avg_ch0: np.ndarray
    avg_ch1: np.ndarray


def _as_int(value, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return int(default)


def _as_float(value, default: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(default)


def _ordered_section_rows(seq_dict: dict) -> list[tuple[int, str, dict]]:
    rows = []
    for idx, (key, sec) in enumerate(seq_dict.get('SectionConfig', {}).items()):
        sid = _as_int(sec.get('section_id', idx), idx)
        rows.append((sid, key, sec))
    return sorted(rows, key=lambda row: row[0])


def executed_section_ids(seq_dict: dict) -> list[int]:
    """Return section IDs in the order the pulse generator executes them."""
    rows = _ordered_section_rows(seq_dict)
    if not rows:
        return []

    exp = seq_dict.get('ExpConfig', {})
    nr_sections = max(1, _as_int(exp.get('nr_sections', len(rows)), len(rows)))
    bounded_rows = [row for row in rows if 0 <= row[0] < nr_sections]
    if bounded_rows:
        rows = bounded_rows

    section_ids = [sid for sid, _, _ in rows]
    id_to_index = {sid: idx for idx, sid in enumerate(section_ids)}

    start_ptr = _as_int(exp.get('start_repeat_pointer', 0), 0)
    end_ptr = _as_int(exp.get('end_repeat_pointer', len(section_ids) - 1),
                      len(section_ids) - 1)
    cycle_count = max(1, _as_int(exp.get('cycle_repetition_number', 1), 1))
    experiment_count = max(1, _as_int(exp.get('experiment_repetition_number', 1), 1))

    if start_ptr in id_to_index:
        start_idx = id_to_index[start_ptr]
    elif 0 <= start_ptr < len(section_ids):
        start_idx = start_ptr
    else:
        start_idx = 0

    if end_ptr in id_to_index:
        end_idx = id_to_index[end_ptr]
    elif 0 <= end_ptr < len(section_ids):
        end_idx = end_ptr
    else:
        end_idx = len(section_ids) - 1

    if end_idx < start_idx:
        one_experiment = section_ids
    else:
        one_experiment = (
            section_ids[:start_idx]
            + section_ids[start_idx:end_idx + 1] * cycle_count
            + section_ids[end_idx + 1:]
        )
    return one_experiment * experiment_count


def rx_windows_from_sequence(seq_dict: dict) -> list[dict]:
    """Return executed RX windows with section ID and duration in microseconds."""
    rows = _ordered_section_rows(seq_dict)
    sections_by_id = {sid: sec for sid, _, sec in rows}
    windows = []
    for sid in executed_section_ids(seq_dict):
        sec = sections_by_id.get(sid)
        if not sec or _as_int(sec.get('section_type', 2), 2) != 1:
            continue
        duration_us = max(0.0, _as_float(sec.get('delay', 0.0), 0.0))
        windows.append({'section_id': sid, 'duration_us': duration_us})
    return windows


def total_rx_time_us(seq_dict: dict) -> float:
    return sum(win['duration_us'] for win in rx_windows_from_sequence(seq_dict))


def _samples_for_duration_us(duration_us: float, clock_div: int) -> int:
    n = duration_us * BASE_CLOCK_HZ / 1_000_000.0 / max(1, int(clock_div))
    return max(0, int(math.ceil(n)))


def rx_sampling_summary(seq_dict: dict, clock_div: int, fallback: int) -> dict:
    """Calculate RX-driven tracing/DMA settings for the executed sequence."""
    div = max(1, int(clock_div))
    windows = rx_windows_from_sequence(seq_dict)
    window_samples = [
        _samples_for_duration_us(win['duration_us'], div)
        for win in windows
    ]
    positive = [n for n in window_samples if n > 0]
    nr_rx = max(1, len(windows))
    fallback = max(1, int(fallback))
    nr_samples = max(positive) if positive else fallback
    total_rx_samples = sum(positive) if positive else fallback
    total_rx_us_value = sum(win['duration_us'] for win in windows)

    return {
        'clock_div': div,
        'sample_rate_hz': BASE_CLOCK_HZ / div,
        'dt_us': div / 100.0,
        'rx_windows': len(windows),
        'nr_rx': nr_rx,
        'nr_samples': nr_samples,
        'total_rx_us': total_rx_us_value,
        'total_rx_samples': max(1, int(total_rx_samples)),
        'dma_samples_per_channel': max(1, nr_rx * nr_samples),
        'dma_words': max(1, nr_rx * nr_samples * 2),
    }


def nr_rx_from_sequence(seq_dict: dict) -> int:
    return max(1, len(rx_windows_from_sequence(seq_dict)))


def copy_sequence(seq_dict: dict) -> dict:
    """Deep-copy a sequence dictionary before software-side edits."""
    return copy.deepcopy(seq_dict)


def find_section(seq_dict: dict, section: int | str) -> dict:
    """Find a section by dictionary key or by numeric section_id."""
    sections = seq_dict.get('SectionConfig', {})
    if isinstance(section, str):
        if section not in sections:
            raise KeyError(f"Section key not found: {section}")
        return sections[section]

    wanted = int(section)
    for sec in sections.values():
        if int(sec.get('section_id', -1)) == wanted:
            return sec
    raise KeyError(f"Section ID not found: {wanted}")


def set_section_delay(seq_dict: dict, section: int | str, delay_us: float) -> dict:
    find_section(seq_dict, section)['delay'] = float(delay_us)
    return seq_dict


def set_section_field(seq_dict: dict, section: int | str,
                      field: str, value) -> dict:
    find_section(seq_dict, section)[field] = value
    return seq_dict


def set_section_phase(seq_dict: dict, section: int | str, *,
                      phase_ch0: float | None = None,
                      phase_ch1: float | None = None) -> dict:
    sec = find_section(seq_dict, section)
    if phase_ch0 is not None:
        sec['phase_ch0'] = float(phase_ch0) % 360
    if phase_ch1 is not None:
        sec['phase_ch1'] = float(phase_ch1) % 360
    return seq_dict


def set_section_gradient(seq_dict: dict, section: int | str, *,
                         x: int | None = None,
                         y: int | None = None,
                         z: int | None = None) -> dict:
    sec = find_section(seq_dict, section)
    if x is not None:
        sec['x_gradient'] = int(x)
    if y is not None:
        sec['y_gradient'] = int(y)
    if z is not None:
        sec['z_gradient'] = int(z)
    return seq_dict


def nr_samples_for_sequence(seq_dict: dict, clock_div: int, fallback: int) -> int:
    """Samples per RX pulse, sized from the longest executed RX section."""
    return int(rx_sampling_summary(seq_dict, clock_div, fallback)['nr_samples'])


def tracing_config_from_sequence(seq_dict: dict, clock_div: int,
                                 fallback_samples: int) -> TracingConfig:
    summary = rx_sampling_summary(seq_dict, clock_div, fallback_samples)
    return TracingConfig(
        clock_div=summary['clock_div'],
        nr_rx=summary['nr_rx'],
        nr_samples=summary['nr_samples'],
        total_rx_us=summary['total_rx_us'],
        total_rx_samples=summary['total_rx_samples'],
        trigger_mode=1,
    )


def configure_tracing_and_dma(hw, tracing: TracingConfig) -> TracingConfig:
    """Apply tracing registers and ensure the receive buffer size is ready."""
    hw.osci_clock_step_size(tracing.clock_div)
    hw.osci_set_nr_samples(tracing.nr_samples)
    hw.osci_set_stream_nr_rx_pulse(tracing.nr_rx)
    hw.osci_type_stream(tracing.trigger_mode)
    hw.ensure_buffers(tracing.dma_words)
    return tracing


PULSE_GEN_REGISTER_MAP = (
    ('sequence_generator_en', fpga_mri.C_SEQUENCE_GENERATOR_EN),
    ('nr_sections', fpga_mri.C_SET_NR_SECTIONS),
    ('write_sel_section', fpga_mri.C_WRITE_SEL_SECTION),
    ('section_type_last_write', fpga_mri.C_SET_SECTION_TYPE),
    ('delay_last_write_clocks', fpga_mri.C_SET_DELAY),
    ('mux_last_write', fpga_mri.C_SET_MUX),
    ('start_repeat_pointer', fpga_mri.C_SET_START_REPEAT_POINTER),
    ('end_repeat_pointer', fpga_mri.C_SET_END_REPEAT_POINTER),
    ('cycle_repetition_number', fpga_mri.C_SET_CYCLE_REPETITION_NUMBER),
    ('experiment_repetition_number', fpga_mri.C_SET_EXPERIMENT_REPETITION_NUMBER),
    ('busy', fpga_mri.C_GET_BUSY),
    ('data_ready', fpga_mri.C_GET_DATA_READY),
    ('nr_dds_ch', fpga_mri.C_GET_NR_DDS_CH),
    ('mem_depth', fpga_mri.C_GET_MEM_DEPTH),
    ('nr_activity', fpga_mri.C_GET_NR_ACTIVITY),
    ('commit_section', fpga_mri.C_COMMIT_SECTION),
    ('readback_section', fpga_mri.C_READBACK_SECTION),
    ('readback_word', fpga_mri.C_READBACK_WORD),
    ('readback_data', fpga_mri.C_READBACK_DATA),
)


def pulse_gen_register_snapshot(hw_or_ip) -> dict:
    """Read the public pulse-generator AXI registers.

    This includes scalar setup/status registers plus the section-RAM readback
    selector/data window.
    """
    ip = getattr(hw_or_ip, 'pulse_gen', hw_or_ip)
    return {name: int(ip.read(addr)) for name, addr in PULSE_GEN_REGISTER_MAP}


SECTION_RAM_WORDS = fpga_mri.SECTION_WORDS


def _section_word_index(word) -> int:
    if isinstance(word, str):
        if word not in fpga_mri.SECTION_WORD_INDEX:
            raise KeyError(f"Unknown section word: {word}")
        return fpga_mri.SECTION_WORD_INDEX[word]

    index = int(word)
    if index < 0 or index >= fpga_mri.EXPECTED_NR_ACTIVITY:
        raise ValueError(
            f"Section word index must be 0..{fpga_mri.EXPECTED_NR_ACTIVITY - 1}, "
            f"got {index}."
        )
    return index


def pulse_gen_section_word(hw_or_ip, section_id: int, word) -> int:
    """Read one committed section-RAM word from the pulse generator."""
    ip = getattr(hw_or_ip, 'pulse_gen', hw_or_ip)
    ip.write(fpga_mri.C_READBACK_SECTION, int(section_id))
    ip.write(fpga_mri.C_READBACK_WORD, _section_word_index(word))
    return int(ip.read(fpga_mri.C_READBACK_DATA))


def pulse_gen_section_readback(hw_or_ip, section_id: int) -> dict:
    """Read all committed words for one section from section RAM."""
    return {
        name: pulse_gen_section_word(hw_or_ip, section_id, index)
        for index, name in enumerate(fpga_mri.SECTION_WORDS)
    }


def pulse_gen_sequence_readback(hw_or_ip, nr_sections: int) -> list[dict]:
    """Read all committed section-RAM records from section 0 upward."""
    rows = []
    for section_id in range(int(nr_sections)):
        row = {'section_id': section_id}
        row.update(pulse_gen_section_readback(hw_or_ip, section_id))
        rows.append(row)
    return rows


def sequence_timing_table(seq_dict: dict) -> list[dict]:
    """Return sorted section timing rows from a sequence dictionary."""
    rows = []
    t_start = 0.0
    type_label = {0: 'TX', 1: 'RX', 2: 'DELAY'}
    sections = sorted(
        seq_dict.get('SectionConfig', {}).items(),
        key=lambda item: int(item[1].get('section_id', -1)),
    )
    for key, sec in sections:
        sid = int(sec.get('section_id', -1))
        stype = int(sec.get('section_type', 2))
        delay_us = float(sec.get('delay', 0.0))
        rows.append({
            'section_id': sid,
            'key': key,
            'type': type_label.get(stype, str(stype)),
            't_start_us': t_start,
            'delay_us': delay_us,
            'phase_ch0': float(sec.get('phase_ch0', 0.0)),
            'mux': int(sec.get('mux', 0)),
        })
        t_start += delay_us
    return rows


def parse_sequence_dict(seq_dict: dict, runtime_tmp_dir: str):
    """Parse an in-memory sequence dict through the existing JSON parser."""
    os.makedirs(runtime_tmp_dir, exist_ok=True)
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile('w', suffix='.json', dir=runtime_tmp_dir,
                                         delete=False) as tmp:
            json.dump(seq_dict, tmp)
            tmp_path = tmp.name
        return fpga_mri.parse_json(tmp_path)
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)


def sequence_object_from_dict(hw_or_ip, seq_dict: dict, runtime_tmp_dir: str):
    ip = getattr(hw_or_ip, 'pulse_gen', hw_or_ip)
    exp_arr, sec_list = parse_sequence_dict(seq_dict, runtime_tmp_dir)
    seq = fpga_mri.MRI_Sequence(ip, exp_arr, sec_list)
    seq.read_ExpConfig()
    return seq


def program_pulse_generator(hw, seq_dict: dict, runtime_tmp_dir: str):
    """Parse a sequence dictionary and write it to the pulse generator."""
    seq = sequence_object_from_dict(hw, seq_dict, runtime_tmp_dir)
    seq.stop_sequence()
    seq.write_ExpConfig()
    time.sleep(0.5)
    seq.write_all_Sections()
    # time.sleep(2)
    return seq


def write_one_section(hw_or_ip, seq_dict: dict, section: int | str, runtime_tmp_dir: str):
    """Write one updated section from seq_dict to pulse-generator RAM.

    Use after the full sequence has already been programmed. This does not
    rewrite ExpConfig and does not touch unrelated section RAM entries.
    """
    sec = find_section(seq_dict, section)
    section_id = int(sec.get('section_id'))
    seq = sequence_object_from_dict(hw_or_ip, seq_dict, runtime_tmp_dir)
    seq.write_one_Section(section_id)
    return section_id


def acquire_preprogrammed_scan(hw, sequence_obj, seq_dict: dict, config: ExperimentConfig,
                               *, fallback_samples: int, scan_idx: int = 0,
                               total_scans: int = 1) -> ScanResult:
    """Acquire one scan from an already-programmed pulse-generator sequence."""
    tracing = tracing_config_from_sequence(seq_dict, config.clock_div, fallback_samples)
    configure_tracing_and_dma(hw, tracing)
    context = ScanContext(
        loop_idx=scan_idx,
        avg_idx=0,
        scan_idx=scan_idx,
        total_scans=total_scans,
        config=config,
        tracing=tracing,
    )
    ch0, ch1 = hw.acquire(
        sequence_obj,
        nr_rx=tracing.nr_rx,
        nr_samples=tracing.nr_samples,
        clock_div=tracing.clock_div,
    )
    avg_ch0 = ch0.astype(float)
    avg_ch1 = ch1.astype(float)
    return ScanResult(context, ch0, ch1, avg_ch0, avg_ch1)


def phase_cycle_sequence(seq_dict: dict, section_ids: Iterable[int],
                         scan_idx: int) -> dict:
    """Return a copy with +90-degree phase steps on selected section IDs."""
    selected = {int(s) for s in section_ids}
    if not selected:
        raise ValueError("Phase cycling is enabled but no section IDs were provided.")

    shifted = copy.deepcopy(seq_dict)
    found = set()
    phase_shift = ((int(scan_idx) + 1) * 90) % 360

    for sec in shifted.get('SectionConfig', {}).values():
        sid = int(sec.get('section_id', -1))
        if sid not in selected:
            continue
        found.add(sid)
        sec['phase_ch0'] = (float(sec.get('phase_ch0', 0)) + phase_shift) % 360
        sec['phase_ch1'] = (float(sec.get('phase_ch1', 0)) + phase_shift) % 360

    missing = sorted(selected - found)
    if missing:
        raise ValueError(f"Phase-cycle section IDs not found in sequence: {missing}")
    return shifted


def render_pulse_view(seq_dict: dict, runtime_tmp_dir: str, *,
                      save_path: str | None = None, dpi: int = 150,
                      show: bool = False):
    """Render the existing fpga_mri pulse diagram for a sequence dictionary."""
    os.makedirs(runtime_tmp_dir, exist_ok=True)
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile('w', suffix='.json', dir=runtime_tmp_dir,
                                         delete=False) as tmp:
            json.dump(seq_dict, tmp)
            tmp_path = tmp.name
        exp_arr, sec_list = fpga_mri.parse_json(tmp_path)
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)

    seq = fpga_mri.MRI_Sequence(None, exp_arr, sec_list)
    return seq.visualize_sequence(dpi=dpi, save_path=save_path, show=show)


SequenceTransform = Callable[[dict, ScanContext], dict]
ScanCallback = Callable[[ScanResult], None]
ProgressCallback = Callable[[int, int], None]


class AdvancedExperimentRunner:
    """Composable runner for GUI and notebook-defined advanced experiments."""

    def __init__(self, hw, runtime_tmp_dir: str):
        self.hw = hw
        self.runtime_tmp_dir = runtime_tmp_dir

    def run_sequence(
        self,
        seq_dict: dict,
        config: ExperimentConfig,
        *,
        fallback_samples: int,
        preprogrammed_sequence_obj=None,
        sequence_transform: SequenceTransform | None = None,
        scan_callback: ScanCallback | None = None,
        progress_callback: ProgressCallback | None = None,
        dynamic_tracing: bool = False,
        stop_flag=None,
    ) -> tuple[np.ndarray | None, np.ndarray | None]:
        base_tracing = tracing_config_from_sequence(
            seq_dict, config.clock_div, fallback_samples)
        configure_tracing_and_dma(self.hw, base_tracing)

        base_sequence_obj = None
        if (not dynamic_tracing and not config.phase_cycling_enabled
                and sequence_transform is None):
            base_sequence_obj = preprogrammed_sequence_obj
            if base_sequence_obj is None:
                base_sequence_obj = program_pulse_generator(
                    self.hw, seq_dict, self.runtime_tmp_dir)

        avg_ch0 = avg_ch1 = None
        total = config.total_scans

        for loop_idx in range(config.loop_count):
            for avg_idx in range(config.num_averages):
                if stop_flag is not None and stop_flag.is_set():
                    return avg_ch0, avg_ch1

                scan_idx = loop_idx * config.num_averages + avg_idx
                context = ScanContext(
                    loop_idx=loop_idx,
                    avg_idx=avg_idx,
                    scan_idx=scan_idx,
                    total_scans=total,
                    config=config,
                    tracing=base_tracing,
                )

                seq_for_scan = seq_dict
                if sequence_transform is not None:
                    seq_for_scan = sequence_transform(copy.deepcopy(seq_for_scan), context)
                if config.phase_cycling_enabled:
                    seq_for_scan = phase_cycle_sequence(
                        seq_for_scan, config.phase_cycle_sections, scan_idx)

                tracing = base_tracing
                if dynamic_tracing:
                    tracing = tracing_config_from_sequence(
                        seq_for_scan, config.clock_div, fallback_samples)
                    configure_tracing_and_dma(self.hw, tracing)
                    context = ScanContext(
                        loop_idx=loop_idx,
                        avg_idx=avg_idx,
                        scan_idx=scan_idx,
                        total_scans=total,
                        config=config,
                        tracing=tracing,
                    )

                sequence_obj = base_sequence_obj
                if sequence_obj is None:
                    sequence_obj = program_pulse_generator(
                        self.hw, seq_for_scan, self.runtime_tmp_dir)

                ch0, ch1 = self.hw.acquire(
                    sequence_obj,
                    nr_rx=tracing.nr_rx,
                    nr_samples=tracing.nr_samples,
                    clock_div=tracing.clock_div,
                )

                if avg_ch0 is None:
                    avg_ch0 = ch0.astype(float)
                    avg_ch1 = ch1.astype(float)
                else:
                    avg_ch0 = (avg_ch0 * scan_idx + ch0) / (scan_idx + 1)
                    avg_ch1 = (avg_ch1 * scan_idx + ch1) / (scan_idx + 1)

                if scan_callback is not None:
                    scan_callback(ScanResult(context, ch0, ch1, avg_ch0, avg_ch1))
                if progress_callback is not None:
                    progress_callback(scan_idx + 1, total)
                if scan_idx + 1 < total:
                    sleep_for_tr(config, stop_flag)

        return avg_ch0, avg_ch1
