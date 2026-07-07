# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6 - MRI GUI plus reusable advanced-experiment APIs.
# --
# --   Built on the proven fpga_mri.py JSON-sequence stack and mri_overlay.py
# --   hardware layer.  Replicates the legacy modular GUI feature set and adds
# --   first-class support for user-defined JSON pulse sequences.
# --
# --   Launch (single notebook cell):
# --       import src_v3_6.app as gui
# --       display(gui.GUI_total)
# ----------------------------------------------------------------------------------

__all__ = ["app", "core_api", "experiment_control"]
__version__ = "3.6.0"
