----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2022/05/27 17:42:21
-- Design Name: 
-- Module Name: fpga_pulse_gen - Behavioral
-- Project Name: NMR EPR pulse generator 
-- Target Devices: 
-- Tool Versions: 2019.1 vivado
-- Description:  
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- -- memory interface
--
-- for i in 0 to number of sections 
-- 11 is the number of activities
-- if section type = 0 tx
--    section type = 1 rx
-- 0  + i*11 section type
-- #tx# 	
-- 1  + i*11 phase set duration
-- 2  + i*11 TX pulse duration
-- 3  + i*11 wait duration

-- #rx#
-- 4  + i*11 wait mux duration
-- 5  + i*11 RX pulse duration
-- 6  + i*11 cycle end wait duration

-- 7  + i*11 phase offset for channel 0
-- 8  + i*11 frequency offset for channel 0
-- 9  + i*11 phase offset for channel 1
-- 10 + i*11 frequency offset for channel 1

-- pulse gen mem to save the section activity by user
-- upgrade version, user can save more activity (grad coil control)
----------------------------------------------------------------------------------


-- ! Use standard library ieee
library IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;

-- ! Use library fpga_pulse_gen_pkg
USE work.fpga_pulse_gen_pkg.ALL;

entity fpga_pulse_gen is
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
		o_gradient_tvalid					: OUT std_logic;		
		ov_set_gradient_x					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_x_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z_ref				: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		
		iv_set_gradient_sweep				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_step 		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)		
	);
end fpga_pulse_gen;

architecture Behavioral of fpga_pulse_gen is

-- counter interface signal
	signal
	timer_data_i
	:unsigned (C_DATA_WIDTH - 1 DOWNTO 0):= (others => '0');
	
	signal
	rstn_i,
	timer_en_i,
	timer_load_en_i,
	timer_done_i,
	cycle_repetition_en_i,
	cycle_repetition_load_en_i,
	cycle_repetition_done_i,
	experiment_repetition_en_i,	
	experiment_repetition_load_en_i,
	experiment_repetition_done_i,
	timer_pre_done_i,
	pre_cycle_repetition_done_i
	: std_logic := '0';
	
-- memory interface	
	signal
	wr_en_i
	: std_logic := '0';
	
	signal
	read_sel_section_i,
	set_section_type_i,
	set_delay_i,
	set_mux_i,
	set_phase_ch0_i,
	set_frequency_ch0_i,
	set_phase_ch1_i,
	set_frequency_ch1_i,
	set_resetn_dds_i,
	experiment_last_nr_i,
	set_gradient_x_i,
	set_gradient_y_i,
	set_gradient_z_i,
	set_gradient_x_ref_i,
	set_gradient_y_ref_i,
	set_gradient_z_ref_i,
	counter_data_repetition_i,
	set_gradient_x_sweep_offset_i,
	set_gradient_y_sweep_offset_i,
	set_gradient_z_sweep_offset_i,
	set_gradient_sweep_i
	:unsigned (C_DATA_WIDTH - 1 DOWNTO 0):= (others => '0');	
	
begin

