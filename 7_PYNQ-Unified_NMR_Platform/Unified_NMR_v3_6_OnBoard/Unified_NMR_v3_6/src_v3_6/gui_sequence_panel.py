# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_sequence_panel
# --   Sequence panel — quick-config generators (FID / Spin-Echo / CPMG),
# --   a raw JSON editor (validate / save / load), an interactive Plotly
# --   timeline, and a file browser for local sequence folders.
# --
# --   *** All JSON uses the REAL fpga_mri schema ***  (so generated sequences
# --   run on the overlay unchanged):
# --     ExpConfig : nr_sections, start_repeat_pointer, end_repeat_pointer,
# --                 cycle_repetition_number, experiment_repetition_number,
# --                 gradient_x/y/z_sweep_step
# --     Section   : section_id, section_type (0=TX,1=RX,2=delay), delay (µs),
# --                 mux, phase_ch0, frequency_ch0 (MHz), phase_ch1,
# --                 frequency_ch1 (MHz), rstn, x/y/z_gradient, x/y/z_ref,
# --                 gradient_sweep_flag, x/y/z_sweep_offset
# ----------------------------------------------------------------------------------

import os
import json

import ipywidgets as widgets
import plotly.graph_objects as go


# ── Section-type colours / lanes for the timeline ───────────────────────────────
_TIMELINE_COLOURS = {0: '#f87171', 1: '#34d399', 2: '#64748b'}
_TIMELINE_LANE = {0: 2, 1: 0, 2: 1}      # Y lane: 0=RX, 1=Delay, 2=TX
_TYPE_LABEL = {0: 'TX', 1: 'RX', 2: 'Delay'}


def _rgba(hex_colour: str, alpha: float = 0.4) -> str:
    """Convert '#rrggbb' to an 'rgba(r,g,b,a)' string accepted by Plotly."""
    h = hex_colour.lstrip('#')
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f'rgba({r},{g},{b},{alpha})'


# ─────────────────────────────────────────────────────────────────────────────────
# Section / sequence builders  (REAL fpga_mri schema)
# ─────────────────────────────────────────────────────────────────────────────────
def _section(sid, stype, delay_us, f_tx_mhz, f_rx_mhz, phase_deg=0.0, rstn=1,
             gx=2000, gy=2000, gz=2000, gxr=2000, gyr=2000, gzr=2000,
             sweep_flag=0, gx_off=0, gy_off=0, gz_off=0):
    """Return one section dict with all fields fpga_mri.MRI_Section understands."""
    return {
        "section_id":          int(sid),
        "section_type":        int(stype),
        "delay":               round(float(delay_us), 3),   # µs
        "mux":                 1 if stype == 1 else 0,       # RX path on readout
        "phase_ch0":           float(phase_deg),
        "frequency_ch0":       float(f_tx_mhz),              # MHz
        "phase_ch1":           0.0,
        "frequency_ch1":       float(f_rx_mhz),              # MHz
        "rstn":                int(rstn),
        "x_gradient":          int(gx),
        "y_gradient":          int(gy),
        "z_gradient":          int(gz),
        "x_ref":               int(gxr),
        "y_ref":               int(gyr),
        "z_ref":               int(gzr),
        "gradient_sweep_flag": int(sweep_flag),
        "x_sweep_offset":      int(gx_off),
        "y_sweep_offset":      int(gy_off),
        "z_sweep_offset":      int(gz_off),
    }


def _load_sequence_template(filename: str) -> dict:
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'Sequences', filename)
    with open(path, 'r') as f:
        return json.load(f)


def _first_section(seq: dict, *, name: str | None = None,
                   section_type: int | None = None) -> dict:
    sections = seq.get('SectionConfig', {})
    if name is not None and name in sections:
        return sections[name]
    if section_type is not None:
        ordered = sorted(
            sections.values(),
            key=lambda sec: int(sec.get('section_id', 0)),
        )
        for sec in ordered:
            if int(sec.get('section_type', -1)) == int(section_type):
                return sec
    target = name if name is not None else f'type {section_type}'
    raise KeyError(f"FID template is missing section {target!r}.")


