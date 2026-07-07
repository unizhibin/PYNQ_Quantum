# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_experiment_panel
# --   Experiment control -- run / single / stop, averages, loop count, TR
# --   and progress bar.
# --   The hardware loop is injected via callbacks (no hardware import here).
# ----------------------------------------------------------------------------------

import threading
import ipywidgets as widgets

from . import gui_state as gui_state_module
from .experiment_control import ExperimentConfig, parse_section_id_list


class ExperimentPanel:
    """Run / single-scan / stop controls plus an averaging progress bar."""

    def __init__(self, run_experiment_callback, avg_experiment_callback,
                 clock_div_callback):
        """
        Parameters
        ----------
        run_experiment_callback : callable(config, stop_flag)
            Runs one configured experiment, updates gui_state.state.ch0_raw / ch1_raw.
        avg_experiment_callback : callable(config, stop_flag)
            Runs a configured averaging/loop experiment.
        """
        self._run_exp = run_experiment_callback
        self._avg_exp = avg_experiment_callback
        self._clock_div = clock_div_callback
        self._stop_flag = threading.Event()
        self._exp_thread = None
        self._build()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.VBox:
        return self._root

    @property
    def progress(self) -> widgets.IntProgress:
        return self.prog

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        lyt = widgets.Layout(width='230px')
        sty = {'description_width': '100px'}

        self.nr_avg = widgets.IntText(value=1, description='Nr Averages:',
                                      layout=lyt, style=sty)
        self.nr_loop = widgets.IntText(value=1, description='Loop Count:',
                                       layout=lyt, style=sty)
        self.tr_ms = widgets.FloatText(value=1000.0, description='TR (ms):',
                                       layout=lyt, style=sty)
        self.phase_cycle_enable = widgets.ToggleButton(
            value=False, description='Phase Cycle OFF', button_style='',
            layout=widgets.Layout(width='160px', height='32px'))
        self.phase_cycle_sections = widgets.Text(
            value='', description='Sections:',
            placeholder='5, 10',
            layout=widgets.Layout(width='260px'),
            style={'description_width': '75px'})
        self.phase_cycle_enable.observe(self._on_phase_cycle_toggle, names='value')

        self.run_btn = widgets.Button(
            description='▶ Run Experiment', button_style='success',
            layout=widgets.Layout(width='170px', height='34px'))
        self.single_btn = widgets.Button(
            description='Run 1 Scan', button_style='',
            layout=widgets.Layout(width='130px', height='34px'))
        self.stop_btn = widgets.Button(
            description='■ Stop', button_style='danger',
            layout=widgets.Layout(width='100px', height='34px'), disabled=True)

        self.prog = widgets.IntProgress(
            value=0, min=0, max=100, description='Avg:',
            style={'description_width': '35px', 'bar_color': '#3fb950'},
            layout=widgets.Layout(width='360px', height='24px'))
        self.status = widgets.HTML('<span style="color:#8b949e">Ready.</span>')

        self.run_btn.on_click(self._on_run)
        self.single_btn.on_click(self._on_single)
        self.stop_btn.on_click(self._on_stop)

        param_row = widgets.HBox([self.nr_avg, self.nr_loop, self.tr_ms],
                                 layout=widgets.Layout(flex_wrap='wrap'))
        phase_row = widgets.HBox([self.phase_cycle_enable, self.phase_cycle_sections],
                                 layout=widgets.Layout(flex_wrap='wrap',
                                                       align_items='center'))
        ctrl_row = widgets.HBox([self.run_btn, self.single_btn, self.stop_btn],
                                layout=widgets.Layout(align_items='center'))

        self._root = widgets.VBox([
            widgets.HTML('<b style="color:#58a6ff">Experiment Control</b>'),
            param_row,
            widgets.HTML('<b style="color:#58a6ff">Phase Cycling</b>'),
            phase_row,
            ctrl_row, self.prog, self.status,
        ], layout=widgets.Layout(padding='8px', width='100%'))

    # ── callbacks ─────────────────────────────────────────────────────────────
    def _on_run(self, _):
        if self._exp_thread and self._exp_thread.is_alive():
            return
        self._stop_flag.clear()
        self._set_running(True)
        self._exp_thread = threading.Thread(target=self._worker_avg, daemon=True)
        self._exp_thread.start()

    def _on_single(self, _):
        if self._exp_thread and self._exp_thread.is_alive():
            return
        self._stop_flag.clear()
        self._set_running(True)
        self._exp_thread = threading.Thread(target=self._worker_single, daemon=True)
        self._exp_thread.start()

    def _on_stop(self, _):
        self._stop_flag.set()
        gui_state_module.state.exp_stop = True
        self.status.value = '<span style="color:#d29922">Stopping after current average…</span>'

    def _on_phase_cycle_toggle(self, change):
        enabled = bool(change['new'])
        self.phase_cycle_enable.description = 'Phase Cycle ON' if enabled else 'Phase Cycle OFF'
        self.phase_cycle_enable.button_style = 'success' if enabled else ''

    def _config_from_widgets(self, *, single: bool = False) -> ExperimentConfig:
        return ExperimentConfig(
            clock_div=max(1, int(self._clock_div())),
            num_averages=1 if single else max(1, int(self.nr_avg.value)),
            loop_count=1 if single else max(1, int(self.nr_loop.value)),
            tr_ms=max(0.0, float(self.tr_ms.value)),
            phase_cycling_enabled=bool(self.phase_cycle_enable.value),
            phase_cycle_sections=parse_section_id_list(self.phase_cycle_sections.value),
        )

    def _worker_avg(self):
        try:
            cfg = self._config_from_widgets()
            self.status.value = (
                f'<span style="color:#d29922">Running '
                f'{cfg.loop_count} loop(s) x {cfg.num_averages} average(s), '
                f'TR={cfg.tr_ms:g} ms'
                f'{", phase cycling" if cfg.phase_cycling_enabled else ""}...</span>')
            self._avg_exp(cfg, self._stop_flag)
            self.status.value = '<span style="color:#3fb950">✔ Done.</span>'
        except Exception as e:
            self.status.value = f'<span style="color:#f85149">Error: {e}</span>'
            raise
        finally:
            self._set_running(False)

    def _worker_single(self):
        try:
            gui_state_module.state.exp_stop = False
            self.status.value = '<span style="color:#d29922">Running single scan…</span>'
            self._run_exp(self._config_from_widgets(single=True), self._stop_flag)
            self.status.value = '<span style="color:#3fb950">✔ Single scan done.</span>'
        except Exception as e:
            self.status.value = f'<span style="color:#f85149">Error: {e}</span>'
            raise
        finally:
            self._set_running(False)

    def _set_running(self, is_running: bool):
        self.run_btn.disabled = is_running
        self.single_btn.disabled = is_running
        self.stop_btn.disabled = not is_running
        if not is_running:
            self.prog.value = 100 if self.prog.value > 0 else 0

    def set_progress(self, current: int, total: int):
        self.prog.value = min(100, round(current / max(total, 1) * 100))