-- central processing unit
	inst_control_unit_inst: ENTITY work.fpga_pulse_gen_cu(Behavioral)
	 PORT MAP 
	 (
		clk							 		=> clk,				 					-- axi clock
		o_tx_pulse					 		=> o_tx_pulse,							-- transmitter activation pulse
		o_rx_pulse					 		=> o_rx_pulse,							-- receiver activation pulse
		ov_config_dds_data_ch0				=> ov_config_dds_data_ch0, 				-- DDS config data output
		o_config_tvalid_ch0					=> o_config_tvalid_ch0, 				-- DDS valid signal output		
		ov_config_dds_data_ch1				=> ov_config_dds_data_ch1,				-- DDS config data output	
		o_config_tvalid_ch1					=> o_config_tvalid_ch1,			
		o_mux_ch							=> o_mux_ch,
		i_en					 	 		=> i_en,
		o_mem_wr_en							=> wr_en_i,
		iv_set_nr_sections					=> iv_set_nr_sections,
		ov_sel_section						=> read_sel_section_i,
		o_rstn								=> rstn_i,
		iv_section_type						=> set_section_type_i,			
		iv_set_delay  						=> set_delay_i,
		iv_set_mux							=> set_mux_i,
		iv_set_phase_ch0					=> set_phase_ch0_i,
		iv_set_frequency_ch0				=> set_frequency_ch0_i,
		iv_set_phase_ch1					=> set_phase_ch1_i,
		iv_set_frequency_ch1				=> set_frequency_ch1_i,
		iv_set_resetn_dds					=> set_resetn_dds_i,
		o_dds_rstn							=> o_dds_rstn,		
		o_timer_en							=> timer_en_i,
		o_timer_load_en						=> timer_load_en_i,
		i_timer_pre_done					=> timer_pre_done_i,
		ov_timer_data						=> timer_data_i,
		i_timer_done						=> timer_done_i,
		o_cycle_repetition_en				=> cycle_repetition_en_i,
		o_cycle_repetition_load_en			=> cycle_repetition_load_en_i,
		i_cycle_repetition_done				=> cycle_repetition_done_i,
		iv_experiment_last_nr				=> experiment_last_nr_i,
		o_experiment_repetition_en			=> experiment_repetition_en_i,
		o_experiment_repetition_load_en		=> experiment_repetition_load_en_i,
		i_experiment_repetition_done		=> experiment_repetition_done_i,
		-- repetition contol
		iv_set_start_repeat_pointer			=> iv_set_start_repeat_pointer,
		iv_set_end_repeat_pointer 			=> iv_set_end_repeat_pointer,
		i_pre_cycle_repetition_done			=> pre_cycle_repetition_done_i, 
		o_busy						 		=> o_busy,		
		o_data_ready				 		=> o_data_ready,
		--gradient control
		iv_repetition_gradient_sweep_number	=> counter_data_repetition_i,
		iv_set_gradient_x					=> set_gradient_x_i,
		iv_set_gradient_y					=> set_gradient_y_i,
		iv_set_gradient_z					=> set_gradient_z_i,
		iv_set_gradient_x_ref				=> set_gradient_x_ref_i,
		iv_set_gradient_y_ref				=> set_gradient_y_ref_i,
		iv_set_gradient_z_ref				=> set_gradient_z_ref_i,
		iv_set_gradient_x_sweep_offset		=> set_gradient_x_sweep_offset_i,
		iv_set_gradient_y_sweep_offset		=> set_gradient_y_sweep_offset_i,
		iv_set_gradient_z_sweep_offset		=> set_gradient_z_sweep_offset_i,		
		ov_set_gradient_x					=> ov_set_gradient_x,
		ov_set_gradient_y					=> ov_set_gradient_y,
		ov_set_gradient_z					=> ov_set_gradient_z,
		ov_set_gradient_x_ref				=> ov_set_gradient_x_ref,
		ov_set_gradient_y_ref				=> ov_set_gradient_y_ref,
		ov_set_gradient_z_ref				=> ov_set_gradient_z_ref,
		o_gradient_tvalid					=> o_gradient_tvalid,
		iv_set_gradient_sweep		 		=> set_gradient_sweep_i,
		iv_set_gradient_x_sweep_step 		=> iv_set_gradient_x_sweep_step,
		iv_set_gradient_y_sweep_step 		=> iv_set_gradient_y_sweep_step,
		iv_set_gradient_z_sweep_step 		=> iv_set_gradient_z_sweep_step
	);
		
-- timer
--
-- fpga_pulse_cu (control unit) will upload the timer, (Type: Down counter)
inst_fpga_pulse_timer: ENTITY work.fpga_pulse_timer(Behavioral)
	PORT MAP
	(
		clk 								=> clk,
		i_rstn								=> rstn_i,
		i_timer_en							=> timer_en_i,
		i_timer_load_en						=> timer_load_en_i,		
		iv_timer_data						=> timer_data_i,
		o_timer_pre_done					=> timer_pre_done_i,
		o_timer_done						=> timer_done_i
	);
	