def _set_all_frequencies(seq: dict, f_tx_mhz: float, f_rx_mhz: float) -> None:
    for sec in seq.get('SectionConfig', {}).values():
        sec['frequency_ch0'] = float(f_tx_mhz)
        sec['frequency_ch1'] = float(f_rx_mhz)


def build_fid_json(p90_us, t_dead_us, t_acq_us, f_tx_mhz, f_rx_mhz=0.0,
                   experiment_repeat=1):
    """Build Quick Config FID by patching the known-good Sequences/FID.txt."""
    seq = _load_sequence_template('FID.txt')
    f_rx = f_rx_mhz if f_rx_mhz > 0 else f_tx_mhz
    _set_all_frequencies(seq, f_tx_mhz, f_rx)

    tx = _first_section(seq, name='TX', section_type=0)
    rx = _first_section(seq, name='RX', section_type=1)
    dead = _first_section(seq, name='PostTXPreTX')
    tx['delay'] = round(float(p90_us), 3)
    dead['delay'] = round(float(t_dead_us), 3)
    rx['delay'] = round(float(t_acq_us), 3)

    exp = seq.setdefault('ExpConfig', {})
    exp['nr_sections'] = len(seq.get('SectionConfig', {}))
    exp['cycle_repetition_number'] = 1
    exp['experiment_repetition_number'] = max(1, int(experiment_repeat))
    return seq


def build_cpmg_json(nr_echos, te_us, p90_us, p180_us, t_acq_us,
                    f_tx_mhz, f_rx_mhz=0.0, phase_deg=0.0, experiment_repeat=1):
    """CPMG / multi-spin-echo train (nr_echos = 1 → single spin-echo)."""
    f_rx = f_rx_mhz if f_rx_mhz > 0 else f_tx_mhz
    half_te_pre = max(1.0, (te_us - p90_us / 2 - p180_us / 2) / 2)
    half_te_post = max(1.0, (te_us - p180_us / 2 - t_acq_us / 2) / 2)
    echo_spacing = max(1.0, te_us / 2 - t_acq_us / 2 - p180_us / 2)

    sections = {
        "Section_0_PreDelay":    _section(0, 2, 1000,         f_tx_mhz, f_rx, rstn=0),
        "Section_1_P90":         _section(1, 0, p90_us,       f_tx_mhz, f_rx, phase_deg=phase_deg, rstn=1),
        "Section_2_HalfTE_pre":  _section(2, 2, half_te_pre,  f_tx_mhz, f_rx, rstn=1),
        "Section_3_P180":        _section(3, 0, p180_us,      f_tx_mhz, f_rx, phase_deg=phase_deg + 90.0, rstn=1),
        "Section_4_HalfTE_post": _section(4, 2, half_te_post, f_tx_mhz, f_rx, rstn=1),
        "Section_5_RX":          _section(5, 1, t_acq_us,     f_tx_mhz, f_rx, rstn=1),
        "Section_6_EchoSpacing": _section(6, 2, echo_spacing, f_tx_mhz, f_rx, rstn=1),
        "Section_7_EndDelay":    _section(7, 2, 2000,         f_tx_mhz, f_rx, rstn=1),
    }
    return {
        "ExpConfig": {
            "nr_sections": 8,
            "start_repeat_pointer": 3,
            "end_repeat_pointer": 6,
            "cycle_repetition_number": int(nr_echos),
            "experiment_repetition_number": int(experiment_repeat),
            "gradient_x_sweep_step": 0,
            "gradient_y_sweep_step": 0,
            "gradient_z_sweep_step": 0,
        },
        "SectionConfig": sections,
    }


