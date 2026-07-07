# University of Stuttgart
# IIS
# constrain for ZCU104 xilinx Evaluation Board 
# Autor: Yichao, Yitian
# Version:  1. Bug fixed Re-write the pin for DAC (Zhibin)
# 			2. Re write by Zhibin Doc
# 			3. Added one more pmod port for unified NMR platform 
#
# Date: Changed by Zhibin 06.12.2023  18:43 (last) 

# Structure:
#  FMC----|
#         |---- NMR AISC Chip Configuration Pins (SPI interface)
#         |---- ADC AD7960  18bits 5MSPS from Analog Device (LVDS and LVCMOS18)
#		  |---- DAC AD9767  16bits 125 MSPS (LVCMOS18)
#		  |---- On Board Status LED (LVCMOS12)
#----------------------------------------------------------------------#
# Warining!
# (IBUF inside of IP Core)
 set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Unified_NMR_v1_0_i/fpga_ADC_AD7960_1/U0/fpga_ADC_AD7960_v1_0_S00_AXI_inst/fpga_AD7960_inst/IBUFDS_DCO/O]
 set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets Unified_NMR_v1_0_i/fpga_ADC_AD7960_0/U0/fpga_ADC_AD7960_v1_0_S00_AXI_inst/fpga_AD7960_inst/IBUFDS_DCO/O]
# NMR AISC Chip Configuration Pins:
#
# low voltage CMOS (1.8V)
#

set_property PACKAGE_PIN F23 [get_ports clk_125_p]
set_property PACKAGE_PIN E23 [get_ports clk_125_n]


set_property IOSTANDARD LVDS [get_ports clk_125_p]
set_property IOSTANDARD LVDS [get_ports clk_125_n]


create_clock -period 8.000 -name clk_125_board -waveform {0.000 4.000} [get_ports clk_125_p]


#
#   Bank 67 VCCO - VADJ_FMC - IO_L15P_T2L_N4_AD11P_67
#   PCB port name: FMC_LPC_LA06_P

	set_property PACKAGE_PIN H19 	  [get_ports "o_tx_pulse"];
	set_property IOSTANDARD LVCMOS18  [get_ports "o_tx_pulse"];
	
#   Bank 67 VCCO - VADJ_FMC - IO_L22P_T3U_N6_DBC_AD0P_67
#   PCB port name: FMC_LPC_LA10_P

	set_property PACKAGE_PIN L15      [get_ports "o_rx_pulse"];	
	set_property IOSTANDARD  LVCMOS18 [get_ports "o_rx_pulse"];

# 	Bank 67 VCCO - VADJ_FMC - IO_L6P_T0U_N10_AD6P_67
#   PCB port name: FMC_LPC_LA14_P
	
	set_property PACKAGE_PIN C13      [get_ports "o_mosi"];
	set_property IOSTANDARD  LVCMOS18 [get_ports "o_mosi"];

# 	Bank 68 VCCO - VADJ_FMC - IO_L23P_T3U_N8_68
#   PCB port name: FMC_LPC_LA27_P
	
	set_property PACKAGE_PIN A8       [get_ports "o_sclk"];
	set_property IOSTANDARD  LVCMOS18 [get_ports "o_sclk"];

# 	Bank 68 VCCO - VADJ_FMC - IO_L16P_T2U_N6_QBC_AD3P_68
#   PCB port name: FMC_LPC_LA18_CC_P
	
	set_property PACKAGE_PIN D11      [get_ports "o_cs"]; 
	set_property IOSTANDARD  LVCMOS18 [get_ports "o_cs"];
