----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2022/05/27 14:43:04
-- Design Name: Testbench
-- Module Name: fpga_pulse_gen_if_top_tb - Behavioral
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
-- Version 2.0 test the gradient control unit

-- Revision:
-- v2.1 
-- Engineer: Yitian Chen
-- Date: 2025/12/28 
-- Description: 
-- 1. Modified the MRI sequence stimulus to verify the bi-directional gradient sweep functionality.
--    This sequence is targeted to implement Turbo Spin Echo (TSE) imaging.
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


entity fpga_pulse_gen_if_top_tb is

end fpga_pulse_gen_if_top_tb;

architecture Behavioral of fpga_pulse_gen_if_top_tb is
 	
	constant C_DATA_WIDTH	: integer	:= 32; 
	
	--Inputs
		SIGNAL 
		clk,
		rx_pulse,
		tx_pulse,
		i_en,
		o_busy,
		o_data_ready,
		o_gradient_tvalid
		: std_logic := '0';
	
	-- Outputs
		SIGNAL
		iv_set_nr_sections,
		iv_write_sel_section,
		iv_set_section_type,
		iv_set_delay,
		iv_set_mux,
		iv_set_start_repeat_pointer,
		iv_set_end_repeat_pointer,
		iv_set_cycle_repetition_number,
		iv_set_experiment_repetition_number,
		iv_set_phase_ch0,
		iv_set_frequency_ch0,
		iv_set_phase_ch1,
		iv_set_frequency_ch1,
		iv_set_resetn_dds
		: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');  
		
		SIGNAL
		ov_nr_dds_ch,
		ov_mem_depth,
		ov_nr_activity
		: std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
		
	-- Gradient control
	
		SIGNAL
		iv_set_gradient_x,
		iv_set_gradient_y,
		iv_set_gradient_z,
		iv_set_gradient_x_ref,
		iv_set_gradient_y_ref,
		iv_set_gradient_z_ref,
		iv_set_gradient_sweep,
		iv_set_gradient_x_sweep_step,
		iv_set_gradient_y_sweep_step,
		iv_set_gradient_z_sweep_step,
		iv_set_gradient_x_sweep_offset,
		iv_set_gradient_y_sweep_offset,
		iv_set_gradient_z_sweep_offset	
		: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');  

		SIGNAL
		ov_set_gradient_x,
		ov_set_gradient_y,
		ov_set_gradient_z,
		ov_set_gradient_x_ref,
		ov_set_gradient_y_ref,
		ov_set_gradient_z_ref
		
		: std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
		
	
	--Clock period definitions
	CONSTANT clk_period : time := 10 ns;
		
	component fpga_pulse_gen_top is
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
		
		ov_set_gradient_x						: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y						: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z						: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_x_ref					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y_ref					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z_ref					: OUT std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
		o_gradient_tvalid						: OUT std_logic;
		iv_set_gradient_sweep					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_step 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_step 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_step 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
	);
	end component fpga_pulse_gen_top;	
	
