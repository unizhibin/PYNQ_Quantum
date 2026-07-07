# Unified NMR / MRI Control Software v3.6

This release is the user-facing control software for the PYNQ ZCU104 based NMR / MRI platform. It provides one GUI for FPGA initialization, hardware setup, pulse sequence loading, experiment triggering, live plotting, shimming, and saving acquired data.

The Python package directory is `src_v3_6`. Use this package name for new v3.6 notebooks and scripts.

## Start The GUI

Open Jupyter on the board, then run one notebook cell:

```python
import src_v3_6.app as gui
from IPython.display import display

display(gui.GUI_total)
```

Press `Initialise FPGA` before running hardware experiments. The GUI loads the bundled bitstream, initializes the overlay drivers, and then programs the currently loaded sequence if one is already present.

## Normal Workflow

1. Initialize the FPGA.
2. Check the hardware tab settings, especially clock divider, RX samples, ADC/DAC related controls, and Auto RX Samples.
3. Load or generate a pulse sequence from the Sequence tab.
4. Inspect the timeline to confirm TX, RX, delays, repeat window, and expected section order.
5. Use the always-visible Experiment Control block to run or stop the experiment while staying in any configuration tab.
6. Check the time-domain and FFT plots.
7. Save data from the Analysis tab when the acquisition looks correct.

For long sequences, loading can take a few seconds because the pulse-generator section RAM is written over AXI-Lite. The sequence only needs to be loaded again when the sequence contents change. Re-running an experiment uses the sequence already programmed in the pulse-generator memory.

## Sequence Tab

Quick Config creates common starting sequences such as FID, Spin Echo, and CPMG. The FID quick config is based on the known-good `Sequences/FID.txt` template and patches the user-facing parameters.

JSON Editor lets you paste, validate, apply, reload, and save a full sequence JSON. Validation checks the required top-level structure before programming the GUI sequence state.

Timeline visualizes the loaded sequence as TX, RX, and delay sections. Use it as a quick sanity check before applying RF power.

Sequence Files loads existing `.txt` or `.json` sequence files from the bundled sequence folders.

The Quick Config, JSON Editor, and Sequence Files paths show `now loading...` while a sequence is being generated, validated, reloaded, or programmed.

## Experiment Control

Experiment Control is always visible near the top of the GUI. Use it to trigger scans while changing hardware, sequence, shim, or analysis settings in the tabs below.

Typical controls include averages, loop count, recovery timing, phase cycling options, run, and stop. Keep Python-level recovery timing enabled when you want software spacing between repeated scans. Use hardware sequence timing when the delay is already part of the pulse sequence.

## Auto RX Samples

When Auto RX Samples is enabled, the GUI calculates RX-driven sampling from the loaded sequence and the current clock divider. This helps keep DMA capture length consistent with RX windows in the pulse sequence.

If you manually override sample settings, confirm the plotted data still contains the full RX window you expect.

## Safety And Sanity Checks

Start new hardware setups with a simple FID and low-risk settings.

Before running a new sequence, verify:

- TX and RX frequencies are appropriate for the current mixer and probe setup.
- RF pulse widths and amplitudes are safe for the sample and hardware.
- Gradient values and references are expected.
- Long repeats or recovery delays are intentional.
- The oscilloscope shows the expected TX/RX timing before increasing experiment complexity.

## Advanced Notebooks

The included notebooks can drive the same GUI-loaded sequence through the public API for scans, frequency searches, section patching, and scripted experiments. Use the GUI to load and verify a sequence first, then use notebook API calls when the experiment needs scripted loops or incremental section updates.

## Files To Know

- `app.py`: GUI entry point.
- `core_api.py`: reusable experiment and sequence API.
- `fpga_mri.py`: pulse-generator sequence parser and writer.
- `Sequences/`: bundled sequence templates and examples.
- `Sequences/README.md`: instructions for creating valid AI-assisted sequence files.
