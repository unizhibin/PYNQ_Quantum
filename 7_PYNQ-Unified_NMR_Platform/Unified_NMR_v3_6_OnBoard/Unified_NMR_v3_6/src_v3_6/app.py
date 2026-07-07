# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.app
# --   GUI orchestrator for the MRI_PG2_1_Rev1 / MRI_Rev3 overlay.
# --
# --   *** No hardware imports at module level ***  PYNQ access is deferred until
# --   the "Initialise FPGA" button is pressed, so importing this module never
# --   loads a bitstream or crashes the kernel.
# --
# --   Launch (single notebook cell):
# --       import src_v3_6.app as gui
# --       display(gui.GUI_total)
# --
# --   Layout:  Header · FPGA-init accordion · Experiment controls ·
# --            Tab(Hardware|Sequence|Auto-Shim|Analysis) · HBox(time plot | FFT/T2 plot)
# ----------------------------------------------------------------------------------

import copy
import json
import os
import threading

import numpy as np
import ipywidgets as widgets

from . import mri_overlay
from . import core_api
from . import gui_state as gui_state_module
from . import gui_styles as gs
from . import data_io
from . import gui_hardware_panel as hw_module
from . import gui_sequence_panel as seq_module
from . import gui_shim_panel as shim_module
from . import gui_experiment_panel as exp_module
from . import gui_analysis_panel as ana_module
from . import gui_plot_panel as plot_module
from .experiment_control import ExperimentConfig

_SRC_V36_DIR = os.path.dirname(os.path.abspath(__file__))
_RUNTIME_TMP_DIR = os.path.join(_SRC_V36_DIR, '_runtime_tmp')
# _BITFILE = 'Unified_NMR_v1.5_rev4.bit'
_BITFILE = 'Unified_NMR_v1.6_rev2_mod3.bit'
# Public software label; package name src_v3_6 is kept for notebook compatibility.
_SOFTWARE_VERSION = 'v3.6'
_AUTHOR_NAMES = 'Yitian Chen, Zhibin Zhao, Yichao Peng'
_LOGO_FILES = ('logo_iis_blue.png', 'logo_iis.png')
_loaded_sequence_obj = None
_loaded_sequence_signature: str | None = None


def runtime_tmp_dir() -> str:
    return _RUNTIME_TMP_DIR


def get_clock_div() -> int:
    return _hw_panel.get_clock_div()


def get_nr_samples() -> int:
    return _hw_panel.get_nr_samples()


def get_current_sequence(*, copy_sequence: bool = True) -> dict:
    """Return the sequence currently loaded/visualized in the GUI."""
    seq = _seq_panel.get_current_sequence()
    if not seq:
        raise RuntimeError("No sequence loaded in the GUI.")
    return copy.deepcopy(seq) if copy_sequence else seq


def get_current_sequence_source() -> str:
    return _seq_panel.get_current_sequence_source()


def require_initialized_overlay():
    hw = mri_overlay.get_overlay()
    if not hw.initialized:
        raise RuntimeError("Initialise FPGA from the GUI before running hardware APIs.")
    return hw


def make_runner(hw=None) -> core_api.AdvancedExperimentRunner:
    return core_api.AdvancedExperimentRunner(hw or require_initialized_overlay(),
                                             _RUNTIME_TMP_DIR)


def _sequence_signature(seq_dict: dict | None) -> str | None:
    if seq_dict is None:
        return None
    return json.dumps(seq_dict, sort_keys=True, separators=(',', ':'))


def _remember_loaded_sequence(seq_dict: dict, sequence_obj) -> None:
    global _loaded_sequence_obj, _loaded_sequence_signature
    _loaded_sequence_obj = sequence_obj
    _loaded_sequence_signature = _sequence_signature(seq_dict)


def _clear_loaded_sequence() -> None:
    global _loaded_sequence_obj, _loaded_sequence_signature
    _loaded_sequence_obj = None
    _loaded_sequence_signature = None


def _matching_loaded_sequence(seq_dict: dict | None):
    if _loaded_sequence_obj is None:
        return None
    if _sequence_signature(seq_dict) != _loaded_sequence_signature:
        return None
    return _loaded_sequence_obj