# ─────────────────────────────────────────────────────────────────────────────────
# Timeline visualiser  (REAL schema: section_type + delay in µs)
# ─────────────────────────────────────────────────────────────────────────────────
def build_timeline_figure(seq_dict: dict) -> go.FigureWidget:
    fig = go.FigureWidget(layout=go.Layout(
        height=300, margin=dict(t=30, b=50, l=80, r=20),
        xaxis_title='Time (µs)',
        yaxis=dict(tickvals=[0, 1, 2], ticktext=['RX', 'Delay/Grad', 'TX'],
                   range=[-0.6, 2.6]),
        showlegend=False, plot_bgcolor='white', paper_bgcolor='white',
        font=dict(color='#333333', size=11)))

    exp_cfg = seq_dict.get('ExpConfig', {})
    sec_cfg = seq_dict.get('SectionConfig', {})
    items = list(sec_cfg.items())

    start_ptr = exp_cfg.get('start_repeat_pointer', -1)
    end_ptr = exp_cfg.get('end_repeat_pointer', -1)

    t = 0.0
    starts = []
    for key, sec in items:
        dur = float(sec.get('delay', 0))
        stype = int(sec.get('section_type', 2))
        lane = _TIMELINE_LANE.get(stype, 1)
        colour = _TIMELINE_COLOURS.get(stype, '#64748b')
        x0, x1 = t, t + dur
        starts.append((int(sec.get('section_id', -1)), x0, x1))
        t = x1

        fig.add_trace(go.Scatter(
            x=[x0, x0, x1, x1, x0],
            y=[lane - 0.4, lane + 0.4, lane + 0.4, lane - 0.4, lane - 0.4],
            fill='toself', fillcolor=_rgba(colour, 0.4),
            line=dict(color=colour, width=1.5), mode='lines', name=key,
            hovertemplate=(f'<b>{key}</b><br>Start: %{{x:.1f}} µs<br>'
                           f'Duration: {dur:.1f} µs<br>'
                           f'Type: {_TYPE_LABEL.get(stype, "?")}<extra></extra>')))
        fig.add_annotation(x=(x0 + x1) / 2, y=lane, text=key.replace('Section_', 'S')[:10],
                           showarrow=False, font=dict(size=9, color='#1e2228'),
                           bgcolor='rgba(255,255,255,0.6)')

    # Repeat bracket — match start/end pointers against section_id, fall back to index.
    def _edge(ptr, which):
        for sid, x0, x1 in starts:
            if sid == ptr:
                return x0 if which == 'start' else x1
        if 0 <= ptr < len(starts):
            return starts[ptr][1] if which == 'start' else starts[ptr][2]
        return None

    xs = _edge(start_ptr, 'start')
    xe = _edge(end_ptr, 'end')
    if xs is not None and xe is not None and xe > xs:
        fig.add_vrect(x0=xs, x1=xe, fillcolor='rgba(250,204,21,0.06)',
                      line=dict(color='#facc15', width=1.5, dash='dot'),
                      annotation_text='repeat', annotation_position='top left',
                      annotation_font=dict(color='#b45309', size=10))
    return fig