-- counter--
-- fpga_pulse_cu (control unit) will upload the cycle repetition counter, (Type: Down counter)
inst_fpga_pulse_cycle_repetition_counter: ENTITY work.fpga_pulse_counter(Behavioral)
	PORT MAP
	(
		clk 								=> clk,
		i_rstn								=> rstn_i,
		i_counter_en						=> cycle_repetition_en_i,
		i_counter_load_en					=> cycle_repetition_load_en_i,
		ov_counter_data						=> counter_data_repetition_i,
		iv_counter_data						=> iv_set_cycle_repetition_number,
		o_pre_counter_done					=> pre_cycle_repetition_done_i,
		o_counter_done						=> cycle_repetition_done_i
	);
	
-- fpga_pulse_cu (control unit) will upload the experiment repetition counter, (Type: Down counter)
inst_fpga_pulse_experiment_repetition_counter: ENTITY work.fpga_pulse_counter(Behavioral)
	PORT MAP
	(
		clk 								=> clk,
		i_rstn								=> rstn_i,
		i_counter_en						=> experiment_repetition_en_i,
		i_counter_load_en					=> experiment_repetition_load_en_i,		
		ov_counter_data						=> experiment_last_nr_i,
		iv_counter_data						=> iv_set_experiment_repetition_number,
		o_pre_counter_done					=> open,	
		o_counter_done						=> experiment_repetition_done_i
	);	
				
inst_fpga_pulse_gen_mem: ENTITY work.fpga_pulse_mem(Behavioral)
	PORT MAP
	(
        clk        							=> clk,
        i_wr_en    							=> wr_en_i,
		iv_write_sel_section				=> iv_write_sel_section,
		iv_set_section_type					=> iv_set_section_type,
		iv_set_delay						=> iv_set_delay,
		iv_set_mux							=> iv_set_mux,
		iv_set_phase_ch0					=> iv_set_phase_ch0,
		iv_set_frequency_ch0				=> iv_set_frequency_ch0,
		iv_set_phase_ch1					=> iv_set_phase_ch1,
		iv_set_frequency_ch1				=> iv_set_frequency_ch1,
		iv_set_resetn_dds					=> iv_set_resetn_dds,
		iv_set_gradient_x					=> iv_set_gradient_x,
		iv_set_gradient_y					=> iv_set_gradient_y,
		iv_set_gradient_z					=> iv_set_gradient_z,
		iv_set_gradient_x_ref				=> iv_set_gradient_x_ref,
		iv_set_gradient_y_ref				=> iv_set_gradient_y_ref,
		iv_set_gradient_z_ref				=> iv_set_gradient_z_ref,
		iv_set_gradient_x_sweep_offset		=> iv_set_gradient_x_sweep_offset,
		iv_set_gradient_y_sweep_offset		=> iv_set_gradient_y_sweep_offset,
		iv_set_gradient_z_sweep_offset		=> iv_set_gradient_z_sweep_offset,		
		iv_set_gradient_sweep				=> iv_set_gradient_sweep,
		
		iv_read_sel_section					=> read_sel_section_i,
		ov_section_type						=> set_section_type_i,
		ov_set_delay						=> set_delay_i,
		ov_set_mux							=> set_mux_i,
		ov_set_phase_ch0					=> set_phase_ch0_i,
		ov_set_frequency_ch0				=> set_frequency_ch0_i,
		ov_set_phase_ch1					=> set_phase_ch1_i,
		ov_set_frequency_ch1				=> set_frequency_ch1_i,
		ov_set_resetn_dds					=> set_resetn_dds_i,
		ov_set_gradient_x					=> set_gradient_x_i,
		ov_set_gradient_y					=> set_gradient_y_i,
		ov_set_gradient_z					=> set_gradient_z_i,
		ov_set_gradient_x_ref				=> set_gradient_x_ref_i,
		ov_set_gradient_y_ref				=> set_gradient_y_ref_i,
		ov_set_gradient_z_ref				=> set_gradient_z_ref_i,
		ov_set_gradient_x_sweep_offset		=> set_gradient_x_sweep_offset_i,
		ov_set_gradient_y_sweep_offset		=> set_gradient_y_sweep_offset_i,
		ov_set_gradient_z_sweep_offset		=> set_gradient_z_sweep_offset_i,	
		ov_set_gradient_sweep				=> set_gradient_sweep_i
	);

end Behavioral;
