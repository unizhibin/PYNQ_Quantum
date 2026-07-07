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
# --   Pure-Python shim optimisation algorithms extracted from
# --   LAUNCH_V5_Type8C_Baselin.ipynb.  No hardware calls in this module;
# --   callers supply a `feedback_function` that performs the measurement and
# --   returns (fwhm_hz, baseline_width_hz, peak_amplitude).
# --   DAC writes are done via pmod.da4_set(channel, value).
# ----------------------------------------------------------------------------------

from __future__ import annotations
import numpy as np
import time
from typing import Callable, Sequence


# ── DAC limits ───────────────────────────────────────────────────────────────────
DAC_MIN = 0
DAC_MAX = 4000

# Channel mapping: index → coil name
SHIM_CHANNEL_NAMES = {0: 'Y', 1: 'X', 2: '2XY', 3: 'X²Y²',
                      4: 'Z²', 5: 'Z', 6: 'YZ', 7: 'XZ'}


# ─────────────────────────────────────────────────────────────────────────────────
# Utility
# ─────────────────────────────────────────────────────────────────────────────────

def _clamp(val: float, lo: float = DAC_MIN, hi: float = DAC_MAX) -> int:
    return int(max(lo, min(hi, val)))


# ─────────────────────────────────────────────────────────────────────────────────
# Golden Section Search  (v4, ported from notebook)
# ─────────────────────────────────────────────────────────────────────────────────

def golden_section_search(
    feedback_function: Callable[[int, int], tuple[float, float, float]],
    channel: int,
    param_range: tuple[float, float],
    weights: list[float] = None,
    tol: float = 1.0,
    max_iter: int = 10,
    fwhm_threshold: float = 45.0,
    anchor_freq: float = 100e3,
    avg_nr: int = 1,
) -> tuple[int, float]:
    """
    Golden-section search for optimal DAC value on a single shim channel.

    Parameters
    ----------
    feedback_function : callable(channel, dac_value) → (fwhm_hz, baseline_hz, peak_amp)
    channel           : DAC channel index (0-7)
    param_range       : (low, high) search window in DAC counts
    weights           : [w_fwhm, w_baseline, w_peak] – relative importance
    tol               : convergence tolerance in DAC counts
    max_iter          : maximum number of iterations
    fwhm_threshold    : stop early if FWHM drops below this (Hz)
    anchor_freq       : reference frequency for CZT alignment (Hz)
    avg_nr            : averages per measurement
    
    Returns
    -------
    (best_dac_value, best_fwhm)
    """
    if weights is None:
        weights = [1.0, 0.01, 0.0]

    phi = (np.sqrt(5) - 1) / 2   # golden ratio ≈ 0.618

    a, b = float(param_range[0]), float(param_range[1])

    def _cost(dac_val: int) -> float:
        fwhm, baseline, peak = feedback_function(channel, _clamp(dac_val))
        # Lower cost = better: minimise FWHM + baseline; higher peak = better (negative)
        return weights[0] * fwhm + weights[1] * baseline - weights[2] * peak

    # Initial bracket
    c = b - phi * (b - a)
    d = a + phi * (b - a)
    fc, fd = _cost(c), _cost(d)

    best_dac = _clamp((c + d) / 2)
    best_fwhm = feedback_function(channel, best_dac)[0]

    for _ in range(max_iter):
        if abs(b - a) < tol:
            break
        if fc < fd:
            b, d, fd = d, c, fc
            c = b - phi * (b - a)
            fc = _cost(c)
            best_dac = _clamp(c)
        else:
            a, c, fc = c, d, fd
            d = a + phi * (b - a)
            fd = _cost(d)
            best_dac = _clamp(d)

        best_fwhm = feedback_function(channel, best_dac)[0]
        if best_fwhm < fwhm_threshold:
            break

    return best_dac, best_fwhm


# ─────────────────────────────────────────────────────────────────────────────────
# Auto-calibration orchestrator  (golden section, sequential per channel)
# ─────────────────────────────────────────────────────────────────────────────────