begin

	inst_fpga_pulse_gen_if_top : ENTITY work.fpga_pulse_gen_top(Behavioral)
		PORT MAP
		(
		clk 									=> clk,			--axi clock
		o_tx_pulse								=> tx_pulse,	--tx pulse
		o_rx_pulse								=> rx_pulse,	--rx pulse			
		ov_config_dds_data_ch0					=> open, 		-- DDS config data output
		o_config_tvalid_ch0						=> open,	 	-- DDS valid signal output		
		ov_config_dds_data_ch1					=> open, 		-- DDS config data output	
		o_config_tvalid_ch1						=> open,		-- DDS valid signal output		
		o_mux_ch								=> open,
		-- control write to mem
		i_en									=> i_en,
		-- select the section
		iv_set_nr_sections						=> iv_set_nr_sections,
		iv_write_sel_section					=> iv_write_sel_section,		-- select the number of to config		
		iv_set_section_type						=> iv_set_section_type, 	 	-- section type 																					  -- 0: Tx																					  -- 1: Rx	
		iv_set_delay 							=> iv_set_delay,
		iv_set_mux 								=> iv_set_mux,
		-- repetition contol
		iv_set_start_repeat_pointer				=> iv_set_start_repeat_pointer,
		iv_set_end_repeat_pointer 				=> iv_set_end_repeat_pointer,
		iv_set_cycle_repetition_number			=> iv_set_cycle_repetition_number,	
		iv_set_experiment_repetition_number		=> iv_set_experiment_repetition_number,
		-- DDS contol
		o_dds_rstn								=> open,		
		iv_set_phase_ch0		 				=> iv_set_phase_ch0,			-- configuration the phase of dds
		iv_set_frequency_ch0		 			=> iv_set_frequency_ch0, 	-- configuraton the frequency 		
		iv_set_phase_ch1			 			=> iv_set_phase_ch1, -- configuration the phase of dds
		iv_set_frequency_ch1		 			=> iv_set_frequency_ch1, -- configuraton the frequency 		
		iv_set_resetn_dds						=> iv_set_resetn_dds, 
		o_busy									=> o_busy,
		o_data_ready							=> o_data_ready,		
		ov_nr_dds_ch				 			=> ov_nr_dds_ch,  -- get the number of the dds
		ov_mem_depth							=> ov_mem_depth,
		ov_nr_activity							=> ov_nr_activity,
		-- Gradient Control Unit
		iv_set_gradient_x						=> iv_set_gradient_x,
		iv_set_gradient_y						=> iv_set_gradient_y,
		iv_set_gradient_z						=> iv_set_gradient_z,
		iv_set_gradient_x_ref					=> iv_set_gradient_x_ref,
		iv_set_gradient_y_ref					=> iv_set_gradient_y_ref,
		iv_set_gradient_z_ref					=> iv_set_gradient_z_ref,
		
		iv_set_gradient_x_sweep_offset			=> iv_set_gradient_x_sweep_offset,
		iv_set_gradient_y_sweep_offset			=> iv_set_gradient_y_sweep_offset,
		iv_set_gradient_z_sweep_offset			=> iv_set_gradient_z_sweep_offset,	
		
		ov_set_gradient_x						=> ov_set_gradient_x,
		ov_set_gradient_y						=> ov_set_gradient_y,
		ov_set_gradient_z						=> ov_set_gradient_z,
		ov_set_gradient_x_ref					=> ov_set_gradient_x_ref,
		ov_set_gradient_y_ref					=> ov_set_gradient_y_ref,
		ov_set_gradient_z_ref					=> ov_set_gradient_z_ref,	
		o_gradient_tvalid						=> o_gradient_tvalid,
		iv_set_gradient_sweep					=> iv_set_gradient_sweep,
		iv_set_gradient_x_sweep_step 			=> iv_set_gradient_x_sweep_step,
		iv_set_gradient_y_sweep_step 			=> iv_set_gradient_y_sweep_step,
		iv_set_gradient_z_sweep_step 			=> iv_set_gradient_z_sweep_step
		);

    -- Clock process definitions
	clk_process : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
	END PROCESS;
	
	
	--Stimulus process
	 stim_proc : PROCESS
			-- generic procedure for writing data to the fpga_pulse_gen_top component			
			PROCEDURE write_general_setting_data_prod
			 (
				CONSTANT nr_sections       				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT start_repeat_pointer	   		: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT end_repeat_pointer				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT cycle_repetition_number		: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT experiment_repetition_number	: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_x_sweep_step 			: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_y_sweep_step 			: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_z_sweep_step 			: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
			 )
				IS BEGIN
					WAIT UNTIL rising_edge(clk);
					i_en <= '0'; -- write data in mem				
					iv_set_nr_sections 					<= 	nr_sections;
					iv_set_start_repeat_pointer			<=	start_repeat_pointer;
					iv_set_end_repeat_pointer			<= 	end_repeat_pointer;
					iv_set_cycle_repetition_number  	<= 	cycle_repetition_number;
					iv_set_experiment_repetition_number	<= 	experiment_repetition_number;
					iv_set_gradient_x_sweep_step		<=	gradient_x_sweep_step;
					iv_set_gradient_y_sweep_step		<=	gradient_y_sweep_step;
					iv_set_gradient_z_sweep_step		<=	gradient_z_sweep_step;
					WAIT UNTIL rising_edge(clk);	
			END write_general_setting_data_prod;
			

			PROCEDURE write_section_data_prod
			 (
				CONSTANT write_sel_section				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT section_type	   				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT delay							: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT mux							: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT phase_ch0						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT frequency_ch0					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);				
				CONSTANT phase_ch1						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);			
				CONSTANT frequency_ch1					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT resetn_dds						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
			-- gradient control	
				CONSTANT gradient_x						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_y						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_z						: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_x_ref					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_y_ref					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_z_ref					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_x_offset				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_y_offset				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
				CONSTANT gradient_z_offset				: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0);				
				CONSTANT gradient_sweep					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0)			
			 )
				IS BEGIN
					WAIT UNTIL rising_edge(clk);
					i_en <= '0'; -- write data in mem				
					iv_write_sel_section 					<= 	write_sel_section;
					iv_set_section_type						<=	section_type;
					iv_set_delay							<= 	delay;
					iv_set_mux  							<= 	mux;
					iv_set_phase_ch0						<= 	phase_ch0;
					iv_set_frequency_ch0					<= 	frequency_ch0;
					iv_set_phase_ch1						<=  phase_ch1;
					iv_set_frequency_ch1					<= 	frequency_ch1;
					iv_set_resetn_dds						<=  resetn_dds;
					iv_set_gradient_x						<=  gradient_x;
					iv_set_gradient_y						<= 	gradient_y;
					iv_set_gradient_z						<= 	gradient_z;
					iv_set_gradient_x_ref					<= 	gradient_x_ref;
					iv_set_gradient_y_ref					<= 	gradient_y_ref;
					iv_set_gradient_z_ref					<=  gradient_z_ref;
					iv_set_gradient_x_sweep_offset			<=  gradient_x_offset;
					iv_set_gradient_y_sweep_offset			<=  gradient_y_offset;
					iv_set_gradient_z_sweep_offset			<=  gradient_z_offset;						
					iv_set_gradient_sweep					<= 	gradient_sweep;					
					WAIT UNTIL rising_edge(clk);
			END write_section_data_prod;
			
		BEGIN
		
