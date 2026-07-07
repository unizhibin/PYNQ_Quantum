# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_analysis_panel
# --   Analysis — FFT toggle + channel select, T2 fitting, data saving.
# ----------------------------------------------------------------------------------

import ipywidgets as widgets
import numpy as np

from . import gui_state as gui_state_module


class AnalysisPanel:
    """FFT control, T2 fitting display and data-save controls."""

    def __init__(self, save_callback, refresh_callback=None):
        """
        Parameters
        ----------
        save_callback    : callable(ch0, ch1, filename, fmt)
        refresh_callback : callable() | None  — re-draw plots after FFT toggle.
        """
        self._save_cb = save_callback
        self._refresh_cb = refresh_callback
        self._build()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.VBox:
        return self._root

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        self._root = widgets.VBox([
            self._build_fft_section(),
            self._build_t2_section(),
            self._build_save_section(),
        ], layout=widgets.Layout(padding='8px', width='100%'))

    # ── FFT ───────────────────────────────────────────────────────────────────
    def _build_fft_section(self) -> widgets.Widget:
        self.fft_toggle = widgets.ToggleButton(
            value=False, description='FFT Off', button_style='danger',
            layout=widgets.Layout(width='130px', height='32px'))
        self.fft_channel = widgets.Dropdown(
            options=[('Ch 0', 0), ('Ch 1', 1)], value=0, description='Channel:',
            layout=widgets.Layout(width='160px'), style={'description_width': '65px'})
        self.fft_toggle.observe(self._on_fft_toggle, names='value')
        self.fft_channel.observe(self._on_fft_channel, names='value')

        return widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">FFT</b>'),
            widgets.HBox([self.fft_toggle, self.fft_channel]),
        ], layout=widgets.Layout(border='1px solid #30363d', border_radius='6px',
                                 padding='8px', margin='0 0 6px 0'))

    def _on_fft_toggle(self, change):
        v = change['new']
        gui_state_module.state.fft_enabled = v
        self.fft_toggle.description = 'FFT On' if v else 'FFT Off'
        self.fft_toggle.button_style = 'success' if v else 'danger'
        if self._refresh_cb:
            self._refresh_cb()

    def _on_fft_channel(self, change):
        gui_state_module.state.fft_channel = change['new']
        if self._refresh_cb and gui_state_module.state.fft_enabled:
            self._refresh_cb()

    # ── T2 fitting ─────────────────────────────────────────────────────────────
    def _build_t2_section(self) -> widgets.Widget:
        self.t2_display = widgets.HTML('<span style="color:#8b949e">T₂ not yet fitted.</span>')
        self.fwhm_display = widgets.HTML('<span style="color:#8b949e">FWHM not yet measured.</span>')
        self.run_t2_btn = widgets.Button(
            description='Fit T2', button_style='',
            layout=widgets.Layout(width='100px', height='30px'))
        self.run_t2_btn.on_click(self._on_run_t2)

        return widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">T₂ &amp; FWHM</b>'),
            widgets.HBox([self.run_t2_btn, self.fwhm_display]),
            self.t2_display,
        ], layout=widgets.Layout(border='1px solid #30363d', border_radius='6px',
                                 padding='8px', margin='0 0 6px 0'))

    def _on_run_t2(self, _):
        from scipy.optimize import curve_fit
        state = gui_state_module.state
        if state.ch1_raw is None:
            self.t2_display.value = '<span style="color:#d29922">No data yet.</span>'
            return
        try:
            data = np.abs(np.asarray(state.ch1_raw, dtype=float))
            t = np.arange(len(data))

            def _exp(x, A, T2, offset):
                return A * np.exp(-x / T2) + offset

            p0 = [data.max(), len(data) / 3, data.min()]
            popt, _ = curve_fit(_exp, t, data, p0=p0, maxfev=4000)
            self.t2_display.value = (
                f'<b>T₂ = {popt[1]:.2f} samples</b>'
                f' (A={popt[0]:.1f}, offset={popt[2]:.1f})')
        except Exception as e:
            self.t2_display.value = f'<span style="color:#f85149">Fit error: {e}</span>'
            raise

    def update_fwhm(self, fwhm_hz: float):
        self.fwhm_display.value = f'<b>FWHM = {fwhm_hz:.2f} Hz</b>'

    # ── Save ───────────────────────────────────────────────────────────────────
    def _build_save_section(self) -> widgets.Widget:
        self.save_name = widgets.Text(
            value='Untitled', description='Filename:',
            layout=widgets.Layout(width='280px'), style={'description_width': '70px'})
        self.save_format = widgets.Dropdown(
            options=[('.csv', 0), ('.txt', 1)], value=0, description='Format:',
            layout=widgets.Layout(width='160px'), style={'description_width': '60px'})
        self.save_btn = widgets.Button(
            description='💾 Save', button_style='primary',
            layout=widgets.Layout(width='100px', height='32px'))
        self.save_status = widgets.HTML('<span style="color:#8b949e">—</span>')

        self.save_name.observe(self._on_name_change, names='value')
        self.save_btn.on_click(self._on_save)

        return widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">Save Data</b>'),
            widgets.HBox([self.save_name, self.save_format, self.save_btn]),
            self.save_status,
        ], layout=widgets.Layout(border='1px solid #30363d', border_radius='6px',
                                 padding='8px'))

    def _on_name_change(self, change):
        gui_state_module.state.save_name = change['new'] or 'Untitled'

    def _on_save(self, _):
        state = gui_state_module.state
        if state.ch0_raw is None:
            self.save_status.value = '<span style="color:#d29922">No data to save.</span>'
            return
        try:
            name = self.save_name.value or 'Untitled'
            fmt = self.save_format.value
            path = self._save_cb(state.ch0_raw, state.ch1_raw, name, fmt)
            extra = f' → {path}' if path else ''
            self.save_status.value = (
                f'<span style="color:#3fb950">✔ Saved as "{name}"{extra}</span>')
        except Exception as e:
            self.save_status.value = f'<span style="color:#f85149">Save error: {e}</span>'
            raise
