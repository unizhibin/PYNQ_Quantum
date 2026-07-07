# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.gui_styles
# --   CSS / theme constants and small HTML helpers.  The CSS is injected once
# --   into the notebook output via an ipywidgets.HTML widget.
# ----------------------------------------------------------------------------------

# ── Colour palette ──────────────────────────────────────────────────────────────
COLOUR = {
    "bg_card":        "#1e2228",
    "bg_panel":       "#262b33",
    "bg_header":      "#d8ecff",
    "accent_blue":    "#58a6ff",
    "accent_green":   "#3fb950",
    "accent_amber":   "#d29922",
    "accent_red":     "#f85149",
    "text_primary":   "#e6edf3",
    "text_secondary": "#8b949e",
    "border":         "#30363d",
    # Section-type colours used in the timeline
    "tx":             "#f87171",
    "rx":             "#34d399",
    "delay":          "#64748b",
    "repeat_marker":  "#facc15",
}

CSS = """
<style>
.nmr-card {
    background:#1e2228; border:1px solid #30363d; border-radius:8px;
    padding:10px 14px; margin:4px 6px; color:#e6edf3;
    font-family:'Segoe UI', sans-serif;
}
.badge-tx    { background:#f87171; color:#1e2228; padding:1px 6px; border-radius:4px; font-size:11px; font-weight:600; }
.badge-rx    { background:#34d399; color:#1e2228; padding:1px 6px; border-radius:4px; font-size:11px; font-weight:600; }
.badge-delay { background:#64748b; color:#e6edf3; padding:1px 6px; border-radius:4px; font-size:11px; font-weight:600; }
.status-ok   { color:#3fb950; font-weight:700; }
.status-err  { color:#f85149; font-weight:700; }
.status-warn { color:#d29922; font-weight:700; }
.nmr-header {
    background:#d8ecff; border-bottom:2px solid #58a6ff;
    border-radius:8px 8px 0 0;
}
.nmr-title {
    color:#0b4f8a; font-size:18px; font-weight:700;
    font-family:'Segoe UI', sans-serif; letter-spacing:0; margin-left:4px;
}
.nmr-subtitle {
    color:#315f7f; font-size:12px; margin-left:16px;
    font-family:'Segoe UI', sans-serif;
}
.nmr-authors {
    color:#6e7681; font-size:10px; text-align:right;
    font-family:'Segoe UI', sans-serif; padding:2px 8px 0 0;
}
.nmr-json textarea {
    font-family:'Consolas','Courier New', monospace !important;
    font-size:12px !important; background:#0d1117 !important; color:#e6edf3 !important;
    border:1px solid #30363d !important; border-radius:4px !important;
}
.nmr-progress .progress-bar { background-color:#3fb950; }
</style>
"""


def section_badge(section_type: int) -> str:
    """Return an HTML badge for a section-type integer (0=TX, 1=RX, 2=Delay)."""
    labels = {0: ("TX", "badge-tx"), 1: ("RX", "badge-rx"), 2: ("Delay", "badge-delay")}
    label, cls = labels.get(section_type, ("?", "badge-delay"))
    return f'<span class="{cls}">{label}</span>'


def status_html(msg: str, level: str = "ok") -> str:
    """Return a coloured HTML status line. level: 'ok' | 'err' | 'warn'."""
    return f'<span class="status-{level}">{msg}</span>'


def card_html(title: str, body: str) -> str:
    return f'<div class="nmr-card"><b style="color:#58a6ff">{title}</b><br/>{body}</div>'


def inject_css_widget():
    """Return an ipywidgets.HTML widget that injects the CSS into the notebook."""
    import ipywidgets as widgets
    return widgets.HTML(value=CSS)