def get_loaded_sequence_obj(seq_dict: dict | None = None):
    """Return the pulse-generator object programmed by the GUI load/apply path."""
    source_seq = seq_dict if seq_dict is not None else get_current_sequence(copy_sequence=False)
    sequence_obj = _matching_loaded_sequence(source_seq)
    if sequence_obj is None:
        raise RuntimeError(
            'No matching GUI-programmed sequence object. Load/apply this sequence in the GUI first.'
        )
    return sequence_obj


def read_loaded_pulse_gen_sections() -> list[dict]:
    """Read committed pulse-generator section RAM for the GUI-loaded sequence."""
    hw = require_initialized_overlay()
    seq = get_current_sequence(copy_sequence=False)
    nr_sections = len(seq.get('SectionConfig', {}))
    return core_api.pulse_gen_sequence_readback(hw, nr_sections)


def read_pulse_gen_section(section_id: int) -> dict:
    """Read one committed pulse-generator section RAM record."""
    return core_api.pulse_gen_section_readback(require_initialized_overlay(), section_id)


def read_pulse_gen_registers() -> dict:
    """Read pulse-generator setup/status AXI registers from the loaded overlay."""
    return core_api.pulse_gen_register_snapshot(require_initialized_overlay())


def calculate_rx_sampling(seq_dict: dict | None = None,
                          clock_div: int | None = None) -> dict:
    """Return RX-driven sampling settings for a sequence and divider."""
    source_seq = seq_dict if seq_dict is not None else get_current_sequence(copy_sequence=False)
    div = clock_div if clock_div is not None else get_clock_div()
    return core_api.rx_sampling_summary(source_seq, div, get_nr_samples())


def make_experiment_config(
    *,
    num_averages: int = 1,
    loop_count: int = 1,
    tr_ms: float = 1000.0,
    python_tr_enabled: bool = True,
    phase_cycling_enabled: bool = False,
    phase_cycle_sections: tuple[int, ...] = (),
) -> ExperimentConfig:
    return ExperimentConfig.from_clock_div(
        get_clock_div(),
        num_averages=num_averages,
        loop_count=loop_count,
        tr_ms=tr_ms,
        python_tr_enabled=python_tr_enabled,
        phase_cycling_enabled=phase_cycling_enabled,
        phase_cycle_sections=phase_cycle_sections,
    )


def update_gui_from_scan(result: core_api.ScanResult) -> None:
    state = gui_state_module.state
    state.ch0_raw = result.avg_ch0
    state.ch1_raw = result.avg_ch1
    state.last_ch0_raw = result.ch0
    state.last_ch1_raw = result.ch1
    state.clock_scale = result.context.tracing.clock_div
    state.sample_rate_hz = result.context.tracing.sample_rate_hz
    state.nr_samples = result.context.tracing.nr_samples
    state.nr_rx_pulses = result.context.tracing.nr_rx
    state.rx_total_time_us = result.context.tracing.total_rx_us
    state.rx_total_samples = result.context.tracing.total_rx_samples
    state.dma_samples_per_channel = result.context.tracing.dma_samples_per_channel
    state.num_averages = result.context.config.num_averages
    state.loop_count = result.context.config.loop_count
    state.tr_ms = result.context.config.tr_ms
    state.phase_cycling_enabled = result.context.config.phase_cycling_enabled
    state.phase_cycle_sections = result.context.config.phase_cycle_sections
    _refresh_plots()
    _exp_panel.set_progress(result.context.scan_idx + 1, result.context.total_scans)


def program_api_sequence(seq_dict: dict | None = None):
    """Program a full sequence once and return the reusable sequence object."""
    source_seq = (core_api.copy_sequence(seq_dict) if seq_dict is not None
                  else get_current_sequence(copy_sequence=True))
    hw = require_initialized_overlay()
    if _hw_panel.auto_rx_enabled():
        _sync_rx_sampling_from_sequence(source_seq, force=True)
    sequence_obj = core_api.program_pulse_generator(hw, source_seq, _RUNTIME_TMP_DIR)
    _remember_loaded_sequence(source_seq, sequence_obj)
    return sequence_obj