-- MRI sequence simulation 
-- Total section 13
-- repetition			   .|.																										   .|.
-- section		0			1		  2			3			4			5			6		  7			8			9		  10	   11		   12
--			--Delay--	--Delay--	--Tx--	--Delay--	--Delay--	--Delay--	--Delay--	--Tx--	--Delay--	--Delay--	--Rx--	--Delay--	--Delay--
-- Tx			0			0		  P90		0			0			0			0		 P180		0			0		  0			0			0
-- Rx			0			0		  0			0			0			0			0		  0			0			0		 ACQ		0			0
-- Gx			0			0		  0			50			50			0			0		  0			0			50		  50		0			0
-- Gy 			0			0		  0	 	  -128*i	  -128*i 		0			0		  0 		0			0		  0			0			0
-- Gz			0		   100		 100	  -100		  -100			0			0		  0			0			0		  0			0			0


	-- Rev 2.1 
		write_general_setting_data_prod
		(
			to_unsigned(14,C_DATA_WIDTH), 	--nr_sections
			to_unsigned(4,C_DATA_WIDTH), 	--start_repeat_pointer
			to_unsigned(12,C_DATA_WIDTH), 	--end_repeat_pointer
			to_unsigned(50,C_DATA_WIDTH),	--cycle_repetition_number
			to_unsigned(1,C_DATA_WIDTH),	--experiment_repetition_number
			to_unsigned(0,C_DATA_WIDTH),	--gradient_x_sweep_step
			to_unsigned(80,C_DATA_WIDTH),	--gradient_y_sweep_step
			to_unsigned(0,C_DATA_WIDTH)	--gradient_z_sweep_step
		);

		-- section 0:
		write_section_data_prod
		(
			to_unsigned(0,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(100,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(0,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 1: P90 pulse 
		write_section_data_prod
		(
			to_unsigned(1,C_DATA_WIDTH),		-- section id
			to_unsigned(0,C_DATA_WIDTH),		-- section type
			to_unsigned(90,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 2: Pre-Gfe_Prephase, push Gx to 4095 and Gx_ref to 0
		write_section_data_prod
		(
			to_unsigned(2,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(4095,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(0,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 3: Gfe_Prephase, same as Pre-Gfe_Prephase section, duration 10000
		-- Gx remain 4095, Gx_ref remain 0
		write_section_data_prod
		(
			to_unsigned(3,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(10000,C_DATA_WIDTH),	-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(4095,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 4: Post-Gfe_Prephase, turn off Gx, set Gx_sig and Gx_ref to middle value 2000
		write_section_data_prod
		(
			to_unsigned(4,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 5: P180 pulse, hell yeah.
		write_section_data_prod
		(
			to_unsigned(5,C_DATA_WIDTH),		-- section id
			to_unsigned(0,C_DATA_WIDTH),		-- section type
			to_unsigned(180,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 6: Pre-Gpe_pos, positive sweep on Gy = 0x000100 = 4, could be cancelled,
		-- so that the cute proton spins could have some fun free precession time.
		-- Gy_sig = 0 (by default), Gy_ref = Gy_offset = 0 
		write_section_data_prod
		(
			to_unsigned(6,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(4000,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(8,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 7: Gpe_pos, positive sweep on Gy = 0x000100 = 4
		write_section_data_prod
		(
			to_unsigned(7,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(4000,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(4000,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(8,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 8: Post-Gpe_pos, Pre-Gfe_readout, turn off Gy, set Gy_sig and Gy_ref to middle value 2000.
		-- Push Gx to maximum 4095 for readout, Gx_ref to 0
		write_section_data_prod
		(
			to_unsigned(8,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(1,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(4095,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(0,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);


		-- section 9: RX and Gfe_readout, duation 20000. Gx same as previous section
		-- Gx_sig remain 4095, Gx_ref remain 0
				write_section_data_prod
		(
			to_unsigned(9,C_DATA_WIDTH),		-- section id
			to_unsigned(1,C_DATA_WIDTH),		-- section type
			to_unsigned(20000,C_DATA_WIDTH),		-- duration
			to_unsigned(1,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(4095,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(0,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 10: Post-Gfe_readout and Pre-Gpe_neg, turn off Gx, set Gx_sig and Gx_ref to middle value 2000
		-- negative sweep on Gy = 0x001100 = 4 + 8 = 12, duration 50 for settling.
		-- Gy_offset = Gy_ref = 4095, Gy_sig = 0 (by default)
		-- 4095 - step * step_size, where step_size is always positive
		write_section_data_prod
		(
			to_unsigned(10,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(4,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 11: Gpe_neg. Duration should be exactly same as Gpe_pos, 4000.
		-- negative sweep on Gy = 0x001100 = 4 + 8 = 12, duration 50 for settling.
		-- Gy_offset = Gy_ref = 4095, Gy_sig = 0 (by default)
		-- 4095 - step * step_size, where step_size is always positive
		write_section_data_prod
		(
			to_unsigned(11,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(4000,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(4,C_DATA_WIDTH)		    -- gradient sweep command
		);

		-- section 12: Inter-cycle delay. 
		-- set to 2000 to distinguish from other delays. Needs to be physically reasonable.
		write_section_data_prod
		(
			to_unsigned(12,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(2000,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);

		-- section 13:
		-- section end delay, set to 50, where the TR is controlled by high-level sequence controller in Python
		write_section_data_prod
		(
			to_unsigned(13,C_DATA_WIDTH),		-- section id
			to_unsigned(2,C_DATA_WIDTH),		-- section type
			to_unsigned(50,C_DATA_WIDTH),		-- duration
			to_unsigned(0,C_DATA_WIDTH),		-- mux
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch0
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch0	
			to_unsigned(0,C_DATA_WIDTH),		-- phase ch1
			to_unsigned(1,C_DATA_WIDTH),		-- frequency ch1
			to_unsigned(1,C_DATA_WIDTH),		-- resetn dds
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_x_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_sig
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_sig
			to_unsigned(2000,C_DATA_WIDTH),	    -- gradient_x_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_y_ref
			to_unsigned(2000,C_DATA_WIDTH),		-- gradient_z_ref	
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_x_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_y_offset
			to_unsigned(0,C_DATA_WIDTH),		-- gradient_z_offset
			to_unsigned(0,C_DATA_WIDTH)		-- gradient sweep command
		);


			 WAIT FOR 2*clk_period;
				i_en <= '1'; -- BEGIN 				 
			 
			 WAIT FOR 10*1000000*clk_period;
			
			 ASSERT false
			 REPORT "Simulation finished"
			 SEVERITY failure;
	 END PROCESS;
	
end Behavioral;
