# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_plot_panel
# --   Plot panel — two Plotly FigureWidgets (time domain + FFT / T2) with
# --   helper methods to update traces from numpy arrays.  Downsamples to keep
# --   Plotly responsive.
# ----------------------------------------------------------------------------------

import ipywidgets as widgets
import plotly.graph_objects as go
import numpy as np

# Display geometry (kept local so the panel has no external constant deps).
SCREEN_W = 1920
SCREEN_H = 1080
SCREEN_POINTS = 1024   # max points rendered per trace


class PlotPanel:
    """Owns the time-domain and FFT/T2 figures and their update helpers."""

    def __init__(self):
        self._build()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.HBox:
        return self._root

    @property
    def fig_time(self) -> go.FigureWidget:
        return self._fig_time

    @property
    def fig_fft(self) -> go.FigureWidget:
        return self._fig_fft

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        self._fig_time = self._make_time_fig()
        self._fig_fft = self._make_fft_fig()
        self._root = widgets.HBox(
            [self._fig_time, self._fig_fft],
            layout=widgets.Layout(width='100%'),
        )

    def _make_time_fig(self) -> go.FigureWidget:
        fig = go.FigureWidget(layout=go.Layout(
            height=round(0.324 * SCREEN_H),
            width=round(0.45 * SCREEN_W),
            margin=dict(t=24, b=40, l=60, r=10),
            xaxis=dict(title='Time (µs)', gridcolor='#e0e0e0', linecolor='#aaaaaa'),
            yaxis=dict(title='Voltage (mV)', gridcolor='#e0e0e0', linecolor='#aaaaaa'),
            showlegend=True, hovermode=False,
            legend=dict(yanchor='top', y=0.99, xanchor='left', x=0.01),
            plot_bgcolor='white', paper_bgcolor='white',
            font=dict(color='#333333', size=11),
        ))
        fig.add_trace(go.Scattergl(x=[], y=[], name='Ch 0',
                                   line=dict(color='#1d4ed8', width=1)))
        fig.add_trace(go.Scattergl(x=[], y=[], name='Ch 1',
                                   line=dict(color='#15803d', width=1)))
        return fig

    def _make_fft_fig(self) -> go.FigureWidget:
        fig = go.FigureWidget(layout=go.Layout(
            height=round(0.324 * SCREEN_H),
            width=round(0.28 * SCREEN_W),
            margin=dict(t=24, b=40, l=60, r=10),
            xaxis=dict(title='Frequency (Hz)', gridcolor='#e0e0e0', linecolor='#aaaaaa'),
            yaxis=dict(title='Amplitude (a.u.)', gridcolor='#e0e0e0', linecolor='#aaaaaa'),
            showlegend=True, hovermode=False,
            plot_bgcolor='white', paper_bgcolor='white',
            font=dict(color='#333333', size=11),
        ))
        fig.add_trace(go.Scattergl(x=[], y=[], name='FFT',
                                   line=dict(color='#dc2626', width=1)))
        fig.add_trace(go.Scattergl(x=[], y=[], name='T2 data',
                                   line=dict(color='#15803d', width=1), visible=False))
        fig.add_trace(go.Scattergl(x=[], y=[], name='T2 fit',
                                   line=dict(color='#b45309', width=2, dash='dash'),
                                   visible=False))
        fig.add_annotation(x=0, y=0, text='T₂ = -', showarrow=False,
                           font=dict(size=14, color='#b45309'), visible=False)
        return fig

    # ── update helpers ────────────────────────────────────────────────────────
    def update_time(self, time_us, ch0_mv, ch1_mv):
        n = len(time_us)
        if n > SCREEN_POINTS:
            idx = np.linspace(0, n - 1, SCREEN_POINTS, dtype=int)
            t, y0, y1 = time_us[idx], ch0_mv[idx], ch1_mv[idx]
        else:
            t, y0, y1 = time_us, ch0_mv, ch1_mv
        with self._fig_time.batch_update():
            self._fig_time.data[0].x = np.asarray(t).tolist()
            self._fig_time.data[0].y = np.asarray(y0).tolist()
            self._fig_time.data[1].x = np.asarray(t).tolist()
            self._fig_time.data[1].y = np.asarray(y1).tolist()

    def update_fft(self, freqs, amplitudes):
        with self._fig_fft.batch_update():
            self._fig_fft.data[0].x = np.asarray(freqs).tolist()
            self._fig_fft.data[0].y = np.asarray(amplitudes).tolist()
            self._fig_fft.data[0].visible = True

    def clear_fft(self):
        with self._fig_fft.batch_update():
            self._fig_fft.data[0].x = []
            self._fig_fft.data[0].y = []
            self._fig_fft.data[0].visible = False

    def update_t2(self, t_axis, envelope, fit_curve=None, t2_value=None):
        with self._fig_fft.batch_update():
            self._fig_fft.data[1].x = np.asarray(t_axis).tolist()
            self._fig_fft.data[1].y = np.asarray(envelope).tolist()
            self._fig_fft.data[1].visible = True
            if fit_curve is not None:
                self._fig_fft.data[2].x = np.asarray(t_axis).tolist()
                self._fig_fft.data[2].y = np.asarray(fit_curve).tolist()
                self._fig_fft.data[2].visible = True
            if t2_value is not None:
                self._fig_fft.layout.annotations[0].text = f'T₂ = {t2_value:.2f} ms'
                self._fig_fft.layout.annotations[0].visible = True
