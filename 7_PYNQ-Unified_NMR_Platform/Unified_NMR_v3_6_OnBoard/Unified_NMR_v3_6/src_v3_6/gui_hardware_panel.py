# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_hardware_panel
# --   Hardware configuration — Chip Config (HV SPI), Sampling, Bandpass.
# --   All hardware access is lazy via mri_overlay.get_overlay(); the panel can
# --   be instantiated before the overlay is initialised.
# ----------------------------------------------------------------------------------

import ipywidgets as widgets

from . import gui_state as gui_state_module

# SPI parameter widgets for the HV chip (created once at module level).
_spi = [
    widgets.IntText(value=2,   description='pre_pll:',  layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=0,   description='pll_div:',  layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=3,   description='pre_tx:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=250, description='tx_cnt:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=12,  description='dt_hsp:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=12,  description='dt_lsp:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=12,  description='dt_hsn:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=12,  description='dt_lsn:',   layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=12,  description='dt_com_p:', layout=widgets.Layout(width='130px', height='28px'), style={'description_width': '70px'}),
    widgets.IntText(value=12,  description='dt_com_n:', layout=widgets.Layout(width='130px', height='28px'), style={'description_width': '70px'}),
    widgets.IntText(value=1,   description='delay_p:',  layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
    widgets.IntText(value=1,   description='delay_n:',  layout=widgets.Layout(width='120px', height='28px'), style={'description_width': '60px'}),
]


class HardwarePanel:
    """Owns all hardware-configuration widgets (Chip / ADC&Trigger / Bandpass)."""

    def __init__(self):
        self._rx_sampling_callback = None
        self._build()

    def _hw(self):
        from . import mri_overlay
        return mri_overlay.get_overlay()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.Tab:
        return self._tab

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        self._tab = widgets.Tab(layout=widgets.Layout(width='100%'))
        self._tab.children = [
            self._build_chip_config(),
            self._build_adc_trigger(),
            self._build_bandpass(),
        ]
        self._tab.set_title(0, 'Chip Config')
        self._tab.set_title(1, 'Sampling')
        self._tab.set_title(2, 'Bandpass Filter')

    # ── Tab 0 – Chip Config ────────────────────────────────────────────────────
    def _build_chip_config(self) -> widgets.Widget:
        self.mixer_btn = widgets.ToggleButton(value=False, description='Mixer OFF',
                                              button_style='danger',
                                              layout=widgets.Layout(width='120px', height='32px'))
        self.pll_btn = widgets.ToggleButton(value=False, description='PLL OFF',
                                            button_style='danger',
                                            layout=widgets.Layout(width='120px', height='32px'))
        self.if_amp_btn = widgets.ToggleButton(value=False, description='IF Amp OFF',
                                               button_style='danger',
                                               layout=widgets.Layout(width='130px', height='32px'))
        self.mixer_btn.observe(self._on_mixer, names='value')
        self.pll_btn.observe(self._on_pll_hv, names='value')
        self.if_amp_btn.observe(self._on_if_amp, names='value')
        hv_row = widgets.HBox([self.mixer_btn, self.pll_btn, self.if_amp_btn],
                              layout=widgets.Layout(flex_wrap='wrap'))

        spi_row1 = widgets.HBox(_spi[:6])
        spi_row2 = widgets.HBox(_spi[6:])
        self.spi_init_btn = widgets.Button(description='Send SPI Config', button_style='warning',
                                           layout=widgets.Layout(width='160px', height='32px'))
        self.spi_status = widgets.HTML('<span style="color:#8b949e">SPI idle.</span>')
        self.spi_init_btn.on_click(lambda _: self._spi_init_cmd())

        return widgets.VBox([
            widgets.HTML('<b style="color:#d29922">HV Chip (Heiko):</b>'), hv_row,
            widgets.HTML('<b style="color:#8b949e">SPI Parameters (HV chip):</b>'),
            spi_row1, spi_row2,
            widgets.HBox([self.spi_init_btn, self.spi_status]),
        ], layout=widgets.Layout(padding='8px'))

    # ── Tab 1 – Sampling ───────────────────────────────────────────────────────
    def _build_adc_trigger(self) -> widgets.Widget:
        self.clock_div = widgets.IntSlider(
            value=100, min=1, max=100000, step=1,
            description='Clock divider (100/x MHz):', continuous_update=False,
            layout=widgets.Layout(width='440px'), style={'description_width': '180px'})
        self.nr_samples = widgets.IntSlider(
            value=2000, min=64, max=2**22, step=1,
            description='Nr Samples (per RX):', continuous_update=False,
            layout=widgets.Layout(width='440px'), style={'description_width': '180px'})
        self.auto_rx_samples = widgets.Checkbox(
            value=True, description='Auto RX samples', indent=False,
            layout=widgets.Layout(width='160px'))
        self.rx_total = widgets.IntProgress(
            value=0, min=0, max=1, description='RX total:',
            style={'description_width': '70px', 'bar_color': '#58a6ff'},
            layout=widgets.Layout(width='440px', height='22px'))
        self.rx_info = widgets.HTML(
            '<span style="color:#8b949e">Load a sequence to calculate RX sampling.</span>')
        self.dig_ris = widgets.Checkbox(value=True, description='Dig Rising', indent=False,
                                        layout=widgets.Layout(width='120px'))
        self.dig_fal = widgets.Checkbox(value=False, description='Dig Falling', indent=False,
                                        layout=widgets.Layout(width='120px'))

        self.clock_div.observe(self._on_clock_div, names='value')
        self.nr_samples.observe(self._on_nr_samples, names='value')
        self.auto_rx_samples.observe(self._on_auto_rx_samples, names='value')
        self.dig_ris.observe(self._on_dig_ris, names='value')
        self.dig_fal.observe(self._on_dig_fal, names='value')

        return widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">Sampling:</b>'),
            widgets.HBox([self.auto_rx_samples]),
            self.clock_div, self.nr_samples, self.rx_total, self.rx_info,
            widgets.HTML('<span style="color:#8b949e">ADC mode is fixed at 9; trigger mode is fixed at single shot.</span>'),
            widgets.HTML('<b style="color:#8b949e">Digital Trigger:</b>'),
            widgets.HBox([self.dig_ris, self.dig_fal]),
        ], layout=widgets.Layout(padding='8px'))

    # ── Tab 2 – Bandpass ───────────────────────────────────────────────────────
    def _build_bandpass(self) -> widgets.Widget:
        self.bp_low = widgets.FloatText(value=1, description='f_low (kHz):',
                                        layout=widgets.Layout(width='200px'),
                                        style={'description_width': '90px'})
        self.bp_high = widgets.FloatText(value=100, description='f_high (kHz):',
                                         layout=widgets.Layout(width='200px'),
                                         style={'description_width': '90px'})
        self.bp_butter = widgets.Checkbox(value=False, description='Butterworth', indent=False,
                                          layout=widgets.Layout(width='140px'))
        self.bp_cheby1 = widgets.Checkbox(value=False, description='Chebyshev I', indent=False,
                                          layout=widgets.Layout(width='140px'))
        self.bp_cheby2 = widgets.Checkbox(value=False, description='Chebyshev II', indent=False,
                                          layout=widgets.Layout(width='140px'))
        self.bp_order = widgets.IntText(value=3, description='Order:',
                                        layout=widgets.Layout(width='150px'),
                                        style={'description_width': '55px'})
        freq_row = widgets.HBox([self.bp_low, self.bp_high, self.bp_order])
        type_row = widgets.HBox([self.bp_butter, self.bp_cheby1, self.bp_cheby2])

        return widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">Frequency Range:</b>'), freq_row,
            widgets.HTML('<b style="color:#58a6ff">Filter Type:</b>'), type_row,
        ], layout=widgets.Layout(padding='8px'))

    # ── HV chip SPI callbacks ──────────────────────────────────────────────────
    def _on_mixer(self, change):
        self.mixer_btn.button_style = 'success' if change['new'] else 'danger'
        self.mixer_btn.description = 'Mixer ON' if change['new'] else 'Mixer OFF'
        self._spi_init_cmd()

    def _on_pll_hv(self, change):
        self.pll_btn.button_style = 'success' if change['new'] else 'danger'
        self.pll_btn.description = 'PLL ON' if change['new'] else 'PLL OFF'
        self._spi_init_cmd()

    def _on_if_amp(self, change):
        self.if_amp_btn.button_style = 'success' if change['new'] else 'danger'
        self.if_amp_btn.description = 'IF Amp ON' if change['new'] else 'IF Amp OFF'
        self._spi_init_cmd()

    def _spi_init_cmd(self):
        hw = self._hw()
        if not hw.initialized:
            self.spi_status.value = '<span style="color:#d29922">FPGA not initialised.</span>'
            return
        try:
            spi = hw.spi
            spi.pll_flag = 1 if self.pll_btn.value else 0
            spi.mixer_flag = 0 if self.mixer_btn.value else 1
            spi.gain_flag = 0 if self.if_amp_btn.value else 1
            spi.pll_prescaler = _spi[0].value
            spi.N_divider = _spi[1].value
            spi.prescaler_tx_logic = _spi[2].value
            spi.tx_shortening_counter = _spi[3].value
            spi.deadtime_hs_p = _spi[4].value
            spi.deadtime_ls_p = _spi[5].value
            spi.deadtime_hs_n = _spi[6].value
            spi.deadtime_ls_n = _spi[7].value
            spi.deadtime_comp_p = _spi[8].value
            spi.deadtime_comp_n = _spi[9].value
            spi.delay_p = _spi[10].value
            spi.delay_n = _spi[11].value
            spi.spi_init_cmd()
            self.spi_status.value = '<span style="color:#3fb950">SPI sent.</span>'
        except Exception as exc:
            self.spi_status.value = f'<span style="color:#f85149">SPI error: {exc}</span>'
            raise

    # ── ADC & Trigger callbacks ────────────────────────────────────────────────
    def _on_clock_div(self, change):
        gui_state_module.state.clock_div = change['new']
        hw = self._hw()
        if hw.initialized:
            hw.osci_clock_step_size(change['new'])
        if self.auto_rx_samples.value and self._rx_sampling_callback is not None:
            self._rx_sampling_callback()

    def _on_nr_samples(self, change):
        gui_state_module.state.nr_samples = change['new']
        hw = self._hw()
        if hw.initialized:
            hw.osci_set_nr_samples(change['new'])

    def _on_auto_rx_samples(self, change):
        gui_state_module.state.auto_rx_samples = bool(change['new'])
        if change['new'] and self._rx_sampling_callback is not None:
            self._rx_sampling_callback()

    def _on_dig_ris(self, change):
        hw = self._hw()
        if hw.initialized:
            hw.osci_dig_trigger_ris(1 if change['new'] else 0)

    def _on_dig_fal(self, change):
        hw = self._hw()
        if hw.initialized:
            hw.osci_dig_trigger_fal(1 if change['new'] else 0)

    # ── public helpers ─────────────────────────────────────────────────────────
    def get_filter_type(self) -> int:
        if self.bp_butter.value:
            return 2
        if self.bp_cheby1.value:
            return 3
        if self.bp_cheby2.value:
            return 4
        return 0

    def get_filter_freqs(self):
        return self.bp_low.value * 1000, self.bp_high.value * 1000

    def get_bp_order(self) -> int:
        return self.bp_order.value

    def get_clock_div(self) -> int:
        return self.clock_div.value

    def set_rx_sampling_callback(self, callback):
        self._rx_sampling_callback = callback

    def auto_rx_enabled(self) -> bool:
        return bool(self.auto_rx_samples.value)

    def set_clock_div(self, value: int):
        value = max(self.clock_div.min, min(self.clock_div.max, int(value)))
        if self.clock_div.value != value:
            self.clock_div.value = value
        else:
            self._on_clock_div({'new': value})

    def get_nr_samples(self) -> int:
        return self.nr_samples.value

    def set_nr_samples(self, value: int):
        value = max(self.nr_samples.min, min(self.nr_samples.max, int(value)))
        if self.nr_samples.value != value:
            self.nr_samples.value = value
        else:
            self._on_nr_samples({'new': value})

    def set_rx_sampling_summary(self, summary: dict):
        self.set_nr_samples(summary.get('nr_samples', self.nr_samples.value))

        state = gui_state_module.state
        state.auto_rx_samples = self.auto_rx_samples.value
        state.rx_total_time_us = float(summary.get('total_rx_us', 0.0))
        state.rx_total_samples = int(summary.get('total_rx_samples', 0))
        state.dma_samples_per_channel = int(summary.get('dma_samples_per_channel', 0))
        state.nr_rx_pulses = int(summary.get('nr_rx', 1))
        state.sample_rate_hz = float(summary.get('sample_rate_hz', 0.0))

        total_samples = max(0, int(summary.get('total_rx_samples', 0)))
        dma_samples = max(1, int(summary.get('dma_samples_per_channel', total_samples)))
        self.rx_total.max = max(1, dma_samples)
        self.rx_total.value = min(total_samples, self.rx_total.max)

        fs_mhz = float(summary.get('sample_rate_hz', 0.0)) / 1_000_000.0
        total_us = float(summary.get('total_rx_us', 0.0))
        nr_rx = int(summary.get('nr_rx', 1))
        nr_samples = int(summary.get('nr_samples', self.nr_samples.value))
        self.rx_info.value = (
            '<span style="color:#8b949e">'
            f'{nr_rx} RX window(s), total RX {total_us:g} us -> '
            f'{total_samples} samples/ch at {fs_mhz:g} MS/s. '
            f'DMA uses {nr_samples} samples/RX ({dma_samples} samples/ch allocated).'
            '</span>')