#----------------------------------------------------------------------#
# 	DAC AD9767  16bits 125 MSPS
#
# 	low voltage CMOS (1.8V)
#
# 	Bank 68 VCCO - VADJ_FMC - IO_L14P_T2L_N2_GC_68
#   PCB port name: FMC_LPC_LA17_CC_P

	set_property PACKAGE_PIN F11       [get_ports "o_clk_dac"];
	set_property IOSTANDARD  LVCMOS18  [get_ports "o_clk_dac"];

	set_property PACKAGE_PIN F12      [get_ports "ov_dac_data[0]"]; #   PCB port name:  FMC_LPC_LA20_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[0]"];
	set_property PACKAGE_PIN D12      [get_ports "ov_dac_data[1]"]; #   PCB port name:  FMC_LPC_LA19_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[1]"]; 
	set_property PACKAGE_PIN B11      [get_ports "ov_dac_data[2]"]; #   PCB port name:  FMC_LPC_LA23_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[2]"];
	set_property PACKAGE_PIN H13      [get_ports "ov_dac_data[3]"]; #   PCB port name:  FMC_LPC_LA22_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[3]"]; 	
	set_property PACKAGE_PIN B10      [get_ports "ov_dac_data[4]"]; #   PCB port name:  FMC_LPC_LA21_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[4]"];
	set_property PACKAGE_PIN B9       [get_ports "ov_dac_data[5]"]; #   PCB port name:  FMC_LPC_LA26_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[5]"];
	set_property PACKAGE_PIN C7       [get_ports "ov_dac_data[6]"]; #   PCB port name:  FMC_LPC_LA25_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[6]"];
	set_property PACKAGE_PIN B6       [get_ports "ov_dac_data[7]"]; #   PCB port name:  FMC_LPC_LA24_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[7]"];
	set_property PACKAGE_PIN K10      [get_ports "ov_dac_data[8]"]; #   PCB port name:  FMC_LPC_LA29_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[8]"];
	set_property PACKAGE_PIN M13      [get_ports "ov_dac_data[9]"]; #   PCB port name:  FMC_LPC_LA28_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[9]"];
	set_property PACKAGE_PIN F7       [get_ports "ov_dac_data[10]"]; #   PCB port name:  FMC_LPC_LA31_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[10]"];
	set_property PACKAGE_PIN E9       [get_ports "ov_dac_data[11]"]; #   PCB port name:  FMC_LPC_LA30_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[11]"];
	set_property PACKAGE_PIN C9       [get_ports "ov_dac_data[12]"]; #   PCB port name:  FMC_LPC_LA33_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[12]"];
	set_property PACKAGE_PIN F8       [get_ports "ov_dac_data[13]"]; #   PCB port name:  FMC_LPC_LA32_P
	set_property IOSTANDARD  LVCMOS18 [get_ports "ov_dac_data[13]"];
#----------------------------------------------------------------------#
# 	ADC AD7960  18bits 5MSPS from Analog Device
#
#   low voltage CMOS (1.8V):

	set_property PACKAGE_PIN K19      	  [get_ports "o_adc_en_0"]; #   PCB port name:  FMC_LPC_LA03_P
	set_property IOSTANDARD  LVCMOS18     [get_ports "o_adc_en_0"];
	set_property PACKAGE_PIN K18      	  [get_ports "o_adc_en_1"]; #   PCB port name:  FMC_LPC_LA03_N
	set_property IOSTANDARD  LVCMOS18     [get_ports "o_adc_en_1"];
	set_property PACKAGE_PIN L17      	  [get_ports "o_adc_en_2"]; #   PCB port name:  FMC_LPC_LA04_P
	set_property IOSTANDARD  LVCMOS18     [get_ports "o_adc_en_2"];
	set_property PACKAGE_PIN L16      	  [get_ports "o_adc_en_3"]; #   PCB port name:  FMC_LPC_LA04_N
	set_property IOSTANDARD  LVCMOS18     [get_ports "o_adc_en_3"];