def write_api_section(seq_dict: dict, section: int | str):
    """Patch one section in pulse-generator RAM from an updated sequence dict."""
    hw = require_initialized_overlay()
    hw.pulse_gen.write(core_api.fpga_mri.C_SEQUENCE_GENERATOR_EN, 0)
    return core_api.write_one_section(
        hw,
        seq_dict,
        section,
        _RUNTIME_TMP_DIR,
    )


def acquire_api_programmed(
    seq_dict: dict,
    sequence_obj,
    *,
    config: ExperimentConfig | None = None,
    scan_idx: int = 0,
    total_scans: int = 1,
    scan_callback: core_api.ScanCallback | None = None,
    fallback_samples: int | None = None,
):
    """Acquire once from an already-programmed pulse-generator sequence."""
    cfg = config or make_experiment_config(num_averages=1, loop_count=1,
                                           tr_ms=0, python_tr_enabled=False)
    if _hw_panel.auto_rx_enabled():
        summary = _sync_rx_sampling_from_sequence(seq_dict, force=True)
        if fallback_samples is None and summary is not None:
            fallback_samples = summary['nr_samples']
    result = core_api.acquire_preprogrammed_scan(
        require_initialized_overlay(),
        sequence_obj,
        seq_dict,
        cfg,
        fallback_samples=fallback_samples or get_nr_samples(),
        scan_idx=scan_idx,
        total_scans=total_scans,
    )
    update_gui_from_scan(result)
    if scan_callback is not None:
        scan_callback(result)
    return result.ch0, result.ch1


def run_api_sequence(
    seq_dict: dict | None = None,
    *,
    config: ExperimentConfig | None = None,
    sequence_transform: core_api.SequenceTransform | None = None,
    scan_callback: core_api.ScanCallback | None = None,
    dynamic_tracing: bool = False,
    stop_flag=None,
    fallback_samples: int | None = None,
):
    """Run a sequence through the v3 API and keep GUI visualization unchanged.

    By default the source sequence is the one loaded in the GUI Sequence tab.
    The runner receives a deep copy, so per-scan transforms reprogram hardware
    without editing the GUI's displayed virgin sequence.
    """
    cfg = config or make_experiment_config()
    source_seq = (core_api.copy_sequence(seq_dict) if seq_dict is not None
                  else get_current_sequence(copy_sequence=True))
    reusable_sequence = None
    if (seq_dict is None and sequence_transform is None
            and not cfg.phase_cycling_enabled and not dynamic_tracing):
        reusable_sequence = _matching_loaded_sequence(source_seq)
    if _hw_panel.auto_rx_enabled():
        summary = _sync_rx_sampling_from_sequence(source_seq, force=True)
        if fallback_samples is None and summary is not None:
            fallback_samples = summary['nr_samples']
    runner = make_runner()

    def _on_scan(result: core_api.ScanResult):
        update_gui_from_scan(result)
        if scan_callback is not None:
            scan_callback(result)

    return runner.run_sequence(
        source_seq,
        cfg,
        fallback_samples=fallback_samples or get_nr_samples(),
        preprogrammed_sequence_obj=reusable_sequence,
        sequence_transform=sequence_transform,
        scan_callback=_on_scan,
        dynamic_tracing=dynamic_tracing,
        stop_flag=stop_flag,
    )

# ─────────────────────────────────────────────────────────────────────────────────
# FPGA initialisation
# ─────────────────────────────────────────────────────────────────────────────────
def _fpga_init():
    hw = mri_overlay.get_overlay()
    hw.init(bitfile=_BITFILE)
    return True


# ─────────────────────────────────────────────────────────────────────────────────
# Sequence helpers
# ─────────────────────────────────────────────────────────────────────────────────
def _build_sequence_from_dict(seq_dict: dict):
    """Write seq_dict to a temp file, parse it, push to the pulse generator."""
    hw = mri_overlay.get_overlay()
    return core_api.program_pulse_generator(hw, seq_dict, _RUNTIME_TMP_DIR)


