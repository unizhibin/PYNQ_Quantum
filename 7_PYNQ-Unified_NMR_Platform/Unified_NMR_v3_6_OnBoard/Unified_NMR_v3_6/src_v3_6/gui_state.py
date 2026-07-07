# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_state
# --   Shared mutable runtime state used across all GUI panels.
# --   A single module-level instance (`state`) avoids circular imports between
# --   the orchestrator, panels and data processing helpers.
# ----------------------------------------------------------------------------------


class GUIState:
    """Centralised runtime state shared across all GUI panels."""

    def __init__(self):
        # ── ADC / sampling ──────────────────────────────────────────────────
        self.clock_div: int = 100           # 100 MHz / clock_div = sampling rate
        self.sample_rate_hz: float = 1e6    # actual rate used for last acquisition
        self.nr_samples: int = 2000         # samples per RX pulse (per echo window)
        self.nr_rx_pulses: int = 1          # number of RX packages per experiment
        self.auto_rx_samples: bool = True   # update sampling from loaded sequence
        self.rx_total_time_us: float = 0.0
        self.rx_total_samples: int = 0
        self.dma_samples_per_channel: int = 0
        self.num_averages: int = 1          # software averages per loop
        self.loop_count: int = 1            # repeated average blocks
        self.tr_ms: float = 1000.0          # Python-level delay between scans
        self.phase_cycling_enabled: bool = False
        self.phase_cycle_sections: tuple[int, ...] = ()

        # ── Data saving ─────────────────────────────────────────────────────
        self.save_name: str = "Untitled"
        self.save_format: int = 0           # 0 = .csv, 1 = .txt

        # ── Analysis toggles ────────────────────────────────────────────────
        self.fft_enabled: bool = False
        self.fft_channel: int = 0

        # ── Experiment control ──────────────────────────────────────────────
        self.exp_stop: bool = False

        # ── Last acquired data (mV, set after each acquisition) ─────────────
        self.ch0_raw = None
        self.ch1_raw = None
        self.last_ch0_raw = None
        self.last_ch1_raw = None
        self.clock_scale: int = 100         # clock divider used for last acquisition

        # ── Currently loaded sequence dict (real fpga_mri schema) ───────────
        self.sequence: dict = {}


# Module-level singleton — import and use `state` everywhere.
state = GUIState()