def auto_cali_golden(
    feedback_function: Callable[[int, int], tuple[float, float, float]],
    set_dac: Callable[[int, int], None],
    order: list[int] = None,
    param_range_magnitude: float = 500.0,
    max_iter: int = 10,
    fwhm_threshold: float = 10.0,
    anchor_freq: float = 80e3,
    avg_nr: int = 1,
    progress_callback: Callable[[int, int, float], None] = None,
) -> dict[int, int]:
    """
    Run golden-section shim optimisation sequentially over all channels.

    Parameters
    ----------
    feedback_function : callable(channel, dac_value) → (fwhm_hz, baseline_hz, peak_amp)
    set_dac           : callable(channel, value) — applies the DAC value (e.g. pmod.da4_set)
    order             : channel optimisation order (default [0,1,2,3,6,7,5,4])
    param_range_magnitude : half-range around current DAC value (counts)
    progress_callback : optional callable(channel_idx, total_channels, fwhm)
    
    Returns
    -------
    dict mapping channel → optimal DAC value
    """
    if order is None:
        order = [0, 1, 2, 3, 6, 7, 5, 4]

    best_values: dict[int, int] = {}
    total = len(order)

    for step, ch in enumerate(order):
        current = best_values.get(ch, 2000)   # default mid-scale
        lo = max(DAC_MIN, current - param_range_magnitude)
        hi = min(DAC_MAX, current + param_range_magnitude)

        # Wrap feedback to write DAC before measuring
        def _fb(channel, dac_val):
            set_dac(channel, dac_val)
            time.sleep(0.05)
            return feedback_function(channel, dac_val)

        best_val, best_fwhm = golden_section_search(
            _fb, ch, (lo, hi),
            max_iter=max_iter,
            fwhm_threshold=fwhm_threshold,
            anchor_freq=anchor_freq,
            avg_nr=avg_nr,
        )
        set_dac(ch, best_val)
        best_values[ch] = best_val

        if progress_callback:
            progress_callback(step + 1, total, best_fwhm)

        if best_fwhm < fwhm_threshold:
            break   # good enough

    return best_values


# ─────────────────────────────────────────────────────────────────────────────────
# Nelder-Mead simplex  (ported from notebook)
# ─────────────────────────────────────────────────────────────────────────────────

def nelder_mead_optimize(
    feedback_function: Callable[[list[int]], tuple[float, float, float]],
    set_dac: Callable[[int, int], None],
    channels: list[int],
    init_params: list[int] = None,
    step: float = 1000.0,
    max_iter: int = 60,
    fwhm_threshold: float = 45.0,
    anchor_freq: float = 40e3,
    avg_nr: int = 1,
    progress_callback: Callable[[int, int, float], None] = None,
) -> tuple[list[int], float]:
    """
    Nelder-Mead simplex optimisation over all shim channels simultaneously.

    Parameters
    ----------
    feedback_function : callable(dac_values: list[int]) → (fwhm_hz, baseline_hz, peak_amp)
    set_dac           : callable(channel, value) — applies DAC
    channels          : list of channel indices to optimise
    init_params       : initial DAC values (one per channel); defaults to 2000
    step              : initial simplex step size (DAC counts)
    progress_callback : optional callable(iteration, max_iter, fwhm)
    
    Returns
    -------
    (best_dac_values, best_fwhm)
    """
    n = len(channels)
    if init_params is None:
        init_params = [2000] * n

    def _cost(params: list[float]) -> float:
        clamped = [_clamp(p) for p in params]
        for ch, val in zip(channels, clamped):
            set_dac(ch, val)
        time.sleep(0.05)
        fwhm, baseline, peak = feedback_function(clamped)
        return fwhm

    # Build initial simplex
    simplex = [np.array(init_params, dtype=float)]
    for i in range(n):
        vertex = np.array(init_params, dtype=float)
        vertex[i] += step
        simplex.append(vertex)
    costs = [_cost(s.tolist()) for s in simplex]

    alpha, gamma, rho, sigma = 1.0, 2.0, 0.5, 0.5

    best_fwhm = min(costs)
    best_params = simplex[np.argmin(costs)].copy()

    for iteration in range(max_iter):
        # Sort
        order = np.argsort(costs)
        simplex = [simplex[i] for i in order]
        costs   = [costs[i]   for i in order]

        best_fwhm   = costs[0]
        best_params = simplex[0].copy()

        if progress_callback:
            progress_callback(iteration + 1, max_iter, best_fwhm)

        if best_fwhm < fwhm_threshold:
            break

        # Centroid (exclude worst)
        centroid = np.mean(simplex[:-1], axis=0)

        # Reflection
        x_r   = centroid + alpha * (centroid - simplex[-1])
        f_r   = _cost(x_r.tolist())

        if costs[0] <= f_r < costs[-2]:
            simplex[-1], costs[-1] = x_r, f_r
            continue

        if f_r < costs[0]:
            # Expansion
            x_e = centroid + gamma * (x_r - centroid)
            f_e = _cost(x_e.tolist())
            if f_e < f_r:
                simplex[-1], costs[-1] = x_e, f_e
            else:
                simplex[-1], costs[-1] = x_r, f_r
            continue

        # Contraction
        x_c = centroid + rho * (simplex[-1] - centroid)
        f_c = _cost(x_c.tolist())
        if f_c < costs[-1]:
            simplex[-1], costs[-1] = x_c, f_c
            continue

        # Shrink
        best_v = simplex[0]
        simplex = [best_v] + [best_v + sigma * (s - best_v) for s in simplex[1:]]
        costs   = [_cost(s.tolist()) for s in simplex]

    return [_clamp(p) for p in best_params], best_fwhm


