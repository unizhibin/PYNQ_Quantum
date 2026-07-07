# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- Company: University of Stuttgart (IIS)
# -- Engineer: Yichao Peng
# -- Description:
# --   Lazy-loading hardware singleton for the self-contained src_v3_6 overlay.
# --   All PYNQ imports happen INSIDE init() so that importing this module
# --   at notebook cell run time does NOT load any bitstream and does NOT
# --   crash the PYNQ kernel.
# --
# --   Usage:
# --       import src.mri_overlay as mri_overlay
# --       hw = mri_overlay.get_overlay()
# --       hw.init()   # called once from the "Initialise FPGA" button
# --
# --   Public API after init():
# --       hw.pulse_gen, hw.osci, hw.chip_conf, hw.adc0, hw.adc1
# --       hw.da4 (gradient DAC IP handle)
# --       hw.shim_ip (shim DAC IP handle)
# --       hw.dma, hw.dma_send, hw.dma_recv
# --       hw.spi  (MRI_spi instance)
# --       hw.output_buffer_0, hw.output_buffer_1
# --
# --       hw.da4_set(chn, value)
# --       hw.da4_setall(value)
# --       hw.shim_da4_set(chn, value)
# --       hw.shim_da4_setall(value)
# --       hw.osci_*() helpers (enable/disable, clock_step_size, …)
# --       hw.acquire(nr_rx, nr_samples, clock_div) → (ch0, ch1)
# ----------------------------------------------------------------------------------

from __future__ import annotations

import os
import time

# ── Bitstream resolution ─────────────────────────────────────────────────────────
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))


def _resolve_bitfile(bitfile: str) -> str:
    """Locate the .bit file by trying several candidate locations.

    The companion .hwh must sit next to the .bit; PYNQ finds it automatically.
    Search order:
        1. The path as given (absolute or relative to cwd).
        2. Next to this module (src_v3_6/).
    """
    if os.path.isabs(bitfile) and os.path.exists(bitfile):
        return bitfile
    name = os.path.basename(bitfile)
    candidates = [
        bitfile,
        os.path.join(_THIS_DIR, name),
    ]
    for cand in candidates:
        if os.path.exists(cand):
            return cand
    # Fall back to the original string; PYNQ will raise a clear error if missing.
    return bitfile


# ── Module-level singleton ───────────────────────────────────────────────────────
_overlay_instance: "MRIOverlay | None" = None


def get_overlay() -> "MRIOverlay":
    """Return the module-level singleton, creating (but NOT initialising) it if needed."""
    global _overlay_instance
    if _overlay_instance is None:
        _overlay_instance = MRIOverlay()
    return _overlay_instance


