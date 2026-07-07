# Pulse Sequence File Guide For LLM-Assisted Editing

This folder contains pulse sequence files for the Unified NMR / MRI v3.6 GUI. Give this README plus one working template sequence to an LLM when you want it to create or modify a valid sequence for this system.

Sequence files are JSON documents stored as `.txt` or `.json`. The GUI expects the exact schema below.

## Top-Level Structure

Every sequence file must contain exactly these top-level objects:

```json
{
  "ExpConfig": {},
  "SectionConfig": {}
}
```

Do not add comments, trailing commas, or non-JSON syntax.

## ExpConfig Fields

`ExpConfig` must include:

- `nr_sections`: total number of sections in `SectionConfig`.
- `start_repeat_pointer`: first section id in the hardware repeat window.
- `end_repeat_pointer`: last section id in the hardware repeat window.
- `cycle_repetition_number`: number of times to repeat the repeat window.
- `experiment_repetition_number`: number of hardware experiment repetitions.
- `gradient_x_sweep_step`: X gradient sweep step.
- `gradient_y_sweep_step`: Y gradient sweep step.
- `gradient_z_sweep_step`: Z gradient sweep step.

Repeat pointers are section ids and are inclusive. The hardware executes sections before the repeat window once, repeats the window `cycle_repetition_number` times, then executes sections after the repeat window once.

## SectionConfig Fields

`SectionConfig` is an object whose values are section objects. Section names can be descriptive, but every section object must include all fields below:

- `section_id`: integer id. Use contiguous ids from `0` to `nr_sections - 1`.
- `section_type`: `0` for TX, `1` for RX, `2` for delay.
- `delay`: section duration in microseconds.
- `mux`: use `1` for RX sections, `0` for TX and delay sections.
- `phase_ch0`: TX phase in degrees.
- `frequency_ch0`: TX frequency in MHz.
- `phase_ch1`: RX phase in degrees, normally `0.0`.
- `frequency_ch1`: RX frequency in MHz.
- `rstn`: reset control, normally keep the template value unless the user explicitly asks.
- `x_gradient`: X gradient DAC value.
- `y_gradient`: Y gradient DAC value.
- `z_gradient`: Z gradient DAC value.
- `x_ref`: X gradient reference DAC value.
- `y_ref`: Y gradient reference DAC value.
- `z_ref`: Z gradient reference DAC value.
- `gradient_sweep_flag`: gradient sweep enable flag.
- `x_sweep_offset`: X sweep offset.
- `y_sweep_offset`: Y sweep offset.
- `z_sweep_offset`: Z sweep offset.

Use integer values for gradient and reference fields. Use numeric values, not strings.

## Timing And Units

- Delays are in microseconds.
- Frequencies are in MHz.
- Phases are in degrees.
- Gradient and reference values are integer DAC codes.

Do not silently shrink long delays unless the user specifically asks for a demo-shortened sequence. For realistic pulse programs, preserve the requested timing.

## Good Editing Rules For An LLM

When modifying a template sequence:

- Preserve all existing keys unless the user specifically asks for a structural change.
- Change only the sections required by the requested experiment.
- Keep `section_id` values unique and contiguous.
- Update `nr_sections` whenever sections are added or removed.
- Keep repeat pointers valid after adding or removing sections.
- Use TX sections for RF pulses, RX sections for acquisition windows, and delay sections for waiting or gradient-only periods.
- Keep `mux=1` only during RX acquisition windows.
- Keep the same gradient reference style as the template unless the user asks otherwise.
- Prefer explicit sections when readability matters. Use hardware repeats only when the repeated block is truly identical.
- Output a complete JSON sequence, not a patch or explanation-only answer.

## Prompt Template

You can paste this prompt into an LLM:

```text
Use the attached Unified NMR / MRI sequence README and the attached working template sequence. Create a complete valid sequence JSON for the following experiment: <describe experiment>. Preserve the system schema exactly. Use microseconds for delay, MHz for frequency, degrees for phase, and integer DAC values for gradients. Keep section ids contiguous, update nr_sections, and keep repeat pointers valid. Do not omit fields and do not add non-JSON comments.
```

## Validation Checklist

Before loading a new sequence in the GUI, check:

- The file parses as JSON.
- `ExpConfig` and `SectionConfig` both exist.
- `nr_sections` equals the number of section objects.
- Section ids run from `0` to `nr_sections - 1` with no gaps.
- Repeat pointers refer to existing section ids.
- Every section has every required field.
- TX/RX frequencies, pulse widths, delays, and gradient values are safe for the hardware setup.
