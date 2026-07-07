# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.experiment_control
# --   Python-level experiment protocol configuration.
# --
# --   This layer owns user-facing experiment parameters that are broader than a
# --   single hardware register: software averages, loop count and repetition
# --   time (TR).  Sampling is controlled by the tracing clock divider.
# ----------------------------------------------------------------------------------

from __future__ import annotations

from dataclasses import dataclass
import time


BASE_CLOCK_HZ = 100_000_000.0


@dataclass(frozen=True)
class ExperimentConfig:
    """Validated experiment protocol values used by the acquisition runner."""

    clock_div: int = 100
    num_averages: int = 1
    loop_count: int = 1
    tr_ms: float = 1000.0
    python_tr_enabled: bool = True
    phase_cycling_enabled: bool = False
    phase_cycle_sections: tuple[int, ...] = ()

    def __post_init__(self):
        if self.clock_div < 1:
            raise ValueError("clock_div must be at least 1.")
        if self.num_averages < 1:
            raise ValueError("num_averages must be at least 1.")
        if self.loop_count < 1:
            raise ValueError("loop_count must be at least 1.")
        if self.tr_ms < 0:
            raise ValueError("TR must be non-negative.")
        if any(section_id < 0 for section_id in self.phase_cycle_sections):
            raise ValueError("Phase-cycle section IDs must be non-negative.")

    @classmethod
    def from_clock_div(
        cls,
        clock_div: int,
        *,
        num_averages: int = 1,
        loop_count: int = 1,
        tr_ms: float = 1000.0,
        python_tr_enabled: bool = True,
        phase_cycling_enabled: bool = False,
        phase_cycle_sections: tuple[int, ...] = (),
    ) -> "ExperimentConfig":
        return cls(
            clock_div=max(1, int(clock_div)),
            num_averages=max(1, int(num_averages)),
            loop_count=max(1, int(loop_count)),
            tr_ms=max(0.0, float(tr_ms)),
            python_tr_enabled=bool(python_tr_enabled),
            phase_cycling_enabled=bool(phase_cycling_enabled),
            phase_cycle_sections=tuple(int(s) for s in phase_cycle_sections),
        )

    @property
    def actual_sample_rate_hz(self) -> float:
        """Sampling rate implied by the integer FPGA divider."""
        return BASE_CLOCK_HZ / max(1, int(self.clock_div))

    @property
    def total_scans(self) -> int:
        return max(1, int(self.num_averages) * int(self.loop_count))

    @property
    def tr_seconds(self) -> float:
        if not self.python_tr_enabled:
            return 0.0
        return max(0.0, float(self.tr_ms) / 1000.0)


def sleep_for_tr(config: ExperimentConfig, stop_flag=None) -> None:
    """Sleep for TR while remaining responsive to a stop request."""
    delay_s = config.tr_seconds
    if delay_s <= 0:
        return
    if stop_flag is not None and hasattr(stop_flag, "wait"):
        stop_flag.wait(delay_s)
    else:
        time.sleep(delay_s)


def parse_section_id_list(text: str) -> tuple[int, ...]:
    """Parse user text like '5, 10' into unique section IDs."""
    if not text or not text.strip():
        return ()
    ids: list[int] = []
    for raw in text.replace(";", ",").split(","):
        item = raw.strip()
        if not item:
            continue
        section_id = int(item)
        if section_id < 0:
            raise ValueError("Section IDs must be non-negative.")
        if section_id not in ids:
            ids.append(section_id)
    return tuple(ids)