# ────────────────────────────────────────────────────────────────────────────────
# MRI_spi — HV NMR chip SPI controller
# Faithful replication of the MRI_spi class defined in MRI_V5_TypeTSE_3_0.ipynb
# ────────────────────────────────────────────────────────────────────────────────
class MRI_spi:
    """SPI configuration controller for Heiko's HV NMR chip."""

    def __init__(self, ip):
        self.ip = ip
        self.Address_register_SPI_data = tuple(x * 4 for x in (0, 2))  # (0, 8)
        self.Address_register_start    = 1 * 4   # 4
        self.Address_register_done     = 3 * 4   # 12
        self.register_width = 32

        # Bit positions of each SPI sub-field within the 54-bit SPI word
        self.sub_addr_array = [
            0,   # Sub_Address_SPI_pll_en
            1,   # Sub_Address_SPI_gain
            2,   # Sub_Address_SPI_skip_mixer
            3,   # Sub_Address_SPI_prescaler_pll (2 bits)
            5,   # Sub_Address_SPI_N_divider_pll (5 bits)
            10,  # Sub_Address_SPI_prescaler_tx_logic (2 bits)
            12,  # Sub_Address_SPI_tx_shortening_counter (8 bits)
            20,  # Sub_Address_SPI_deadtime_hs_p (4 bits, spans reg boundary)
            24,  # Sub_Address_SPI_deadtime_ls_p
            28,  # Sub_Address_SPI_deadtime_hs_n
            32,  # Sub_Address_SPI_deadtime_ls_n
            36,  # Sub_Address_SPI_deadtime_comp_p
            40,  # Sub_Address_SPI_deadtime_comp_n
            44,  # Sub_Address_SPI_delay_p
            48,  # Sub_Address_SPI_delay_n
            52,  # Sub_Address_SPI_amplifier_reset
            53,  # Sub_Address_SPI_pll_or_spi_output
            54,  # Sub_Address_SPI_ls
        ]

        # Named sub-address indices
        self.Sub_Address_SPI_pll_en                = 0
        self.Sub_Address_SPI_gain                  = 1
        self.Sub_Address_SPI_skip_mixer            = 2
        self.Sub_Address_SPI_prescaler_pll         = 3
        self.Sub_Address_SPI_N_divider_pll         = 4
        self.Sub_Address_SPI_prescaler_tx_logic    = 5
        self.Sub_Address_SPI_tx_shortening_counter = 6
        self.Sub_Address_SPI_deadtime_hs_p         = 7
        self.Sub_Address_SPI_deadtime_ls_p         = 8
        self.Sub_Address_SPI_deadtime_hs_n         = 9
        self.Sub_Address_SPI_deadtime_ls_n         = 10
        self.Sub_Address_SPI_deadtime_comp_p       = 11
        self.Sub_Address_SPI_deadtime_comp_n       = 12
        self.Sub_Address_SPI_delay_p               = 13
        self.Sub_Address_SPI_delay_n               = 14
        self.Sub_Address_SPI_amplifier_reset       = 15
        self.Sub_Address_SPI_pll_or_spi_output     = 16
        self.Sub_Address_SPI_ls                    = 17

        # Default SPI parameters (spi_init_cmd defaults)
        self.pll_flag              = 1
        self.gain_flag             = 0    # 0 = gain on
        self.mixer_flag            = 0    # 0 = mixer on
        self.pll_prescaler         = 2
        self.N_divider             = 0
        self.prescaler_tx_logic    = 3
        self.tx_shortening_counter = 250
        self.deadtime_hs_p         = 12
        self.deadtime_ls_p         = 12
        self.deadtime_hs_n         = 12
        self.deadtime_ls_n         = 12
        self.deadtime_comp_p       = 12
        self.deadtime_comp_n       = 12
        self.delay_p               = 1
        self.delay_n               = 1

    # ── Register helpers ──────────────────────────────────────────────────────
    def read_register(self, address):
        return self.ip.read(address)

    def write_register(self, address, val):
        return self.ip.write(address, val)

    def clear_register(self):
        self.ip.write(self.Address_register_SPI_data[0], 0)
        self.ip.write(self.Address_register_SPI_data[1], 0)
        self.ip.write(self.Address_register_start, 0)
        self.ip.write(self.Address_register_done, 0)

    # ── Sub-address read/write ─────────────────────────────────────────────────
    def read_spi_sub_address(self, sub_address):
        cur = (self.ip.read(self.Address_register_SPI_data[1])
               + 2 ** 32 * self.ip.read(self.Address_register_SPI_data[0]))
        length = 1 if sub_address == 17 else (
            self.sub_addr_array[sub_address + 1] - self.sub_addr_array[sub_address])
        return (cur >> (9 + self.sub_addr_array[sub_address])) % (2 ** length)

    def write_spi_sub_address(self, sub_address, set_val):
        address = (self.Address_register_SPI_data[0]
                   if self.sub_addr_array[sub_address] > 22
                   else self.Address_register_SPI_data[1])
        cur_0 = self.read_register(self.Address_register_SPI_data[0])
        cur_2 = self.read_register(self.Address_register_SPI_data[1])

        if sub_address == self.Sub_Address_SPI_deadtime_hs_p:
            # Special: spans register 0 and register 2
            if set_val >= 8:
                masked    = cur_0 & (2 ** self.register_width - 2)
                result_0  = masked | 1
                set_val  -= 8
            else:
                result_0  = cur_0 & (2 ** self.register_width - 2)
            self.ip.write(self.Address_register_SPI_data[0], result_0)
            max_val  = 7
            set_val  = min(set_val, max_val)
            masked   = cur_2 & (2 ** self.register_width - 1 - (max_val << 29))
            self.ip.write(self.Address_register_SPI_data[1], masked | (set_val << 29))
        else:
            length  = 1 if sub_address == 17 else (
                self.sub_addr_array[sub_address + 1] - self.sub_addr_array[sub_address])
            max_val = 2 ** length - 1
            set_val = min(set_val, max_val)
            if address == self.Address_register_SPI_data[1]:
                masked   = cur_2 & (2 ** self.register_width - 1
                                    - (max_val << (self.sub_addr_array[sub_address] + 9)))
                self.ip.write(address, masked | (set_val << (self.sub_addr_array[sub_address] + 9)))
            else:
                masked   = cur_0 & (2 ** self.register_width - 1
                                    - (max_val << (self.sub_addr_array[sub_address] - 23)))
                self.ip.write(address, masked | (set_val << (self.sub_addr_array[sub_address] - 23)))

    # ── Register 1: start trigger ─────────────────────────────────────────────
    def spi_write_start(self, val):
        self.ip.write(self.Address_register_start, val)

    # ── Per-field write helpers ───────────────────────────────────────────────
    def spi_write_pll_en(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_pll_en, val)

    def spi_write_gain(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_gain, val)

    def spi_write_skip_mixer(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_skip_mixer, val)

    def spi_write_prescaler_pll(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_prescaler_pll, val)

    def spi_write_N_divider_pll(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_N_divider_pll, val)

    def spi_write_prescaler_tx_logic(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_prescaler_tx_logic, val)

    def spi_write_tx_shortening_counter(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_tx_shortening_counter, val)

    def spi_write_deadtime_hs_p(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_hs_p, val)

    def spi_write_deadtime_ls_p(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_ls_p, val)

    def spi_write_deadtime_hs_n(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_hs_n, val)

    def spi_write_deadtime_ls_n(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_ls_n, val)

    def spi_write_deadtime_comp_p(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_comp_p, val)

    def spi_write_deadtime_comp_n(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_deadtime_comp_n, val)

    def spi_write_delay_p(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_delay_p, val)

    def spi_write_delay_n(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_delay_n, val)

    def spi_write_amplifier_reset(self, val):
        self.write_spi_sub_address(self.Sub_Address_SPI_amplifier_reset, val)

    # ── Per-field read helpers ────────────────────────────────────────────────
    def spi_read_pll_en(self):        return self.read_spi_sub_address(self.Sub_Address_SPI_pll_en)
    def spi_read_gain(self):          return self.read_spi_sub_address(self.Sub_Address_SPI_gain)
    def spi_read_skip_mixer(self):    return self.read_spi_sub_address(self.Sub_Address_SPI_skip_mixer)
    def spi_read_prescaler_pll(self): return self.read_spi_sub_address(self.Sub_Address_SPI_prescaler_pll)
    def spi_read_N_divider_pll(self): return self.read_spi_sub_address(self.Sub_Address_SPI_N_divider_pll)
    def spi_read_prescaler_tx_logic(self):     return self.read_spi_sub_address(self.Sub_Address_SPI_prescaler_tx_logic)
    def spi_read_tx_shortening_counter(self):  return self.read_spi_sub_address(self.Sub_Address_SPI_tx_shortening_counter)
    def spi_read_deadtime_hs_p(self):  return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_hs_p)
    def spi_read_deadtime_ls_p(self):  return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_ls_p)
    def spi_read_deadtime_hs_n(self):  return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_hs_n)
    def spi_read_deadtime_ls_n(self):  return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_ls_n)
    def spi_read_deadtime_comp_p(self): return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_comp_p)
    def spi_read_deadtime_comp_n(self): return self.read_spi_sub_address(self.Sub_Address_SPI_deadtime_comp_n)
    def spi_read_delay_p(self):   return self.read_spi_sub_address(self.Sub_Address_SPI_delay_p)
    def spi_read_delay_n(self):   return self.read_spi_sub_address(self.Sub_Address_SPI_delay_n)
    def spi_read_amplifier_reset(self): return self.read_spi_sub_address(self.Sub_Address_SPI_amplifier_reset)

    # ── Three-phase SPI initialisation ────────────────────────────────────────
    def spi_init_cmd(self):
        """Send three-phase SPI init sequence to Heiko's HV chip."""
        import time

        def _send(reset_val):
            self.clear_register()
            self.spi_write_pll_en(self.pll_flag)
            self.spi_write_gain(self.gain_flag)
            self.spi_write_skip_mixer(self.mixer_flag)
            self.spi_write_prescaler_pll(self.pll_prescaler)
            self.spi_write_N_divider_pll(self.N_divider)
            self.spi_write_prescaler_tx_logic(self.prescaler_tx_logic)
            self.spi_write_tx_shortening_counter(self.tx_shortening_counter)
            self.spi_write_deadtime_hs_p(self.deadtime_hs_p)
            self.spi_write_deadtime_ls_p(self.deadtime_ls_p)
            self.spi_write_deadtime_hs_n(self.deadtime_hs_n)
            self.spi_write_deadtime_ls_n(self.deadtime_ls_n)
            self.spi_write_deadtime_comp_p(self.deadtime_comp_p)
            self.spi_write_deadtime_comp_n(self.deadtime_comp_n)
            self.spi_write_delay_p(self.delay_p)
            self.spi_write_delay_n(self.delay_n)
            self.spi_write_amplifier_reset(reset_val)
            self.spi_write_start(1)
            time.sleep(1)

        _send(1)   # First: amplifier_reset = 1
        _send(0)   # Second: amplifier_reset = 0
        _send(0)   # Third: amplifier_reset = 0


