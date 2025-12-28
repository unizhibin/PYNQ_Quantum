----------------------------------------------------------------------------------
-- Company: University of Stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2022/05/26 23:21:33
-- Design Name: 
-- Module Name: fpga_pulse_gen_top - Behavioral
-- Project Name: NMR EPR pulse generator 
-- Target Devices: ZCU104
-- Tool Versions: 2019.1 vivado
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- Version 2.0 add Magnetic Resonance Imaging grandient Control Unit 02.05.2025 Zhibin Zhao 
----------------------------------------------------------------------------------


-- ! Use standard library ieee
library IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

-- ! Use library fpga_pulse_gen_pkg and fpga_pulse_gen_if_pkg
USE work.fpga_pulse_gen_pkg.ALL;



entity fpga_pulse_gen_top is
    Port 
	( 
		clk 									: IN  std_logic; 	--axi clock
		o_tx_pulse								: OUT std_logic; 	--tx pulse
		o_rx_pulse								: OUT std_logic; 	--rx pulse			
		ov_config_dds_data_ch0					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output
		o_config_tvalid_ch0						: OUT std_logic; -- DDS valid signal output		
		ov_config_dds_data_ch1					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output	
		o_config_tvalid_ch1						: OUT std_logic; -- DDS valid signal output		
		o_mux_ch								: OUT std_logic; 
		i_en									: IN  std_logic;
		-- select the section
		iv_set_nr_sections						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_write_sel_section					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- select the number of to config		
		iv_set_section_type						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- section type 																					  -- 0: Tx																					  -- 1: Rx	
		iv_set_delay 							: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_mux 								: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		-- repetition contol
		iv_set_start_repeat_pointer				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_end_repeat_pointer 				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_cycle_repetition_number			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);		
		iv_set_experiment_repetition_number		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		-- DDS contol
		o_dds_rstn								: OUT std_logic; 		
		iv_set_phase_ch0		 				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- configuration the phase of dds
		iv_set_frequency_ch0		 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- configuraton the frequency 		
		iv_set_phase_ch1			 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- configuration the phase of dds
		iv_set_frequency_ch1		 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- configuraton the frequency 		
		iv_set_resetn_dds						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); 
		o_busy									: OUT std_logic;
		o_data_ready							: OUT std_logic;		
		ov_nr_dds_ch				 			: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0); -- get the number of the dds
		ov_mem_depth							: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_nr_activity							: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		-- Gradient Control Unit
		iv_set_gradient_x						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_ref					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_ref					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_ref					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_offset			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_offset			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_offset			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
			
		ov_set_gradient_x					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_x_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		o_gradient_tvalid					: OUT std_logic;
		
		iv_set_gradient_sweep				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
	);
end fpga_pulse_gen_top;

architecture Behavioral of fpga_pulse_gen_top is

begin
    -- instantiation of the fpga_pulse_gen component
	fpga_pulse_gen_inst: ENTITY work.fpga_pulse_gen(Behavioral)
        PORT MAP 
		(	
			clk							 		=> clk,				 			-- axi clock
			o_tx_pulse					 		=> o_tx_pulse,					-- transmitter activation pulse
			o_rx_pulse					 		=> o_rx_pulse,					-- receiver activation pulse
			ov_config_dds_data_ch0				=> ov_config_dds_data_ch0,
			o_config_tvalid_ch0					=> o_config_tvalid_ch0,
			ov_config_dds_data_ch1				=> ov_config_dds_data_ch1,
			o_config_tvalid_ch1					=> o_config_tvalid_ch1,
			o_mux_ch							=> o_mux_ch,			
			i_en					 	 		=> i_en,
			-- select the section
			iv_set_nr_sections					=> iv_set_nr_sections,
			iv_write_sel_section				=> iv_write_sel_section,
			iv_set_section_type					=> iv_set_section_type,
			iv_set_delay 						=> iv_set_delay,
			iv_set_mux 							=> iv_set_mux,
			-- repetition contol
			iv_set_start_repeat_pointer			=> iv_set_start_repeat_pointer,
			iv_set_end_repeat_pointer 			=> iv_set_end_repeat_pointer,
			iv_set_cycle_repetition_number		=> iv_set_cycle_repetition_number,
			iv_set_experiment_repetition_number	=> iv_set_experiment_repetition_number,
			-- DDS control
			o_dds_rstn							=> o_dds_rstn,
			iv_set_phase_ch0		 			=> iv_set_phase_ch0,
			iv_set_frequency_ch0		 		=> iv_set_frequency_ch0,		
			iv_set_phase_ch1			 		=> iv_set_phase_ch1,
			iv_set_frequency_ch1		 		=> iv_set_frequency_ch1, 		
			iv_set_resetn_dds					=> iv_set_resetn_dds,
			o_busy						 		=> o_busy,		
			o_data_ready				 		=> o_data_ready,
			-- Gradient Control
			iv_set_gradient_x					=> iv_set_gradient_x,
			iv_set_gradient_y					=> iv_set_gradient_y,
			iv_set_gradient_z					=> iv_set_gradient_z,
			iv_set_gradient_x_ref				=> iv_set_gradient_x_ref,
			iv_set_gradient_y_ref				=> iv_set_gradient_y_ref,
			iv_set_gradient_z_ref				=> iv_set_gradient_z_ref,
			
			iv_set_gradient_x_sweep_offset			=> iv_set_gradient_x_sweep_offset,
			iv_set_gradient_y_sweep_offset			=> iv_set_gradient_y_sweep_offset,
			iv_set_gradient_z_sweep_offset			=> iv_set_gradient_z_sweep_offset,
			
			ov_set_gradient_x					=> ov_set_gradient_x,
			ov_set_gradient_y					=> ov_set_gradient_y,
			ov_set_gradient_z					=> ov_set_gradient_z,
			ov_set_gradient_x_ref				=> ov_set_gradient_x_ref,
			ov_set_gradient_y_ref				=> ov_set_gradient_y_ref,
			ov_set_gradient_z_ref				=> ov_set_gradient_z_ref,
			o_gradient_tvalid					=> o_gradient_tvalid,
			iv_set_gradient_sweep		 		=> iv_set_gradient_sweep,
			iv_set_gradient_x_sweep_step 		=> iv_set_gradient_x_sweep_step,
			iv_set_gradient_y_sweep_step 		=> iv_set_gradient_y_sweep_step,
			iv_set_gradient_z_sweep_step 		=> iv_set_gradient_z_sweep_step				
		);
-- READ INFO:		
		ov_nr_dds_ch 	<= std_logic_vector(to_unsigned(C_NR_DDS_XILINX,ov_nr_dds_ch'length));
		ov_mem_depth 	<= std_logic_vector(to_unsigned(C_MEM_ADDR_WIDTH,ov_nr_dds_ch'length));
		ov_nr_activity	<= std_logic_vector(to_unsigned(C_NR_ACTIVITY,ov_nr_dds_ch'length));

	
end Behavioral;
							
	














	
		
	