# ─────────────────────────────────────────────────────────────────────────────────
# CZT-based FWHM measurement helper (adapted from LAUNCH_V5_Type8C_Baselin.ipynb)
# ─────────────────────────────────────────────────────────────────────────────────

def measure_fwhm_czt(
    time_data: np.ndarray,
    fs: float,
    anchor_freq: float = 100e3,
    wide_bw: float = 100e3,
    zoom_bw: float = 2e3,
    zoom_pts: int = 1024,
) -> tuple[float, float, float]:
    """
    Estimate FWHM via a two-stage Chirp Z-Transform.

    Returns (fwhm_hz, baseline_width_hz, peak_amplitude).
    Uses scipy.signal.zoom_fft for the zoom stage.
    """
    from scipy.signal import zoom_fft

    n = len(time_data)

    # Stage 1 – wide band FFT to locate peak
    wide_freqs = np.linspace(
        max(0, anchor_freq - wide_bw / 2),
        anchor_freq + wide_bw / 2,
        512,
    )
    spectrum_wide = np.abs(zoom_fft(time_data, [wide_freqs[0], wide_freqs[-1]], m=512, fs=fs))
    peak_idx = np.argmax(spectrum_wide)
    peak_freq = wide_freqs[peak_idx]

    # Stage 2 – zoomed CZT around peak
    f_lo = peak_freq - zoom_bw / 2
    f_hi = peak_freq + zoom_bw / 2
    spectrum = np.abs(zoom_fft(time_data, [f_lo, f_hi], m=zoom_pts, fs=fs))
    freqs = np.linspace(f_lo, f_hi, zoom_pts)

    peak_amp = np.max(spectrum)
    if peak_amp == 0:
        return 9999.0, 9999.0, 0.0

    # Half-max crossing
    norm = spectrum / peak_amp
    pk   = np.argmax(norm)
    left_idxs  = np.where(norm[:pk] <= 0.5)[0]
    right_idxs = np.where(norm[pk:] <= 0.5)[0]

    if len(left_idxs) == 0 or len(right_idxs) == 0:
        fwhm = zoom_bw
    else:
        f_left  = freqs[left_idxs[-1]]
        f_right = freqs[pk + right_idxs[0]]
        fwhm    = f_right - f_left

    # Baseline width at 10 % of peak
    left_base  = np.where(norm[:pk] <= 0.1)[0]
    right_base = np.where(norm[pk:] <= 0.1)[0]
    if len(left_base) == 0 or len(right_base) == 0:
        baseline = zoom_bw * 2
    else:
        baseline = freqs[pk + right_base[0]] - freqs[left_base[-1]]

    return float(fwhm), float(baseline), float(peak_amp)