#   LVDS signal:
# 	(input):

	set_property PACKAGE_PIN J15      [get_ports "i_ADC_dco_neg_adc0"]; #   PCB port name:  FMC_LPC_LA07_N
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_dco_neg_adc0"];
	set_property PACKAGE_PIN J16      [get_ports "i_ADC_dco_pos_adc0"]; #   PCB port name:  FMC_LPC_LA07_P
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_dco_pos_adc0"];

	set_property PACKAGE_PIN E14      [get_ports "i_ADC_dco_neg_adc1"]; #   PCB port name:  FMC_LPC_CLK0_M2C_N
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_dco_neg_adc1"];
	set_property PACKAGE_PIN E15      [get_ports "i_ADC_dco_pos_adc1"]; #   PCB port name:  FMC_LPC_CLK0_M2C_P
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_dco_pos_adc1"];

	set_property PACKAGE_PIN A12      [get_ports "i_ADC_data_neg_adc0"]; #   PCB port name:  FMC_LPC_LA11_N
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_data_neg_adc0"];
	set_property PACKAGE_PIN A13      [get_ports "i_ADC_data_pos_adc0"]; #   PCB port name:  FMC_LPC_LA11_P
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_data_pos_adc0"];

	set_property PACKAGE_PIN K20      [get_ports "i_ADC_data_neg_adc1"]; #   PCB port name:  FMC_LPC_LA02_N
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_data_neg_adc1"];
	set_property PACKAGE_PIN L20      [get_ports "i_ADC_data_pos_adc1"]; #   PCB port name:  FMC_LPC_LA02_P
	set_property IOSTANDARD  LVDS     [get_ports "i_ADC_data_pos_adc1"];

# 	(Output):

	set_property PACKAGE_PIN E17      [get_ports "o_ADC_clk_neg_adc0"]; #   PCB port name:  FMC_LPC_LA08_N
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_clk_neg_adc0"];
	set_property PACKAGE_PIN E18      [get_ports "o_ADC_clk_pos_adc0"]; #   PCB port name:  FMC_LPC_LA08_P
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_clk_pos_adc0"];

	set_property PACKAGE_PIN F16      [get_ports "o_ADC_clk_neg_adc1"]; #   PCB port name:  FMC_LPC_LA00_CC_N
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_clk_neg_adc1"];
	set_property PACKAGE_PIN F17      [get_ports "o_ADC_clk_pos_adc1"]; #   PCB port name:  FMC_LPC_LA00_CC_P
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_clk_pos_adc1"];

	set_property PACKAGE_PIN G16      [get_ports "o_ADC_cnv_neg_adc0"]; #   PCB port name:  FMC_LPC_LA09_N
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_cnv_neg_adc0"];
	set_property PACKAGE_PIN H16      [get_ports "o_ADC_cnv_pos_adc0"]; #   PCB port name:  FMC_LPC_LA09_P
	set_property IOSTANDARD  LVDS     [get_ports "o_ADC_cnv_pos_adc0"];

	set_property PACKAGE_PIN H17 	  [get_ports {o_ADC_cnv_neg_adc1}]; #   PCB port name:  FMC_LPC_LA01_CC_N
	set_property IOSTANDARD LVDS      [get_ports {o_ADC_cnv_neg_adc1}];
	set_property PACKAGE_PIN H18 	  [get_ports {o_ADC_cnv_pos_adc1}]; #   PCB port name:  FMC_LPC_LA01_CC_P
	set_property IOSTANDARD LVDS 	  [get_ports {o_ADC_cnv_pos_adc1}];
#----------------------------------------------------------------------#
# On Board Status LED
#
#   low voltage CMOS (1.2V):
	set_property PACKAGE_PIN D5       [get_ports "o_led_tracing"] ;# Bank  88 VCCO - VCC3V3   - IO_L11N_AD9N_88
	set_property IOSTANDARD  LVCMOS33 [get_ports "o_led_tracing"] ;# Bank  88 VCCO - VCC3V3   - IO_L11N_AD9N_88
	set_property PACKAGE_PIN D6       [get_ports "o_pulse_gen_led"] ;# Bank  88 VCCO - VCC3V3   - IO_L11P_AD9P_88
	set_property IOSTANDARD  LVCMOS33 [get_ports "o_pulse_gen_led"] ;# Bank  88 VCCO - VCC3V3   - IO_L11P_AD9P_88

