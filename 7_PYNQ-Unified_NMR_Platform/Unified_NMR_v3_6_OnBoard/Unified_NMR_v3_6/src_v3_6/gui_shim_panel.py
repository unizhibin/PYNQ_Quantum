# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_shim_panel
# --   Auto-Shim panel — manual DAC sliders for all 8 shim channels plus
# --   automated optimisation (Golden Section / Nelder-Mead) with a live
# --   FWHM-vs-iteration plot.
# ----------------------------------------------------------------------------------

import threading
import ipywidgets as widgets
import plotly.graph_objects as go

from . import shim_algorithms as shim_alg
from .shim_algorithms import SHIM_CHANNEL_NAMES, DAC_MIN, DAC_MAX


class ShimPanel:
    """Manual + automated shim control."""

    def __init__(self, run_fid_callback, shim_dac_set_fn=None):
        """
        Parameters
        ----------
        run_fid_callback : callable() → (ch0_arr, ch1_arr, fs_hz)
        shim_dac_set_fn  : callable(channel: int, value: int) | None
            Sets one shim DAC channel.  Falls back to mri_overlay if None.
        """
        self._run_fid = run_fid_callback
        self._shim_dac_set_fn = shim_dac_set_fn
        self._stop_flag = threading.Event()
        self._shim_thread = None
        self._fwhm_history = []
        self._current_dac = {ch: 2000 for ch in range(8)}
        self._build()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.VBox:
        return self._root

    def _set_shim_dac(self, ch: int, val: int):
        if self._shim_dac_set_fn is not None:
            self._shim_dac_set_fn(ch, val)
        else:
            from . import mri_overlay
            hw = mri_overlay.get_overlay()
            if hw.initialized:
                hw.shim_da4_set(ch, val)

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        self._root = widgets.VBox([
            self._build_manual_dac(),
            self._build_auto_shim(),
            self._build_progress(),
        ], layout=widgets.Layout(padding='8px', width='100%'))

    # ── manual DAC ─────────────────────────────────────────────────────────────
    def _build_manual_dac(self) -> widgets.Widget:
        header = widgets.HTML('<b style="color:#58a6ff">Manual Shim DAC Channels</b>')
        self._dac_sliders = {}
        for ch in range(8):
            s = widgets.IntSlider(
                value=2000, min=DAC_MIN, max=DAC_MAX, step=1,
                description=f'Ch {ch} ({SHIM_CHANNEL_NAMES[ch]}):',
                continuous_update=False,
                layout=widgets.Layout(width='480px'),
                style={'description_width': '100px'})
            s.observe(self._make_dac_observer(ch), names='value')
            self._dac_sliders[ch] = s

        left = widgets.VBox([self._dac_sliders[i] for i in range(4)])
        right = widgets.VBox([self._dac_sliders[i] for i in range(4, 8)])
        self.reset_dac_btn = widgets.Button(
            description='Reset all to 2000', button_style='warning',
            layout=widgets.Layout(width='160px', height='30px'))
        self.reset_dac_btn.on_click(self._on_reset_dac)

        return widgets.VBox([header, widgets.HBox([left, right]), self.reset_dac_btn],
                            layout=widgets.Layout(border='1px solid #30363d',
                                                  border_radius='6px', padding='8px',
                                                  margin='0 0 8px 0'))

    def _make_dac_observer(self, ch: int):
        def _obs(change):
            val = change['new']
            self._current_dac[ch] = val
            self._set_shim_dac(ch, val)
        return _obs

    def _on_reset_dac(self, _):
        for ch in range(8):
            self._dac_sliders[ch].value = 2000
            self._set_shim_dac(ch, 2000)

    # ── auto-shim ──────────────────────────────────────────────────────────────
    def _build_auto_shim(self) -> widgets.Widget:
        header = widgets.HTML('<b style="color:#58a6ff">Auto-Shim Optimisation</b>')
        lyt = widgets.Layout(width='220px')
        sty = {'description_width': '130px'}

        self.algo_choice = widgets.ToggleButtons(
            options=['Golden Section', 'Nelder-Mead'], value='Golden Section',
            description='Algorithm:',
            style={'description_width': '90px', 'button_width': '140px'})
        self.shim_anchor = widgets.FloatText(value=80e3, description='Anchor freq (Hz):',
                                             layout=lyt, style=sty)
        self.shim_range = widgets.FloatText(value=500.0, description='Search range (DAC):',
                                            layout=lyt, style=sty)
        self.shim_thr = widgets.FloatText(value=10.0, description='FWHM target (Hz):',
                                          layout=lyt, style=sty)
        self.shim_iter = widgets.IntText(value=10, description='Max iterations:',
                                         layout=lyt, style=sty)
        self.shim_avg = widgets.IntText(value=1, description='Averages/meas:',
                                        layout=lyt, style=sty)
        self.shim_order = widgets.Text(value='0,1,2,3,6,7,5,4', description='Channel order:',
                                       layout=widgets.Layout(width='260px'),
                                       style={'description_width': '130px'})

        self.run_shim_btn = widgets.Button(
            description='▶ Run Auto-Shim', button_style='success',
            layout=widgets.Layout(width='160px', height='32px'))
        self.stop_shim_btn = widgets.Button(
            description='■ Stop', button_style='danger',
            layout=widgets.Layout(width='100px', height='32px'), disabled=True)
        self.shim_status = widgets.HTML('<span style="color:#8b949e">Idle.</span>')

        self.run_shim_btn.on_click(self._on_run_shim)
        self.stop_shim_btn.on_click(self._on_stop_shim)

        params_row = widgets.HBox([
            widgets.VBox([self.shim_anchor, self.shim_range, self.shim_thr]),
            widgets.VBox([self.shim_iter, self.shim_avg, self.shim_order]),
        ])
        ctrl_row = widgets.HBox([self.run_shim_btn, self.stop_shim_btn, self.shim_status],
                                layout=widgets.Layout(align_items='center'))

        return widgets.VBox([header, self.algo_choice, params_row, ctrl_row],
                            layout=widgets.Layout(border='1px solid #30363d',
                                                  border_radius='6px', padding='8px',
                                                  margin='0 0 8px 0'))

    # ── FWHM progress plot ─────────────────────────────────────────────────────
    def _build_progress(self) -> widgets.Widget:
        header = widgets.HTML('<b style="color:#58a6ff">FWHM vs. Iteration</b>')
        self._fwhm_fig = go.FigureWidget(layout=go.Layout(
            height=200, margin=dict(t=10, b=40, l=60, r=20),
            xaxis=dict(title='Iteration', gridcolor='#e0e0e0'),
            yaxis=dict(title='FWHM (Hz)', gridcolor='#e0e0e0'),
            plot_bgcolor='white', paper_bgcolor='white',
            font=dict(color='#333333', size=11)))
        self._fwhm_fig.add_trace(go.Scatter(
            x=[], y=[], mode='lines+markers',
            line=dict(color='#1d4ed8', width=2),
            marker=dict(size=5, color='#1d4ed8')))

        self.fwhm_progress = widgets.IntProgress(
            value=0, min=0, max=100, description='Progress:',
            style={'description_width': '70px', 'bar_color': '#3fb950'},
            layout=widgets.Layout(width='360px', height='24px'))

        return widgets.VBox([header, self._fwhm_fig, self.fwhm_progress],
                            layout=widgets.Layout(border='1px solid #30363d',
                                                  border_radius='6px', padding='8px'))

    # ── run logic ──────────────────────────────────────────────────────────────
    def _on_run_shim(self, _):
        if self._shim_thread and self._shim_thread.is_alive():
            return
        self._stop_flag.clear()
        self._fwhm_history = []
        self.run_shim_btn.disabled = True
        self.stop_shim_btn.disabled = False
        self.shim_status.value = '<span style="color:#d29922">Running…</span>'
        self._shim_thread = threading.Thread(target=self._shim_worker, daemon=True)
        self._shim_thread.start()

    def _on_stop_shim(self, _):
        self._stop_flag.set()
        self.shim_status.value = '<span style="color:#d29922">Stopping…</span>'

    def _shim_worker(self):
        try:
            anchor = self.shim_anchor.value
            param_rng = self.shim_range.value
            thr = self.shim_thr.value
            max_iter = self.shim_iter.value
            avg_nr = self.shim_avg.value
            algo = self.algo_choice.value

            try:
                order = [int(x.strip()) for x in self.shim_order.value.split(',')]
            except ValueError:
                order = [0, 1, 2, 3, 6, 7, 5, 4]

            def _feedback_single(channel, dac_val):
                if self._stop_flag.is_set():
                    return 9999.0, 9999.0, 0.0
                ch0, ch1, fs = self._run_fid()
                fwhm, bw, amp = shim_alg.measure_fwhm_czt(
                    ch0.astype(float), fs, anchor_freq=anchor)
                return fwhm, bw, amp

            def _feedback_multi(dac_vals):
                if self._stop_flag.is_set():
                    return 9999.0, 9999.0, 0.0
                ch0, ch1, fs = self._run_fid()
                fwhm, bw, amp = shim_alg.measure_fwhm_czt(
                    ch0.astype(float), fs, anchor_freq=anchor)
                return fwhm, bw, amp

            def _set_dac(ch, val):
                self._current_dac[ch] = val
                self._set_shim_dac(ch, val)
                self._dac_sliders[ch].value = int(val)

            def _progress_cb(step, total, fwhm):
                if self._stop_flag.is_set():
                    return
                self._fwhm_history.append(fwhm)
                self._update_fwhm_plot(self._fwhm_history)
                pct = min(100, round(step / max(total, 1) * 100))
                self.fwhm_progress.value = pct
                self.shim_status.value = (
                    f'<span style="color:#d29922">Step {step}/{total} '
                    f'— FWHM: {fwhm:.1f} Hz</span>')

            if algo == 'Golden Section':
                shim_alg.auto_cali_golden(
                    feedback_function=_feedback_single, set_dac=_set_dac, order=order,
                    param_range_magnitude=param_rng, max_iter=max_iter,
                    fwhm_threshold=thr, anchor_freq=anchor, avg_nr=avg_nr,
                    progress_callback=_progress_cb)
                self.shim_status.value = (
                    '<span style="color:#3fb950">✔ Golden Section complete. '
                    f'Best FWHM: {self._fwhm_history[-1]:.1f} Hz</span>'
                    if self._fwhm_history else
                    '<span style="color:#3fb950">✔ Done (no measurements taken).</span>')
            else:
                init_params = [self._current_dac.get(ch, 2000) for ch in range(8)]
                result, best_fwhm = shim_alg.nelder_mead_optimize(
                    feedback_function=_feedback_multi, set_dac=_set_dac,
                    channels=list(range(8)), init_params=init_params, step=param_rng,
                    max_iter=max_iter, fwhm_threshold=thr, anchor_freq=anchor,
                    avg_nr=avg_nr, progress_callback=_progress_cb)
                for ch, val in zip(range(8), result):
                    _set_dac(ch, val)
                self.shim_status.value = (
                    f'<span style="color:#3fb950">✔ Nelder-Mead complete. '
                    f'Best FWHM: {best_fwhm:.1f} Hz</span>')
        except Exception as e:
            self.shim_status.value = f'<span style="color:#f85149">Error: {e}</span>'
            raise
        finally:
            self.run_shim_btn.disabled = False
            self.stop_shim_btn.disabled = True

    def _update_fwhm_plot(self, history):
        with self._fwhm_fig.batch_update():
            self._fwhm_fig.data[0].x = list(range(1, len(history) + 1))
            self._fwhm_fig.data[0].y = history
