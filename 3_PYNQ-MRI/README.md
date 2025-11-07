## History（A dream woven from DuPont jumper wires）
![history-full](./figures/Gallery/history.jpg)
This all began in 2018, when FPGA was just a small hobby. Before I started my PhD, I’m grateful to my parents for supporting that hobby—they bought me around €3,000 worth of development boards. After I started the PhD, FPGA was still only a side tool while I focused on designing the main project: a zero-dead-time chip.

To avoid the high NI license costs, I decided to use my hobby to solve some real problems. I chose a platform that’s even more open than Red Pitaya (and, frankly, because my parents had already bought ZCU102, PYNQ-Z1boards). Later, I also want to thank Prof. Dr. Jens Anders for his support. On this platform, Honghao Gu, Yichao Peng, and Yitian Chen completed their master’s theses. Yichao and Yitian have now begun their PhD journeys. I wish them success.

## MRI Demo Images (Proof-of-Function)

These images are **engineering demos** produced with the PYNQ-MRI platform to verify end-to-end functionality (pulse generation → gradient control → acquisition → reconstruction). They are **not** intended to claim high-resolution spectroscopic performance. Use them as a visual sanity check that the system, gradients, and reconstruction pipeline are wired correctly.

> Safety note (permanent magnets): keep ferromagnetic tools and loose metal away from the magnet gap; do not let objects snap into the poles.

### Gallery
<table>
  <tr>
    <td><img src="./figures/Gallery/1.png" width="220" height="220" alt="1" /></td>
    <td><img src="./figures/Gallery/2.png" width="220" height="220" alt="2" /></td>
    <td><img src="./figures/Gallery/3.png" width="220" height="220" alt="3" /></td>
  </tr>
  <tr>
    <td><img src="./figures/Gallery/4.png" width="220" height="220" alt="4" /></td>
    <td><img src="./figures/Gallery/5.png" width="220" height="220" alt="5" /></td>
    <td><img src="./figures/Gallery/6.png" width="220" height="220" alt="6" /></td>
  </tr>
</table>

### Physical Photos (real objects & scale)

<table>
  <tr>
    <td><img src="./figures/Gallery/r4.jpg" height="220" alt="PLA 3D-printed phantom carrying raised I2S lettering: lettering phantom + 1-cent coin" /></td>
    <td><img src="./figures/Gallery/r5.jpg" height="220" alt="BMF 3D-printed Test sample: hole/star phantom + 2-cent coin" /></td>
  </tr>
  <tr>
    <td align="center"><sub>PLA 3D-printed phantom carrying raised I2S lettering — photo with 1-euro-cent (⌀ 16.25 mm) for scale</sub></td>
    <td align="center"><sub>BMF 3D-printed Test sample — photo with 2-euro-cent (⌀ 18.75 mm) for scale</sub></td>
  </tr>
</table>

### Acquisition (summary)

- Field & nucleus: low-field **¹H**; typical Larmor ≈ 15 MHz (exact values per image in the table below)
- Sequence: 2D Cartesian (spin-echo or gradient-echo as noted per image)
- Readout: standard Cartesian k-space, rectangular FOV, no partial Fourier
- Reconstruction: Hann window → optional zero-filling → 2D IFFT → magnitude → min-max normalization
- Purpose: exercise TX/RX chain, gradient linearity, and basic image formation under lab conditions

### Per-image metadata

Fill this table so users understand what each figure shows and can reproduce it.

| ID | File | Phantom / Content | Sequence | Matrix × FOV | Voxel (mm) | TE / TR (ms) | Averages | RX BW (kHz) | Notes |
|---:|------|-------------------|----------|--------------|------------|--------------|---------:|-------------:|------|
| 1 | `figures/mri_gallery/1.png` | Circular features | SE | `Nx×Ny` @ `Wx×Wy` mm | `Δx×Δy` | `TE` / `TR` | `NEX` | `BW` | e.g., slight ghosting along phase-encode |
| 2 | `figures/mri_gallery/2.png` | Rectangular plate w/ hole | GRE | … | … | … | … | … | … |
| 3 | `figures/mri_gallery/3.png` | 3×3 hole array | SE | … | … | … | … | … | checks resolution/MTF |
| 4 | `figures/mri_gallery/4.png` | Lettering (“IIS/IPS”) | GRE | … | … | … | … | … | orientation A |
| 5 | `figures/mri_gallery/5.png` | Dots + letters | SE | … | … | … | … | … | … |
| 6 | `figures/mri_gallery/6.png` | Lettering (“IIS/IPS”) | GRE | … | … | … | … | … | orientation B |

### File naming & sidecar metadata (recommended)

- **Filename pattern** (example):  
  `2025-11-03_phantom-IIS_seq-GRE_mat-128x128_fov-40x40mm_TE-6ms_TR-200ms_avg-4_bw-100kHz.png`
- Optional **JSON sidecar** for each image:
  ```json
  {
    "nucleus": "1H",
    "B0_T": 0.359,
    "larmor_Hz": 15280000,
    "sequence": "GRE",
    "matrix": [128, 128],
    "fov_mm": [40, 40],
    "voxel_mm": [0.3125, 0.3125],
    "TE_ms": 6,
    "TR_ms": 200,
    "averages": 4,
    "rx_bandwidth_kHz": 100,
    "window": "Hann",
    "zerofill": [256, 256],
    "recon_commit": "<git-short-sha>",
    "notes": "Orientation A; mild ringing on readout"
  }