def _rx_sampling_text(summary: dict | None) -> str:
    if not summary:
        return ''
    return (
        f'RX {summary["total_rx_us"]:g} us, '
        f'{summary["total_rx_samples"]} samples/ch, '
        f'{summary["nr_rx"]} RX window(s), '
        f'{summary["nr_samples"]} samples/RX.'
    )


def _sync_rx_sampling_from_sequence(seq_dict: dict | None = None, *,
                                    force: bool = False) -> dict | None:
    if not force and not _hw_panel.auto_rx_enabled():
        return None
    source_seq = seq_dict if seq_dict is not None else _seq_panel.get_current_sequence()
    if not source_seq:
        return None
    summary = calculate_rx_sampling(source_seq, get_clock_div())
    _hw_panel.set_rx_sampling_summary(summary)
    return summary


def _apply_sequence_to_fpga(seq_dict: dict) -> str:
    sampling_summary = _sync_rx_sampling_from_sequence(seq_dict)
    sampling_msg = _rx_sampling_text(sampling_summary)
    hw = mri_overlay.get_overlay()
    if not hw.initialized:
        _clear_loaded_sequence()
        if sampling_msg:
            return f'FPGA not initialised; GUI updated only. Auto sampling: {sampling_msg}'
        return 'FPGA not initialised; GUI updated only.'
    if _matching_loaded_sequence(seq_dict) is not None:
        msg = 'FPGA pulse generator already programmed; reused existing section RAM.'
        if sampling_msg:
            msg += f' Auto sampling: {sampling_msg}'
        return msg
    _clear_loaded_sequence()
    seq = core_api.program_pulse_generator(hw, core_api.copy_sequence(seq_dict),
                                           _RUNTIME_TMP_DIR)
    _remember_loaded_sequence(seq_dict, seq)
    summary = getattr(seq, 'load_summary', {})
    nr_sections = summary.get('nr_sections')
    mem_depth = summary.get('mem_depth')
    nr_activity = summary.get('nr_activity')
    if mem_depth and nr_activity:
        msg = (f'FPGA pulse generator programmed '
               f'({nr_sections}/{mem_depth} sections, {nr_activity} words/section).')
    else:
        msg = 'FPGA pulse generator programmed.'
    if sampling_msg:
        msg += f' Auto sampling: {sampling_msg}'
    return msg


def _nr_rx_from_dict(seq_dict: dict) -> int:
    return core_api.nr_rx_from_sequence(seq_dict)


def _nr_samples_for_seq(seq_dict: dict, clock_div: int, fallback: int) -> int:
    """Samples per RX pulse, derived from executed RX section duration."""
    return core_api.nr_samples_for_sequence(seq_dict, clock_div, fallback)


def _phase_cycled_sequence_dict(seq_dict: dict, section_ids: tuple[int, ...],
                                scan_idx: int) -> dict:
    """Return a transient sequence copy with selected section phases shifted."""
    return core_api.phase_cycle_sequence(seq_dict, section_ids, scan_idx)


# ─────────────────────────────────────────────────────────────────────────────────
# Core experiment runner (Python-level experiment control + software averaging)
# ─────────────────────────────────────────────────────────────────────────────────
def _run_experiment(config: ExperimentConfig, stop_flag: threading.Event = None):
    state = gui_state_module.state
    hw = mri_overlay.get_overlay()

    if not hw.initialized:
        _exp_panel.status.value = '<span style="color:#f85149">FPGA not initialised.</span>'
        return

    seq_dict = _seq_panel.get_current_sequence()
    if not seq_dict:
        _exp_panel.status.value = '<span style="color:#f85149">No sequence loaded.</span>'
        return

    _hw_panel.set_clock_div(config.clock_div)
    sampling_summary = _sync_rx_sampling_from_sequence(seq_dict)
    source = _seq_panel.get_current_sequence_source()
    exp_cfg = seq_dict.get('ExpConfig', {})
    sampling_suffix = ''
    if sampling_summary:
        sampling_suffix = f' Auto sampling: {_rx_sampling_text(sampling_summary)}'
    _exp_panel.status.value = (
        f'<span style="color:#d29922">Running "{source}" '
        f'({exp_cfg.get("nr_sections", len(seq_dict.get("SectionConfig", {})))} sections, '
        f'{exp_cfg.get("cycle_repetition_number", 1)} HW cycle(s)).'
        f'{sampling_suffix}</span>')
    run_api_sequence(
        config=config,
        stop_flag=stop_flag,
    )


