# ----------------------------------------------------------------------------------
# Authors: Yitian Chen, Zhibin Zhao, Yichao Peng
# Affiliation: Institut für Intelligente Sensorik und Theoretische Elektrotechnik (IIS), University of Stuttgart, Germany
# Release date: 2026.07.01
# Software release: Unified NMR / MRI Control Software v3.6
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# -- src_v3_6.data_io
# --   Self-contained data save / load helpers (no hardware dependency).
# --   ch0 / ch1 arrays are already in mV (converted during acquire()).
# ----------------------------------------------------------------------------------

import os
import numpy as np

DEFAULT_OUTPUT_DIR = "output"


def save_data(ch0, ch1, filename="Untitled", fmt=0, clock_div=100,
              out_dir=DEFAULT_OUTPUT_DIR):
    """Save the two acquired channels (mV) plus a time axis to disk.

    Parameters
    ----------
    ch0, ch1  : array-like   – channel data in mV
    filename  : str          – base name (no extension)
    fmt       : int          – 0 = .csv, 1 = .txt
    clock_div : int          – clock divider (dt = clock_div / 100 µs per sample)
    out_dir   : str          – output directory (created if missing)

    Returns
    -------
    str : the full path of the written file.
    """
    ch0 = np.asarray(ch0, dtype=float)
    ch1 = np.asarray(ch1, dtype=float) if ch1 is not None else np.zeros_like(ch0)
    n = max(len(ch0), len(ch1))
    dt_us = clock_div / 100.0
    time_us = np.arange(n) * dt_us

    # Pad shorter channel so columns line up.
    if len(ch0) < n:
        ch0 = np.pad(ch0, (0, n - len(ch0)))
    if len(ch1) < n:
        ch1 = np.pad(ch1, (0, n - len(ch1)))

    os.makedirs(out_dir, exist_ok=True)
    if not filename:
        filename = "Untitled"
    ext = ".csv" if fmt == 0 else ".txt"
    path = os.path.join(out_dir, filename + ext)

    header = "time(us),channel0(mV),channel1(mV)"
    data = np.column_stack([time_us, ch0, ch1])
    delim = "," if fmt == 0 else "\t"
    np.savetxt(path, data, delimiter=delim,
               header=header.replace(",", delim), comments="")
    return path