# ────────────────────────────────────────────────────────────────────────────────
# MRIOverlay — lazy-loading overlay singleton
# ────────────────────────────────────────────────────────────────────────────────
class MRIOverlay:
    """
    Lazy-loading wrapper around pynq.Overlay for the local MRI bitstream.

    Call init() once (from the notebook or the GUI 'Initialise FPGA' button).
    After that, all attributes are safe to use.
    """

    DEFAULT_BITFILE = 'Unified_NMR_v1_4.bit'
    ADC_MODE        = 9
    DEFAULT_CLOCK_DIV = 100   # 100 MHz / 100 = 1 MHz sampling

    # ── Tracing (osci) register offsets ──────────────────────────────────────
    C_ENABLE_CMD                        = 0  * 4
    C_SINGLE_SHOT_CMD                   = 1  * 4
    C_SELECT_ANALOG_TRIGGER_CHANNEL_CMD = 2  * 4
    C_SET_ANALOG_TRIGGER_RISING_EDGE    = 3  * 4
    C_SET_ANALOG_TRIGGER_FALLING_EDGE   = 4  * 4
    C_BIN_CH_RE_TRIG_EN_CMD             = 5  * 4
    C_BIN_CH_FE_TRIG_EN_CMD             = 6  * 4
    C_ARM_CMD                           = 7  * 4
    C_SET_NR_SAMPLES_CMD                = 8  * 4
    C_CLOCK_STEP_SIZE_CMD               = 9  * 4
    C_SET_TRIGGER_DELAY_CMD             = 10 * 4
    C_SELECT_READ_MEMORY_CMD            = 11 * 4
    C_SET_CURRENT_READ_ADDRESS_CMD      = 12 * 4
    C_READ_DATA                         = 13 * 4
    C_READ_BUSY_SIGNAL_CMD              = 19 * 4
    C_READ_READY_SIGNAL_CMD             = 20 * 4
    C_SET_STREAM_NR_RX_PULSE            = 25 * 4
    C_START_STREAM                      = 26 * 4
    C_TYPE_STREAM                       = 27 * 4
    C_REST_SAMPLES                      = 28 * 4
    C_READ_STREAM_BUSY                  = 29 * 4

    def __init__(self):
        self._initialized = False
        # IP handles — set by init()
        self.ol        = None
        self.pulse_gen = None   # fpga_pulse_generator_0
        self.osci      = None   # fpga_tracing_0
        self.chip_conf = None   # fpga_nmr_chip_config_0
        self.adc0      = None   # fpga_ADC_AD7960_0
        self.adc1      = None   # fpga_ADC_AD7960_1
        self.da4       = None   # fpga_mri_gradient_co_0
        self.shim_ip   = None   # fpga_pmod_da4_a1_0
        self.dma       = None   # axi_dma_0
        self.dma_send  = None
        self.dma_recv  = None
        self.spi       = None   # MRI_spi instance
        self.output_buffer_0 = None
        self.output_buffer_1 = None
        self._alloc_size: int = 0
        # Tracing config (updated by GUI)
        self.clock_div  = self.DEFAULT_CLOCK_DIV
        self.nr_samples = 200000

    @property
    def initialized(self) -> bool:
        return self._initialized

    # ── Main init ─────────────────────────────────────────────────────────────
    def init(self, bitfile: str = None) -> None:
        """
        Load overlay and initialise all IPs.
        Must be called once before any experiment.
        All pynq imports happen here so the module is safe to import on non-PYNQ hosts.
        """
        import time
        from pynq import Overlay, allocate, MMIO

        bf = bitfile or self.DEFAULT_BITFILE
        bf = _resolve_bitfile(bf)
        print(f"[mri_overlay] Loading overlay: {bf}")
        self.ol = Overlay(bf)
        print("[mri_overlay] Overlay loaded.")

        # ── IP handles ──────────────────────────────────────────────────────
        self.pulse_gen = self.ol.fpga_pulse_generator_0
        self.osci      = self.ol.fpga_tracing_0
        self.chip_conf = self.ol.fpga_nmr_chip_config_0
        self.adc0      = self.ol.fpga_ADC_AD7960_0
        self.adc1      = self.ol.fpga_ADC_AD7960_1
        self.da4       = self.ol.fpga_mri_gradient_co_0
        self.shim_ip   = self.ol.fpga_pmod_da4_a1_0
        # NOTE: the AXI DMA (axi_dma_0) is intentionally NOT touched here.
        # Accessing .sendchannel/.recvchannel makes PYNQ instantiate the DMA
        # driver and perform a soft channel reset that polls DMACR.Reset until
        # it self-clears.  That reset only completes when the DMA's AXI4-Stream
        # clock domain is running — which in this design is brought up by the
        # ADC mode write + the analog-chip PLL (spi_init_cmd()).  Touching the
        # DMA before those clocks exist hangs the reset and stalls/crashes the
        # Zynq PS.  The DMA is therefore brought up last, via _ensure_dma(),
        # after ADC/DAC/SPI/tracing are configured — exactly like the proven
        # MRI_V5_TypeTSE notebook, which only touches the DMA in its
        # acquisition cell.
        
        
        # ── ADC configuration ────────────────────────────────────────────────
        self.adc0.write(0x0, self.ADC_MODE)
        self.adc1.write(0x0, self.ADC_MODE)
        print("[mri_overlay] ADCs configured (mode 9).")
        
        
        # ── Gradient DAC ─────────────────────────────────────────────────────
        self.da4.write(16,0)
        self._da4_reset()
        self._da4_init_internal_ref()
        self.da4_setall(0)
        
        self.da4.write(16,1)
        print("[mri_overlay] Gradient DAC initialised.")

        # ── Shim DAC ─────────────────────────────────────────────────────────
        self._shim_da4_reset()
        self._shim_da4_init_internal_ref()
        self.shim_da4_setall(0)
        print("[mri_overlay] Shim DAC initialised.")
        # raise ValueError("DEBUG HALT")

        # ── Tracing (osci) default config ────────────────────────────────────
        # self.osci_trigger_delay(4292870144)
        self.osci_trigger_delay( 2**(26-1)+ 1 )
        self.osci.write(self.C_BIN_CH_RE_TRIG_EN_CMD, 1)
        self.osci_clock_step_size(self.clock_div)
        self.osci_set_nr_samples(self.nr_samples)
        self.osci_set_stream_nr_rx_pulse(1)
        self.osci_type_stream(1)       # single-shot mode
        self.osci_enable()
        print("[mri_overlay] Tracing (osci) configured.")

        # ── SPI / HV chip init ───────────────────────────────────────────────
        # Done BEFORE the DMA is brought up: spi_init_cmd() configures the
        # analog chip / PLL that generates the ADC sampling (AXI4-Stream) clock.
        # The DMA reset can only complete once this clock is running.
        self.spi = MRI_spi(self.chip_conf)
        # self.spi.spi_init_cmd()
        # time.sleep(1)
        print("[mri_overlay] SPI (HV chip) init done.")
        
        # raise ValueError("DEBUG HALT")
        # ── DMA bring-up (LAST — stream clock must be alive) ──────────────────
        self._ensure_dma()

        # ── Allocate default buffers ──────────────────────────────────────────
        default_alloc = self.nr_samples * 2   # 2 channels interleaved
        self._alloc_buffers(default_alloc)
        print(f"[mri_overlay] Buffers allocated: {default_alloc} × int32.")

        self._initialized = True
        print("[mri_overlay] ✔ Hardware fully initialised.")

    # ── DMA management ────────────────────────────────────────────────────────
    def _ensure_dma(self) -> None:
        """
        Lazily obtain the AXI DMA handles and perform the MMIO soft reset.

        Must only be called AFTER the ADC mode write and SPI/PLL init have
        brought up the AXI4-Stream sampling clock — otherwise the DMA reset
        hangs and crashes the Zynq PS.  Safe to call repeatedly (no-op once
        the handles exist).
        """
        if self.dma is not None:
            return
        from pynq import MMIO
        self.dma      = self.ol.axi_dma_0
        # Data path is FPGA → PS only; recvchannel is what we use.  sendchannel
        # is acquired for parity with the reference notebook but never used.
        self.dma_recv = self.dma.recvchannel
        self.dma_send = self.dma.sendchannel
        dma_reset = MMIO(self.dma.mmio.base_addr + 0x4, 4)
        dma_reset.write_mm(0, 1)
        print("[mri_overlay] DMA brought up and reset.")

    # ── Buffer management ─────────────────────────────────────────────────────
    def _alloc_buffers(self, alloc_size: int) -> None:
        """Allocate (or reallocate) DMA receive buffers."""
        import numpy as np
        from pynq import allocate
        if self.output_buffer_0 is not None:
            del self.output_buffer_0
        if self.output_buffer_1 is not None:
            del self.output_buffer_1
        self.output_buffer_0 = allocate(shape=(alloc_size,), dtype=np.int32)
        self.output_buffer_1 = allocate(shape=(alloc_size,), dtype=np.int32)
        self._alloc_size = alloc_size

    def ensure_buffers(self, alloc_size: int) -> None:
        """Resize buffers only if the required size changed."""
        if alloc_size != self._alloc_size:
            self._alloc_buffers(alloc_size)

    # ── Tracing (osci) helpers ────────────────────────────────────────────────
    def osci_enable(self):
        self.osci.write(self.C_ENABLE_CMD, 1)

    def osci_disable(self):
        self.osci.write(self.C_ENABLE_CMD, 0)

    def osci_trigger_delay(self, val: int):
        self.osci.write(self.C_SET_TRIGGER_DELAY_CMD, val)

    def osci_clock_step_size(self, val: int):
        """Set clock divider (100 MHz / val = sampling rate)."""
        self.clock_div = val
        self.osci.write(self.C_CLOCK_STEP_SIZE_CMD, val)

    def osci_set_nr_samples(self, val: int):
        self.nr_samples = val
        self.osci.write(self.C_SET_NR_SAMPLES_CMD, val)

    def osci_set_stream_nr_rx_pulse(self, val: int):
        self.osci.write(self.C_SET_STREAM_NR_RX_PULSE, val)

    def osci_start_stream(self):
        self.osci.write(self.C_START_STREAM, 1)

    def osci_terminate_stream(self):
        self.osci.write(self.C_START_STREAM, 0)

    def osci_type_stream(self, val: int):
        """Set stream trigger mode. v3.6 uses single-shot (1)."""
        self.osci.write(self.C_TYPE_STREAM, val)

    def osci_dig_trigger_ris(self, val: int):
        self.osci.write(self.C_BIN_CH_RE_TRIG_EN_CMD, val)

    def osci_dig_trigger_fal(self, val: int):
        self.osci.write(self.C_BIN_CH_FE_TRIG_EN_CMD, val)
        


    # ── Gradient DAC (da4 = fpga_mri_gradient_co_0) ───────────────────────────
    def _da4_reset(self):
        da4 = self.da4
        da4.write(16, 0b0000)
        da4.write(4,  0b0111)   # reset command
        da4.write(8,  0b0000)
        da4.write(12, 0b0000)
        da4.write(20, 0b0000)
        da4.write(0,  0b0001)

    def _da4_init_internal_ref(self):
        da4 = self.da4
        da4.write(4,  0b1000)   # internal reference command
        da4.write(8,  0b0000)
        da4.write(12, 0b0000)
        da4.write(20, 0b0001)
        da4.write(0,  0b0001)

    def da4_set(self, chn: int, value: int):
        """Write a 12-bit value to one gradient DAC channel."""
        da4 = self.da4
        da4.write(4,  0b0011)
        da4.write(8,  chn)
        da4.write(12, value)
        da4.write(20, 0)
        da4.write(0,  1)

    def da4_setall(self, value: int):
        """Write the same 12-bit value to all gradient DAC channels."""
        da4 = self.da4
        da4.write(4,  0b0011)
        da4.write(8,  0b1111)
        da4.write(12, value)
        da4.write(20, 0)
        da4.write(0,  1)

    # ── Shim DAC (shim_ip = fpga_pmod_da4_a1_0) ──────────────────────────────
    def _shim_da4_reset(self):
        shim = self.shim_ip
        shim.write(4,  0b0111)   # reset command
        shim.write(16, 0b0001)
        shim.write(0,  0b0001)

    def _shim_da4_init_internal_ref(self):
        shim = self.shim_ip
        shim.write(4,  0b1000)   # internal reference command
        shim.write(16, 0b0001)
        shim.write(0,  0b0001)

    def shim_da4_set(self, chn: int, value: int):
        """Write a 12-bit value to one shim DAC channel."""
        shim = self.shim_ip
        shim.write(4,  0b0011)
        shim.write(8,  chn)
        shim.write(12, value)
        shim.write(16, 0)
        shim.write(0,  1)

    def shim_da4_setall(self, value: int):
        """Write the same 12-bit value to all shim DAC channels."""
        shim = self.shim_ip
        shim.write(4,  0b0011)
        shim.write(8,  0b1111)
        shim.write(12, value)
        shim.write(16, 0)
        shim.write(0,  1)

    # ── Experiment acquire ────────────────────────────────────────────────────
    def acquire(self, sequence_obj, nr_rx: int, nr_samples: int,
                clock_div: int = None) -> tuple:
        """
        Run one DMA transfer + sequence start and return deinterleaved channels.

        Parameters
        ----------
        sequence_obj : fpga_mri.MRI_Sequence  (already written to pulse_gen)
        nr_rx        : int  — number of RX pulses (packages)
        nr_samples   : int  — samples per RX pulse
        clock_div    : int  — optional clock divider override

        Returns
        -------
        (ch0, ch1) : tuple of float64 numpy arrays in mV
        """
        import numpy as np

        self._ensure_dma()

        if clock_div is not None and clock_div != self.clock_div:
            self.osci_clock_step_size(clock_div)

        alloc_size = nr_rx * nr_samples * 2   # 2 channels interleaved
        self.ensure_buffers(alloc_size)

        self.osci_set_nr_samples(nr_samples)
        self.osci_set_stream_nr_rx_pulse(nr_rx)
        self.osci_type_stream(1)    # 0--arm, 1--single shot 
        # DMA transfer
        self.output_buffer_0.fill(0)
        self.dma_recv.start()
        self.dma_recv.transfer(self.output_buffer_0)
        self.osci_terminate_stream()
        self.osci_start_stream()

        try:
            sequence_obj.start_sequence()            
            self.dma_recv.wait()
        finally:
            # sequence_obj.stop_sequence()
            self.osci_terminate_stream()

        # sequence_obj.start_sequence()            
        # time.sleep(5)
        # self.dma_recv.wait()
        # sequence_obj.stop_sequence()
        # self.osci_terminate_stream()

        # Deinterleave (even = ch0, odd = ch1)
        n = nr_rx * nr_samples
        raw_ch0 = np.array(self.output_buffer_0[0:n * 2:2], dtype=np.float64)
        raw_ch1 = np.array(self.output_buffer_0[1:n * 2:2], dtype=np.float64)

        # ADC → mV conversion (18-bit ADC, ±2.5 V range, gain correction)
        adc_scale_0 = 5.11 / (2 ** 18) * 1000 / 1.263
        adc_scale_1 = 5.11 / (2 ** 18) * 1000 / 1.218
        ch0_mv = raw_ch0 * adc_scale_0
        ch1_mv = raw_ch1 * adc_scale_1

        return ch0_mv, ch1_mv