def _run_experiment_avg(config: ExperimentConfig, stop_flag: threading.Event):
    gui_state_module.state.exp_stop = False
    _run_experiment(config, stop_flag)


# ─────────────────────────────────────────────────────────────────────────────────
# FID quick-shot for shim feedback
# ─────────────────────────────────────────────────────────────────────────────────
def _run_fid_for_shim():
    hw = mri_overlay.get_overlay()
    if not hw.initialized:
        raise RuntimeError("FPGA not initialised.")
    if not _seq_panel.get_current_sequence():
        raise RuntimeError("No sequence loaded for shim.")
    cfg = ExperimentConfig.from_clock_div(
        _hw_panel.get_clock_div(),
        num_averages=max(1, _shim_panel.shim_avg.value),
        loop_count=1,
        tr_ms=1000.0,
    )
    _run_experiment(cfg)
    state = gui_state_module.state
    fs_hz = 100e6 / _hw_panel.get_clock_div()
    return state.ch0_raw, state.ch1_raw, fs_hz


# ─────────────────────────────────────────────────────────────────────────────────
# Data save
# ─────────────────────────────────────────────────────────────────────────────────
def _save_data(ch0, ch1, filename, fmt):
    clock_div = gui_state_module.state.clock_scale or 100
    return data_io.save_data(ch0, ch1, filename=filename, fmt=fmt, clock_div=clock_div)


# ─────────────────────────────────────────────────────────────────────────────────
# Plot refresh
# ─────────────────────────────────────────────────────────────────────────────────
def _refresh_plots():
    state = gui_state_module.state
    if state.ch0_raw is None:
        return
    clock_div = state.clock_scale or 100
    fs_hz = 100e6 / clock_div
    dt_us = clock_div / 100.0

    ch0_mv = np.asarray(state.ch0_raw, dtype=float)
    ch1_mv = np.asarray(state.ch1_raw, dtype=float)
    time_us = np.arange(len(ch0_mv)) * dt_us
    _plot_panel.update_time(time_us, ch0_mv, ch1_mv)

    if state.fft_enabled:
        ch = ch1_mv if state.fft_channel == 1 else ch0_mv
        spectrum = np.abs(np.fft.rfft(ch))
        freqs = np.fft.rfftfreq(len(ch), d=1.0 / fs_hz)
        _plot_panel.update_fft(freqs, spectrum)
    else:
        _plot_panel.clear_fft()


# ─────────────────────────────────────────────────────────────────────────────────
# Shim DAC callback
# ─────────────────────────────────────────────────────────────────────────────────
def _shim_dac_set(chn: int, value: int):
    hw = mri_overlay.get_overlay()
    if hw.initialized:
        hw.shim_da4_set(chn, value)


# ─────────────────────────────────────────────────────────────────────────────────
# Build panels
# ─────────────────────────────────────────────────────────────────────────────────
_hw_panel = hw_module.HardwarePanel()
_seq_panel = seq_module.SequencePanel(apply_sequence_callback=_apply_sequence_to_fpga)
_hw_panel.set_rx_sampling_callback(lambda: _sync_rx_sampling_from_sequence())
_plot_panel = plot_module.PlotPanel()
_shim_panel = shim_module.ShimPanel(run_fid_callback=_run_fid_for_shim,
                                    shim_dac_set_fn=_shim_dac_set)
_exp_panel = exp_module.ExperimentPanel(run_experiment_callback=_run_experiment,
                                        avg_experiment_callback=_run_experiment_avg,
                                        clock_div_callback=_hw_panel.get_clock_div)
_ana_panel = ana_module.AnalysisPanel(save_callback=_save_data, refresh_callback=_refresh_plots)