# ----------------------------------------------------------------------# 
# The PMOD ports for gradient and for shimming 
# Pmod da4 device has port 0,1,2,3 for upper row, as ~cs (0+4n), Mosi(1+4n), NC,sclk(3+4n) 
set_property PACKAGE_PIN G8       [get_ports "o_cs_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L12N_AD0N_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_cs_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L12N_AD0N_87
set_property PACKAGE_PIN H8       [get_ports "o_mosi_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L12P_AD0P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_mosi_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L12P_AD0P_87
#set_property PACKAGE_PIN G7       [get_ports "PMOD0_2"] ;# Bank  87 VCCO - VCC3V3   - IO_L11N_AD1N_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD0_2"] ;# Bank  87 VCCO - VCC3V3   - IO_L11N_AD1N_87
set_property PACKAGE_PIN H7       [get_ports "o_sclk_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L11P_AD1P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_sclk_grad"] ;# Bank  87 VCCO - VCC3V3   - IO_L11P_AD1P_87
#set_property PACKAGE_PIN G6       [get_ports "PMOD0_4"] ;# Bank  87 VCCO - VCC3V3   - IO_L10N_AD2N_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD0_4"] ;# Bank  87 VCCO - VCC3V3   - IO_L10N_AD2N_87
#set_property PACKAGE_PIN H6       [get_ports "PMOD0_5"] ;# Bank  87 VCCO - VCC3V3   - IO_L10P_AD2P_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD0_5"] ;# Bank  87 VCCO - VCC3V3   - IO_L10P_AD2P_87
#set_property PACKAGE_PIN J6       [get_ports "PMOD0_6"] ;# Bank  87 VCCO - VCC3V3   - IO_L9N_AD3N_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD0_6"] ;# Bank  87 VCCO - VCC3V3   - IO_L9N_AD3N_87
#set_property PACKAGE_PIN J7       [get_ports "PMOD0_7"] ;# Bank  87 VCCO - VCC3V3   - IO_L9P_AD3P_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD0_7"] ;# Bank  87 VCCO - VCC3V3   - IO_L9P_AD3P_87
set_property PACKAGE_PIN J9       [get_ports "o_cs_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L8N_HDGC_AD4N_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_cs_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L8N_HDGC_AD4N_87
set_property PACKAGE_PIN K9       [get_ports "o_mosi_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_mosi_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L8P_HDGC_AD4P_87
#set_property PACKAGE_PIN K8       [get_ports "PMOD1_2"] ;# Bank  87 VCCO - VCC3V3   - IO_L7N_HDGC_AD5N_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD1_2"] ;# Bank  87 VCCO - VCC3V3   - IO_L7N_HDGC_AD5N_87
set_property PACKAGE_PIN L8       [get_ports "o_sclk_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L7P_HDGC_AD5P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_sclk_shim_0"] ;# Bank  87 VCCO - VCC3V3   - IO_L7P_HDGC_AD5P_87
set_property PACKAGE_PIN L10      [get_ports "o_cs_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L6N_HDGC_AD6N_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_cs_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L6N_HDGC_AD6N_87
set_property PACKAGE_PIN M10      [get_ports "o_mosi_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L6P_HDGC_AD6P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_mosi_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L6P_HDGC_AD6P_87
#set_property PACKAGE_PIN M8       [get_ports "PMOD1_6"] ;# Bank  87 VCCO - VCC3V3   - IO_L5N_HDGC_AD7N_87
#set_property IOSTANDARD  LVCMOS33 [get_ports "PMOD1_6"] ;# Bank  87 VCCO - VCC3V3   - IO_L5N_HDGC_AD7N_87
set_property PACKAGE_PIN M9       [get_ports "o_sclk_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L5P_HDGC_AD7P_87
set_property IOSTANDARD  LVCMOS33 [get_ports "o_sclk_shim_1"] ;# Bank  87 VCCO - VCC3V3   - IO_L5P_HDGC_AD7P_87