# ─────────────────────────────────────────────────────────────────────────────────
# SequencePanel
# ─────────────────────────────────────────────────────────────────────────────────
class SequencePanel:
    """Quick-config + JSON editor + timeline + dynamic file browser."""

    def __init__(self, seq_dir_cse=None, seq_dir_tse=None,
                 apply_sequence_callback=None):
        here = os.path.dirname(os.path.abspath(__file__))
        self.base_dir = here
        self.seq_dir_cse = seq_dir_cse or os.path.join(here, 'CSE_sequence')
        self.seq_dir_tse = seq_dir_tse or os.path.join(here, 'TSE_sequence')
        self._apply_sequence_callback = apply_sequence_callback
        self._current_file_path = None
        self._current_json = {}
        self._build()

    # ── public API ────────────────────────────────────────────────────────────
    @property
    def widget(self) -> widgets.Tab:
        return self._tab

    def get_current_sequence(self) -> dict:
        return self._current_json

    def get_current_sequence_source(self) -> str:
        if self._current_file_path:
            return os.path.basename(self._current_file_path)
        if self._current_json:
            return 'JSON editor / quick config'
        return 'none'

    def _apply_current_sequence_to_fpga(self) -> str:
        if self._apply_sequence_callback is None:
            return 'GUI updated.'
        return self._apply_sequence_callback(self._current_json)

    def _sequence_dir_options(self):
        """Return selectable sequence subfolders under src_v3_6."""
        options = []
        preferred = ['Sequences', 'CSE_sequence', 'TSE_sequence']
        seen = set()

        def _has_sequence_files(path):
            try:
                return any(name.endswith('.txt') or name.endswith('.json')
                           for name in os.listdir(path))
            except OSError:
                return False

        for name in preferred:
            path = os.path.join(self.base_dir, name)
            if os.path.isdir(path) and _has_sequence_files(path):
                options.append((name, path))
                seen.add(path)

        for name in sorted(os.listdir(self.base_dir)):
            path = os.path.join(self.base_dir, name)
            if path in seen:
                continue
            if name.startswith('.') or name.startswith('_') or name == '__pycache__':
                continue
            if os.path.isdir(path) and _has_sequence_files(path):
                options.append((name, path))
        return options or [('src_v3_6', self.base_dir)]

    # ── build ─────────────────────────────────────────────────────────────────
    def _build(self):
        self._tab = widgets.Tab(layout=widgets.Layout(width='100%'))
        self._tab.children = [
            self._build_quick_config(),
            self._build_json_editor(),
            self._build_timeline(),
            self._build_file_browser(),
        ]
        for i, title in enumerate(['⚡ Quick Config', '📝 JSON Editor',
                                   '📊 Timeline', '📂 Sequence Files']):
            self._tab.set_title(i, title)

    # ── Tab 0 – Quick Config ───────────────────────────────────────────────────
    def _build_quick_config(self) -> widgets.Widget:
        self.seq_type = widgets.ToggleButtons(
            options=['FID', 'Spin Echo', 'CPMG'], value='CPMG',
            description='Sequence:',
            style={'description_width': '90px', 'button_width': '120px'})

        lyt = widgets.Layout(width='230px')
        sty = {'description_width': '120px'}
        self.qc_f_tx = widgets.FloatText(value=7.5, description='f_TX (MHz):', layout=lyt, style=sty)
        self.qc_f_rx = widgets.FloatText(value=7.5, description='f_RX (MHz):', layout=lyt, style=sty)
        self.qc_p90 = widgets.FloatText(value=5.0,    description='P90 (µs):',  layout=lyt, style=sty)
        self.qc_exp_rep = widgets.IntText(value=1,    description='HW repeats:', layout=lyt, style=sty)

        # CPMG / Spin-Echo params
        self.qc_te = widgets.FloatText(value=1000.0, description='TE (µs):', layout=lyt, style=sty)
        self.qc_p180 = widgets.FloatText(value=10.0, description='P180 (µs):', layout=lyt, style=sty)
        self.qc_nr_echos = widgets.IntText(value=16, description='Nr Echos:', layout=lyt, style=sty)
        self.qc_t_acq = widgets.FloatText(value=200.0, description='T_acq (µs):', layout=lyt, style=sty)
        self.qc_phase = widgets.FloatText(value=0.0, description='Phase (°):', layout=lyt, style=sty)

        # FID params
        self.qc_t_dead = widgets.FloatText(value=50.0, description='T_dead (µs):', layout=lyt, style=sty)
        self.qc_t_acq_fid = widgets.FloatText(value=500.0, description='T_acq (µs):', layout=lyt, style=sty)

        self.seq_type.observe(self._on_seq_type_change, names='value')

        self.qc_generate = widgets.Button(description='Generate Sequence',
                                          button_style='primary',
                                          layout=widgets.Layout(width='200px', height='34px'))
        self.qc_generate.on_click(self._on_generate)
        self.qc_status = widgets.HTML('<span style="color:#8b949e">No sequence generated yet.</span>')

        self._shared_col = widgets.VBox([self.qc_f_tx, self.qc_f_rx, self.qc_p90, self.qc_exp_rep])
        self._cpmg_box = widgets.VBox(
            [self.qc_te, self.qc_p180, self.qc_nr_echos, self.qc_t_acq, self.qc_phase],
            layout=widgets.Layout(border='1px solid #30363d', padding='4px', border_radius='6px'))
        self._fid_box = widgets.VBox(
            [self.qc_t_dead, self.qc_t_acq_fid],
            layout=widgets.Layout(border='1px solid #30363d', padding='4px', border_radius='6px'))
        self._params_row = widgets.HBox([self._shared_col, self._cpmg_box])
        self._on_seq_type_change({'new': self.seq_type.value})

        return widgets.VBox([
            self.seq_type, self._params_row,
            widgets.HBox([self.qc_generate, self.qc_status]),
        ], layout=widgets.Layout(padding='8px'))

    def _on_seq_type_change(self, change):
        stype = change['new']
        if stype == 'FID':
            self._params_row.children = [self._shared_col, self._fid_box]
            self.qc_nr_echos.disabled = True
        else:
            self._params_row.children = [self._shared_col, self._cpmg_box]
            self.qc_nr_echos.disabled = (stype == 'Spin Echo')

    def _on_generate(self, _):
        self.qc_generate.disabled = True
        self.qc_status.value = '<span style="color:#d29922">now loading...</span>'
        try:
            stype = self.seq_type.value
            if stype == 'FID':
                seq = build_fid_json(
                    p90_us=self.qc_p90.value, t_dead_us=self.qc_t_dead.value,
                    t_acq_us=self.qc_t_acq_fid.value, f_tx_mhz=self.qc_f_tx.value,
                    f_rx_mhz=self.qc_f_rx.value, experiment_repeat=self.qc_exp_rep.value)
            else:
                nr_echos = 1 if stype == 'Spin Echo' else self.qc_nr_echos.value
                seq = build_cpmg_json(
                    nr_echos=nr_echos, te_us=self.qc_te.value, p90_us=self.qc_p90.value,
                    p180_us=self.qc_p180.value, t_acq_us=self.qc_t_acq.value,
                    f_tx_mhz=self.qc_f_tx.value, f_rx_mhz=self.qc_f_rx.value,
                    phase_deg=self.qc_phase.value, experiment_repeat=self.qc_exp_rep.value)

            self._current_json = seq
            self._current_file_path = None
            self.json_editor.value = json.dumps(seq, indent=2)
            self._refresh_timeline()
            apply_msg = self._apply_current_sequence_to_fpga()
            self.qc_status.value = (
                f'<span style="color:#3fb950">✔ {stype} sequence generated: '
                f'{seq["ExpConfig"]["nr_sections"]} sections. {apply_msg}</span>')
        except Exception as e:
            self.qc_status.value = f'<span style="color:#f85149">Error: {e}</span>'
            raise
        finally:
            self.qc_generate.disabled = False

    # ── Tab 1 – JSON Editor ────────────────────────────────────────────────────
    def _build_json_editor(self) -> widgets.Widget:
        self.json_editor = widgets.Textarea(
            placeholder='Paste or type a sequence JSON here…',
            layout=widgets.Layout(width='100%', height='360px'))
        self.json_editor.add_class('nmr-json')

        self.json_validate = widgets.Button(description='Validate & Apply',
                                            button_style='primary',
                                            layout=widgets.Layout(width='160px', height='32px'))
        self.json_reload_btn = widgets.Button(description='Reload File',
                                              button_style='',
                                              layout=widgets.Layout(width='120px', height='32px'))
        self.json_save_btn = widgets.Button(description='Save to file…', button_style='',
                                            layout=widgets.Layout(width='140px', height='32px'))
        dir_options = self._sequence_dir_options()
        self.json_save_dir = widgets.Dropdown(
            options=dir_options,
            value=dir_options[0][1], description='Dir:',
            layout=widgets.Layout(width='260px'), style={'description_width': '35px'})
        self.json_save_name = widgets.Text(value='my_sequence', description='Name:',
                                           layout=widgets.Layout(width='220px'),
                                           style={'description_width': '45px'})
        self.json_status = widgets.HTML('<span style="color:#8b949e">No sequence loaded.</span>')

        self.json_validate.on_click(self._on_json_validate)
        self.json_reload_btn.on_click(self._on_json_reload)
        self.json_save_btn.on_click(self._on_json_save)

        return widgets.VBox([
            self.json_editor,
            widgets.HBox([self.json_validate, self.json_reload_btn, self.json_save_dir,
                          self.json_save_name, self.json_save_btn]),
            self.json_status,
        ], layout=widgets.Layout(padding='8px'))

    def _validate_dict(self, seq: dict):
        if 'ExpConfig' not in seq or 'SectionConfig' not in seq:
            raise ValueError("Missing 'ExpConfig' or 'SectionConfig' keys.")
        if not seq['SectionConfig']:
            raise ValueError("SectionConfig is empty.")
        for key, sec in seq['SectionConfig'].items():
            if 'section_type' not in sec or 'delay' not in sec:
                raise ValueError(f"Section '{key}' missing 'section_type' or 'delay'.")

    def _on_json_validate(self, _):
        self.json_validate.disabled = True
        self.json_status.value = '<span style="color:#d29922">now loading...</span>'
        try:
            seq = json.loads(self.json_editor.value)
            self._validate_dict(seq)
            self._current_json = seq
            self._refresh_timeline()
            apply_msg = self._apply_current_sequence_to_fpga()
            nr = seq['ExpConfig'].get('nr_sections', len(seq['SectionConfig']))
            self.json_status.value = (
                f'<span style="color:#3fb950">✔ Valid — {nr} sections. {apply_msg}</span>')
        except Exception as e:
            self.json_status.value = f'<span style="color:#f85149">JSON error: {e}</span>'
            raise
        finally:
            self.json_validate.disabled = False

    def _on_json_save(self, _):
        try:
            if not self._current_json:
                self.json_status.value = '<span style="color:#d29922">Validate a sequence first.</span>'
                return
            os.makedirs(self.json_save_dir.value, exist_ok=True)
            filename = self.json_save_name.value
            if not filename.endswith('.txt') and not filename.endswith('.json'):
                filename += '.txt'
            path = os.path.join(self.json_save_dir.value, filename)
            with open(path, 'w') as f:
                json.dump(self._current_json, f, indent=2)
            self._current_file_path = path
            self.json_status.value = f'<span style="color:#3fb950">✔ Saved to {path}</span>'
            self._refresh_file_list()
        except Exception as e:
            self.json_status.value = f'<span style="color:#f85149">Save error: {e}</span>'
            raise

    def _on_json_reload(self, _):
        if not self._current_file_path:
            self.json_status.value = '<span style="color:#d29922">No loaded file to reload.</span>'
            return
        self.json_reload_btn.disabled = True
        self.json_status.value = '<span style="color:#d29922">now loading...</span>'
        try:
            self._load_sequence_file(self._current_file_path)
            self.json_status.value = (
                f'<span style="color:#3fb950">✔ Reloaded {os.path.basename(self._current_file_path)}.</span>')
        except Exception as e:
            self.json_status.value = f'<span style="color:#f85149">Reload error: {e}</span>'
            raise
        finally:
            self.json_reload_btn.disabled = False

    # ── Tab 2 – Timeline ─────────────────────────────────────────────────────
    def _build_timeline(self) -> widgets.Widget:
        self._timeline_out = widgets.Output()
        self.timeline_refresh = widgets.Button(description='↻ Refresh Timeline', button_style='',
                                               layout=widgets.Layout(width='160px', height='30px'))
        self.timeline_info = widgets.HTML(
            '<span style="color:#8b949e">Generate or load a sequence to see the timeline.</span>')
        self.timeline_refresh.on_click(lambda _: self._refresh_timeline())

        return widgets.VBox([
            widgets.HBox([self.timeline_refresh, self.timeline_info]),
            self._timeline_out,
        ], layout=widgets.Layout(padding='8px'))

    def _refresh_timeline(self):
        if not self._current_json:
            self.timeline_info.value = '<span style="color:#d29922">No sequence loaded.</span>'
            return
        try:
            fig = build_timeline_figure(self._current_json)
            with self._timeline_out:
                self._timeline_out.clear_output(wait=True)
                from IPython.display import display
                display(fig)
            nr = len(self._current_json.get('SectionConfig', {}))
            self.timeline_info.value = f'<span style="color:#3fb950">✔ {nr} sections shown.</span>'
        except Exception as e:
            self.timeline_info.value = f'<span style="color:#f85149">Timeline error: {e}</span>'
            raise

    # ── Tab 3 – File Browser ───────────────────────────────────────────────────
    def _build_file_browser(self) -> widgets.Widget:
        dir_options = self._sequence_dir_options()
        self.fb_dir = widgets.Dropdown(
            options=dir_options,
            value=dir_options[0][1], description='Directory:',
            layout=widgets.Layout(width='340px'), style={'description_width': '80px'})
        self.fb_file = widgets.Dropdown(description='File:',
                                        layout=widgets.Layout(width='480px'),
                                        style={'description_width': '35px'})
        self.fb_load = widgets.Button(description='Load Sequence', button_style='primary',
                                      layout=widgets.Layout(width='150px', height='32px'))
        self.fb_refresh = widgets.Button(description='↻', button_style='',
                                         layout=widgets.Layout(width='40px', height='32px'))
        self.fb_status = widgets.HTML('<span style="color:#8b949e">Select a file and press Load.</span>')

        self.fb_dir.observe(self._on_fb_dir_change, names='value')
        self.fb_load.on_click(self._on_fb_load)
        self.fb_refresh.on_click(lambda _: self._refresh_file_list())
        self._refresh_file_list()

        return widgets.VBox([
            widgets.HBox([self.fb_dir, self.fb_file, self.fb_refresh]),
            widgets.HBox([self.fb_load, self.fb_status]),
        ], layout=widgets.Layout(padding='8px'))

    def _refresh_file_list(self):
        dir_options = self._sequence_dir_options()
        if hasattr(self, 'json_save_dir'):
            save_current = self.json_save_dir.value
            self.json_save_dir.options = dir_options
            if save_current in [path for _, path in dir_options]:
                self.json_save_dir.value = save_current
            else:
                self.json_save_dir.value = dir_options[0][1]
        current = self.fb_dir.value
        self.fb_dir.options = dir_options
        if current in [path for _, path in dir_options]:
            self.fb_dir.value = current
        else:
            self.fb_dir.value = dir_options[0][1]
        dirpath = self.fb_dir.value
        try:
            files = sorted(f for f in os.listdir(dirpath)
                           if f.endswith('.json') or f.endswith('.txt'))
            self.fb_file.options = files if files else ['(no files found)']
        except Exception:
            self.fb_file.options = ['(directory not found)']
            raise

    def _on_fb_dir_change(self, _):
        self._refresh_file_list()

    def _on_fb_load(self, _):
        fname = self.fb_file.value
        if not fname or fname.startswith('('):
            self.fb_status.value = '<span style="color:#d29922">No file selected.</span>'
            return
        fpath = os.path.join(self.fb_dir.value, fname)
        self.fb_load.disabled = True
        self.fb_status.value = '<span style="color:#d29922">now loading...</span>'
        try:
            self._load_sequence_file(fpath)
        finally:
            self.fb_load.disabled = False

    def _load_sequence_file(self, fpath: str):
        fname = os.path.basename(fpath)
        try:
            with open(fpath) as f:
                seq = json.load(f)            # CSE/TSE .txt files are JSON content
            self._validate_dict(seq)
            self._current_json = seq
            self._current_file_path = fpath
            self.json_editor.value = json.dumps(seq, indent=2)
            self._refresh_timeline()
            apply_msg = self._apply_current_sequence_to_fpga()
            nr = seq['ExpConfig'].get('nr_sections', len(seq['SectionConfig']))
            self.fb_status.value = (
                f'<span style="color:#3fb950">✔ Loaded "{fname}" — {nr} sections. {apply_msg}</span>')
        except json.JSONDecodeError:
            with open(fpath) as f:
                self.json_editor.value = f.read()
            self._current_file_path = fpath
            self.fb_status.value = (
                '<span style="color:#d29922">Loaded raw text into JSON editor. '
                'Validate before use.</span>')
        except Exception as e:
            self.fb_status.value = f'<span style="color:#f85149">Load error: {e}</span>'
            raise
