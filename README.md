# Quantum Sensing
## Quantum Experimental System Based on the PYNQ Platform

### Youtube Video

https://youtu.be/D55JbZ45ar8

### Project Structure

PYNQ-Spectroscopy

PYNQ-Relaxometry

PYNQ-Magnet_Shimming

PYNQ-MRI

PYNQ-NMR_PhasedArray

PYNQ-Multi_Channel

### Project Description 

This is a quantum experimentation project based on PYNQ (ZYNQ FPGA from AMD Xilinx) platform. It encompasses hardware circuit design, a graphical user interface (GUI), and several corresponding experiments. In the early stages of development, we employed a range of development platforms—including PYNQ-Z2, ZCU104, ZCU111, and the Kria K26 SoM—to accommodate various application environments. The system is continuously updated on a regular basis.

Most of the setups in this project utilize ASICs developed by our team. However, we also provide alternative implementations that do not require ASICs.

If you require technical support, please feel free to contact me at [zhibin.zhao@iis.uni-stuttgart.de](mailto:zhibin.zhao@iis.uni-stuttgart.de), or my (former) students [yitian.chen@iis.uni-stuttgart.de](mailto:yitian.chen@iis.uni-stuttgart.de) and [yichao.peng@iis.uni-stuttgart.de](mailto:yichao.peng@iis.uni-stuttgart.de).

For collaboration inquiries (regarding the chip or system), please contact Prof. Jens Anders at [jens.anders@iis.uni-stuttgart.de](mailto:jens.anders@iis.uni-stuttgart.de).


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
