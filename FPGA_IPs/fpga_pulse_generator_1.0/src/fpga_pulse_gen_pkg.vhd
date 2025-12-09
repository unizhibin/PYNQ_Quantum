-- NMR EPR Pulse generator package file
-- Interface package
-- package:  fpga_pulse_gen_pkg
-- Autor:	 Zhibin Zhao
-- Company:  Universty of Stuttgart
-- Version: 1.0 
-- 26.05.2022
-- Version: 2.0
-- 02.05.2025
-- add MRI grandient control

-- ! Use standard library ieee
LIBRARY ieee;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE IEEE.NUMERIC_STD.ALL;
USE ieee.math_real.ALL;

PACKAGE fpga_pulse_gen_pkg IS

-- Number of bits of data signals
    CONSTANT C_DATA_WIDTH         : integer := 32;
-- Width of command of fpga_pulse_gen
	CONSTANT C_COMMAND_WIDTH      : integer := 8;
-- Number of bits of xilinx dds ip core configuration data width
    CONSTANT C_DDS_CONFIG_DATA_WIDTH         : integer := 64;
-- Number of configuration xilinx DDS
	CONSTANT C_NR_DDS_XILINX 	  : integer := 2;
-- Determines the depth of the memories	
	CONSTANT C_MEM_ADDR_WIDTH     : integer := 7;  
-- Number of bits of phase data for xilinx dds	
	CONSTANT C_NR_BIT_DDS_PHASE_XILINX 	  : integer := 32;
-- Number of command to control the section
	CONSTANT C_NR_ACTIVITY : integer := 18; --! add command must heir change!
											-- Version 2.0 add 6 commands for grandient control
-- Address for section control
	-- The type of section
	CONSTANT C_SECTION_TYPE : integer := 0;
	-- delay
	CONSTANT C_DELAY : integer := 1;
	-- The wait mux duration
	CONSTANT C_SET_MUX : integer := 2;
	-- The phase offset for channel 0
	CONSTANT C_PHASE_OFFSET_CH0 : integer := 3;
	-- The frequency offset for channel 0
	CONSTANT C_FREQUENCY_OFFSET_CH0 : integer := 4;
	-- The phase offset for channel 1
	CONSTANT C_PHASE_OFFSET_CH1 : integer := 5;
	-- The frequency offset for channel 1
	CONSTANT C_FREQUENCY_OFFSET_CH1 : integer := 6;
	-- Reset the DDS
	CONSTANT C_DDS_RESETN : integer := 7;
	
	-- Gradient X
	CONSTANT C_X_GRADIENT : integer := 8;
	-- Gradient Y
	CONSTANT C_Y_GRADIENT : integer := 9;
	-- Gradient X
	CONSTANT C_Z_GRADIENT : integer := 10;	
	-- Gradient X REFERENCE
	CONSTANT C_X_GRADIENT_REF : integer := 11;
	-- Gradient Y REFERENCE
	CONSTANT C_Y_GRADIENT_REF : integer := 12;
	-- Gradient Z REFERENCE
	CONSTANT C_Z_GRADIENT_REF : integer := 13;
	-- Gradient X OFFSET
	CONSTANT C_X_GRADIENT_OFFSET : integer := 14;
	-- Gradient Y OFFSET
	CONSTANT C_Y_GRADIENT_OFFSET : integer := 15;
	-- Gradient Z OFFSET
	CONSTANT C_Z_GRADIENT_OFFSET : integer := 16;	
	-- Gradient SWEEP
	CONSTANT C_GRADIENT_SWEEP : integer := 17;	
	
-- Address for section control
	-- The type of section Tx
	CONSTANT C_STYPE_TX : integer := 0;
	-- The type of section Rx
	CONSTANT C_STYPE_RX : integer := 1;
	-- The type of section Delay
	CONSTANT C_STYPE_DELAY : integer := 2;
	
-- Derived constants
	
	SUBTYPE t_pulse_gen_config_data IS unsigned;
	
	CONSTANT C_SEL_DDS_CH_WIDTH : integer := integer(ceil(log2(real(C_NR_DDS_XILINX))));
	
-- Type deinition for array of configuration data signals
	TYPE t_pulse_gen_config_data_signals IS ARRAY (natural RANGE <>) OF t_pulse_gen_config_data(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0);
-- Tyoe definition for array of control signals	
	TYPE t_pulse_gen_config_valid_signals IS ARRAY (natural RANGE <>) OF unsigned(0 DOWNTO 0);
	
END fpga_pulse_gen_pkg;

PACKAGE BODY fpga_pulse_gen_pkg IS
END fpga_pulse_gen_pkg;
