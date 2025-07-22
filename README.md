# Quantum Sensing
## Quantum Experimental System Based on the PYNQ Platform

### Youtube Video

https://youtu.be/D55JbZ45ar8

### Project Description 

Due to the unsurpassed specificity and complete non-invasiveness, Nuclear Magnetic Resonance (NMR) is an immensely powerful analytical tool in the field of analytical chemistry, food analysis, oil-well exploration, medical imaging, as well as early-period disease detection. For example, NMR spectroscopy exploits the magnetic characteristics of atomic nuclei to provide specific information about the molecular structure and composition of a sample, while NMR relaxometry measures relaxation variables of a sample and provides valuable information about e.g. molecular mobility and water distribution within food products, and/or molecular dynamic, porosity and moisture content in material science.

Nevertheless, in order to compensate for the comparatively low sensitivity of NMR experiments, standard high-end NMR instruments utilize huge superconducting magnets to create a strong and homogeneous magnetic field since the field's strength boosts the NMR signal and the field's homogeneity is necessary to resolve the spectrum peaks. As a result, they are bulky and expensive, which remains a significant hurdle in making the powerful technology accessible to a wider range of applications.

In this project, with the strategy of substituting large superconducting magnets with small maintenance-free permanent magnets with sufficient field homogeneity and discrete sensor frontend electronics with custom-designed NMR-on-a-chip transceiver, we implement a portable, battery-powered, and low-cost FPGA-based NMR system that is capable of mobile relaxometry and spectroscopy. In addition, edge AI is deployed in our system. We demonstrate the possibilities of spectrum identification, which extends the usage of the system to Non-NMR-professionals, and intelligent field compensation due to temperature drift, which allows us to get rid of the power-hungry temperature control unit. 

### Tools Used 
1. Vivado: used for hardware simulation and implementation.

2. Altium Designer: Circuits schematic design and PCB layout.

3. PYNQ board: GUI visualization and system configuration.
### Directories
1. Documentation: contains all introduction files (including a poster), details of overlay, and experiment results.
   
2. GUI: contains the code for GUI which can be run on PYNQ board together with .bit file.
   
3. PCB: contains all  the electronic circuit designs.
   
4. Video: contains a short introduction video of the architecture and application of the pNMR system.
### Instructions On How To Run the Software System
- Download the GUI files as they are ordered originally, run Launch.ipynb file and GUI will pop up.

### Resource Usage
 
<div align=center>
    <img src="https://github.com/unizhibin/NMR-spectrometer/blob/main/AMD_Xilinx_Challenge_final/Documentation/Overlay%20Usage%20Percentage.PNG" width="400" alt="Image 1" style="float: left; margin-right: 30px;">
    <img src="https://github.com/unizhibin/NMR-spectrometer/blob/main/AMD_Xilinx_Challenge_final/Documentation/Overlay%20Usage.PNG" width="400" alt="Image 2" style="float: left;">
</div align=center>
<p align="center">Resource usage information on PYNQ ZU</p>

<div align=center>
    <img src="https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/FPGA%20Usage/PYNQ_Z2/Overlay%20Usage%20Percentage.PNG" width="400" alt="Image 1" style="float: left; margin-right: 30px;">
    <img src="https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/FPGA%20Usage/PYNQ_Z2/Overlay%20Usage.PNG" width="400" alt="Image 2" style="float: left;">
</div align=center>
<p align="center">Resource usage information on PYNQ Z2(without DPU)</p>

### About This Project
- Technical Complexity: It's a complete instrument system consisting of high-performance hardware design, embedded system design, and user interface software.
- Implementation: Portable NMR system has the potential to broaden the application scenarios in various industry and research areas.
- Marketability: Low-cost, convenient and low power consumption. No complex installation process is needed. Easy to maintain.
- Re-usability: All PCBs, Python codes, Overlay design available. Easy to reproduce.

### Related Documents
- [pNMR_FPGA_poster](https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/pNMR_FPGA_poster.pdf)

- [Hardware and Experiment DoC](https://github.com/unizhibin/Xilinx_Open_Hardware_2023/tree/main/Documentation/Hardware%20and%20Experiment%20DoC.pdf)

- [Overlay_NMR_Spectrometer](https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/Overlay_NMR_Spectrometer.pdf)

- [Z2_daughter_board_schematic](https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/Z2_daughter_board_schematic.pdf)

- [ZU_daughter_board_schematic](https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/ZU_daughter_board_schematic.pdf)

### System Pictures
<div align=center>
    <img src="https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/PYNQ%20Z2%20System.jpg" width="400" alt="Image 1" style="float: left; margin-right: 30px;">
    <img src="https://github.com/unizhibin/Xilinx_Open_Hardware_2023/blob/main/Documentation/PYNQ%20ZU%20System.jpg" width="400" alt="Image 2" style="float: left;">
</div align=center>
<p align="center">pNMR system pictures based on PYNQ-Z2(left) and PYNQ-ZU(right)</p>