# ── Main tab ──────────────────────────────────────────────────────────────────
_main_tab = widgets.Tab(layout=widgets.Layout(width='100%'))
_main_tab.children = [
    _hw_panel.widget, _seq_panel.widget, _shim_panel.widget, _ana_panel.widget,
]
for i, title in enumerate(['Hardware', 'Sequence', 'Auto-Shim', 'Analysis']):
    _main_tab.set_title(i, title)


# ── FPGA-init accordion ───────────────────────────────────────────────────────
_init_status = widgets.HTML('<span style="color:#d29922">Not initialised.</span>')
_init_btn = widgets.Button(description='Initialise FPGA', button_style='warning',
                           layout=widgets.Layout(width='160px', height='32px'))


def _on_init(_):
    _init_btn.disabled = True
    _init_status.value = '<span style="color:#d29922">Loading overlay…</span>'
    try:
        _fpga_init()
        if _seq_panel.get_current_sequence():
            msg = _apply_sequence_to_fpga(_seq_panel.get_current_sequence())
            _init_status.value = (
                f'<span style="color:#3fb950">FPGA initialised. {msg}</span>')
        else:
            _init_status.value = '<span style="color:#3fb950">FPGA initialised.</span>'
        _init_btn.button_style = 'success'
        _init_btn.description = 'Initialised'
    except Exception as e:
        _init_status.value = f'<span style="color:#f85149">Init error: {e}</span>'
        _init_btn.disabled = False
        raise


_init_btn.on_click(_on_init)

_init_pane = widgets.VBox([
    widgets.HBox([_init_btn, _init_status]),
    widgets.HTML('<span style="color:#8b949e; font-size:12px">'
                 f'Bitstream: {_BITFILE}  ·  '
                 'IPs: pulse_gen, osci, chip_conf, adc0/1, da4, shim_da4, dma</span>'),
], layout=widgets.Layout(padding='8px'))

_accordion = widgets.Accordion(children=[_init_pane])
_accordion.set_title(0, 'FPGA Initialisation')
_accordion.selected_index = 0


# ── Always-visible experiment controls ───────────────────────────────────────
_experiment_block = widgets.VBox([
    _exp_panel.widget,
], layout=widgets.Layout(
    width='100%',
    margin='6px 0 8px 0',
    border='1px solid #30363d',
))


def _make_logo_widget(filename: str) -> widgets.Image | None:
    path = os.path.join(_SRC_V36_DIR, 'icon', filename)
    if not os.path.exists(path):
        return None
    with open(path, 'rb') as f:
        return widgets.Image(
            value=f.read(),
            format=os.path.splitext(filename)[1].lstrip('.'),
            layout=widgets.Layout(height='30px', width='auto', margin='0 8px 0 0'),
        )


def _make_header() -> widgets.HBox:
    logos = [logo for name in _LOGO_FILES if (logo := _make_logo_widget(name))]
    title = widgets.HTML(
        f'<span class="nmr-title">NMR / MRI Control Software  {_SOFTWARE_VERSION}</span>'
        '<span class="nmr-subtitle">'
        'PYNQ ZCU104  |  IIS Stuttgart  |  Unified_NMR_v1_5  |  RX-sized JSON stack'
        '</span>',
        layout=widgets.Layout(flex='1 1 auto'),
    )
    return widgets.HBox(
        [*logos, title],
        layout=widgets.Layout(
            width='100%',
            align_items='center',
            padding='8px 16px',
        ),
    )


def _make_author_credit() -> widgets.HTML:
    return widgets.HTML(
        f'<div class="nmr-authors">Authors: {_AUTHOR_NAMES}</div>',
        layout=widgets.Layout(width='100%'),
    )


# ── Header / credits ──────────────────────────────────────────────────────────
_header = widgets.Box([_make_header()], layout=widgets.Layout(width='100%'))
_header.add_class('nmr-header')
_authors = _make_author_credit()


# ── Root widget (exported) ────────────────────────────────────────────────────
GUI_total = widgets.VBox([
    gs.inject_css_widget(),
    _header,
    _accordion,
    _experiment_block,
    _main_tab,
    _plot_panel.widget,
    _authors,
], layout=widgets.Layout(width='100%'))


def build_gui():
    """Return the root GUI widget (alias for the module-level GUI_total)."""
    return GUI_total
