----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2022/05/28 15:02:47
-- Design Name: 
-- Module Name: fpga_pulse_gen_cu - Behavioral
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
-- v_1.0 change the frequency and phase for xilinx dds
-- section type 
-- 0: Tx
-- 1: Rx
-- 2: Delay
-- gradient control risko@! BRAM
----------------------------------------------------------------------------------


-- ! Use standard library ieee
library IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;

-- ! Use library fpga_pulse_gen_pkg
USE work.fpga_pulse_gen_pkg.ALL;


entity fpga_pulse_gen_cu is
    Port 
	(
--		axi clock	
		clk 								: IN  std_logic;
--		tx pulse		
		o_tx_pulse							: OUT std_logic; 	
--		rx pulse		
		o_rx_pulse							: OUT std_logic;
--		config data for axis stream interface for dds channel 0		
		ov_config_dds_data_ch0				: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output
--		valid signal to axis stream interface for dds channel 0			
		o_config_tvalid_ch0					: OUT std_logic; 	
--		config data for axis stream interface for dds channel 1
		ov_config_dds_data_ch1				: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output	
--		valid signal to axis stream interface for dds channel 1	
		o_config_tvalid_ch1					: OUT std_logic;	
--		mux control signal to select the dds output 
		o_mux_ch							: OUT std_logic;
--		register interface user block rising_edge enable	
		i_en								: IN  std_logic;
-- 		memory enable if high write data		
		o_mem_wr_en							: OUT std_logic;		
--		total number of sections for the experiment 		
		iv_set_nr_sections					: IN  unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- set number of sections	
--		select section pointer to read the configuration data from RAM		
		ov_sel_section						: OUT unsigned(C_DATA_WIDTH - 1 DOWNTO 0); -- select the number of to config		
--		restn by the configuration state reset the counters		
		o_rstn								: OUT std_logic; 	
--		chose the sections type 0 TX 1 RX 2 delay		
		iv_section_type						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0); 	
--		the duration for delay section (by the delay section, the phase and frequency can be configed)		
		iv_set_delay						: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
--		the lsb control the mux 
		iv_set_mux							: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
--		the data for phase channel 0		
		iv_set_phase_ch0					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
--		the data for frequency channel 0		
		iv_set_frequency_ch0				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
-- 		the data for phase channel 1		
		iv_set_phase_ch1					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
--		the data for frequency channel 1		
		iv_set_frequency_ch1				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
-- 		user control resetn from register interface
		iv_set_resetn_dds					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		
		o_dds_rstn							: OUT std_logic;
-- 		counters control 
--		timer pulse load enable <pulse>	
		o_timer_load_en						: OUT std_logic;
		o_timer_en							: OUT std_logic;
--		timer data
		i_timer_pre_done					: IN  std_logic;	
		ov_timer_data						: OUT unsigned(C_DATA_WIDTH - 1 DOWNTO 0);		
--		timer done		
		i_timer_done						: IN  std_logic;
--		cycling repetition enable <pulse>		
		o_cycle_repetition_en				: OUT std_logic;
		o_cycle_repetition_load_en			: OUT std_logic;	

		i_cycle_repetition_done				: IN  std_logic;
		o_experiment_repetition_en			: OUT std_logic;
		o_experiment_repetition_load_en		: OUT std_logic;
		iv_experiment_last_nr				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);	
		ov_experiment_repetition_data		: OUT unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		i_experiment_repetition_done		: IN  std_logic;
		-- repetition contol
		iv_set_start_repeat_pointer			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_end_repeat_pointer 			: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		i_pre_cycle_repetition_done			: IN  std_logic;
		o_busy								: OUT std_logic;
		o_data_ready						: OUT std_logic;
		-- gradient control
		iv_repetition_gradient_sweep_number : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z					: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_ref				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_ref				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_ref				: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_offset		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_offset		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_offset		: IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);		
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
end fpga_pulse_gen_cu;

architecture Behavioral of fpga_pulse_gen_cu is
	
	TYPE state_t IS
	(
		conf_s,
		pre_repetition_s,
		repetition_s,
		last_s
	);
	
	SIGNAL
	state
	: state_t := conf_s; -- config state
	
	SIGNAL

	d1_resetn_dds,
	resetn_dds,
	section_type
	:unsigned(C_DATA_WIDTH - 1 DOWNTO 0):= (others => '0');
	
	SIGNAL
	frequency_ch0,
	frequency_ch1,	
	phase_ch0,
	phase_ch1
	:std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0):= (others => '0'); 

	SIGNAL
	config_dds_data_ch0,
	config_dds_data_ch1				
	:std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0):= (others => '0'); 
		
	SIGNAL
	nr_sections,	
	start_repeat_pointer,
	end_repeat_pointer,	
	sel_section
	: integer := 0;
	
	SIGNAL
	d1_set_gradient_x,
	d2_set_gradient_x,
	d1_set_gradient_y,
	d2_set_gradient_y,
	d1_set_gradient_z,
	d2_set_gradient_z	
	: std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0):= (others => '0'); 
	
	SIGNAL
	tx_pulse,
	rx_pulse,	
	config_tvalid_ch0,
	config_tvalid_ch1,
	gradient_tvalid,
	d1_config_tvalid_ch0,
	d1_config_tvalid_ch1,
	d1_gradient_tvalid,	
	mem_wr_en,
	d1_mux_ch,
	mux_ch,
	d1_en,
	d1_pre_cycle_repetition_done,
	busy_i,
	data_ready_i
	: std_logic := '0';
	

begin

--  the state machine process


	o_cycle_repetition_en 		<= '1' WHEN (i_timer_pre_done = '1') AND (i_en = '1') AND (sel_section = end_repeat_pointer)   ELSE '0';

	o_experiment_repetition_en 	<= '1' WHEN (sel_section = nr_sections - 1) AND 
										   (i_timer_done = '1') AND
								           (i_cycle_repetition_done = '1' ) AND (i_en = '1') ELSE '0';
	
	ov_timer_data 						<= iv_set_delay;
	
	ctrl_proc : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			d1_en 								<= i_en;		
			d1_resetn_dds 						<= resetn_dds;	
			d1_mux_ch							<= mux_ch;
			d1_pre_cycle_repetition_done		<= i_pre_cycle_repetition_done;
			o_cycle_repetition_load_en 			<= '0';
			o_experiment_repetition_load_en 	<= '0';	
			config_tvalid_ch0 					<= '0';
			config_tvalid_ch1 					<= '0';
			gradient_tvalid						<= '0';			
			d1_config_tvalid_ch0 				<= config_tvalid_ch0;			
			d1_config_tvalid_ch1 				<= config_tvalid_ch1;
			d1_gradient_tvalid					<= gradient_tvalid;
			section_type 						<= iv_section_type;
			o_timer_load_en 					<= '0';
			
			IF (i_en = '0')THEN
				state 			<= conf_s;			
				o_timer_en 		<= '0';				
				mem_wr_en  		<= '1';
				o_rstn 			<= '0';	
				resetn_dds(0) 	<= '0';
				
			ELSE
				mem_wr_en		<= '0';
				o_rstn 			<= '1';
				
				CASE(state) IS
				
					WHEN conf_s =>
						o_timer_en 				<= '0';	
						sel_section		 	 	<= 0;						
						o_busy				 	<= '0';
						o_data_ready			<= '0';
						resetn_dds(0) 		 	<= '0';							
						mux_ch	 			 	<= '0';							
						IF d1_en = '0' AND i_en = '1' THEN 
						--  load the data by rising edge the i_en
							o_timer_load_en 				<= '1';							
							state 							<=  pre_repetition_s ;
							o_cycle_repetition_load_en 		<= '1';
							o_experiment_repetition_load_en <= '1';
							nr_sections					 	<= to_integer(iv_set_nr_sections);										
							start_repeat_pointer			<= to_integer(iv_set_start_repeat_pointer);
							end_repeat_pointer 	 			<= to_integer(iv_set_end_repeat_pointer);
							resetn_dds						<= iv_set_resetn_dds;						
						ELSE
								state <=  conf_s ;
						END IF;
						
					WHEN pre_repetition_s =>
							
							o_timer_en <= '1';	
							
							IF i_timer_pre_done = '1' THEN
								sel_section 				<= sel_section + 1;
								o_timer_load_en 			<= '1';
							ELSE
								sel_section 				<= sel_section;
								o_timer_load_en 			<= '0';
							END IF;
							IF i_timer_done = '1'  THEN

									mux_ch	 					<= iv_set_mux(0);							
									resetn_dds					<= iv_set_resetn_dds;								
									config_tvalid_ch0 			<= '1';
									config_tvalid_ch1 			<= '1';														
									gradient_tvalid				<= '1';
								IF (sel_section < start_repeat_pointer - 1) THEN						
									state 		<= pre_repetition_s;
								ELSE
									state 		<= repetition_s;
								END IF;	

							ELSE
									state <= pre_repetition_s;
			
							END IF;
							
					WHEN repetition_s =>
					
							o_timer_en <= '1';
							-- sel_section 
							IF (d1_pre_cycle_repetition_done = '1') AND (i_cycle_repetition_done= '1')  THEN
								sel_section 	<= end_repeat_pointer + 1;
							ELSE	
								IF i_timer_pre_done = '1'  THEN
									IF (sel_section < end_repeat_pointer) THEN
										sel_section 	<= sel_section + 1;
									ELSIF (i_pre_cycle_repetition_done = '0') THEN 
										sel_section 	<= start_repeat_pointer;
									END IF;
								ELSE
									sel_section 	<= sel_section;
								END IF;
							END IF;

							-- state
							IF (i_pre_cycle_repetition_done = '1') THEN
								sel_section 	<= sel_section + 1;							
								state 			<= last_s;
							ELSE
								state 			<= repetition_s;
							END IF;
							--Output signal
							IF i_timer_done = '1' THEN
								mux_ch	 						<= iv_set_mux(0);							
								resetn_dds						<= iv_set_resetn_dds;							
								config_tvalid_ch0 				<= '1';
								config_tvalid_ch1 				<= '1';
								gradient_tvalid					<= '1';
							END IF;
							
					WHEN last_s =>	
						
						o_timer_en <= '1';
							--Output signal
						IF i_timer_done = '1' THEN
							mux_ch	 						<= iv_set_mux(0);							
							resetn_dds						<= iv_set_resetn_dds;							
							config_tvalid_ch0 				<= '1';
							config_tvalid_ch1 				<= '1';
							gradient_tvalid					<= '1';
						END IF;
							
						IF i_timer_pre_done = '1' THEN
								
							IF (sel_section < nr_sections - 1) THEN
								sel_section 	<= sel_section + 1;
								state 			<= last_s;
							ELSE
								IF iv_experiment_last_nr < 1 AND (sel_section = nr_sections - 1) AND (i_cycle_repetition_done = '1' ) THEN
									state <= conf_s;
									o_timer_en <= '0';
									sel_section <= 0;
									resetn_dds(0) <= '0';
									d1_resetn_dds(0) <= '0';
								ELSE
									o_cycle_repetition_load_en <= '1';		
									sel_section <= 0;
									state <= pre_repetition_s;
								END IF;
							END IF; 	
						ELSE							
									state 		<= last_s;	
						END IF;
				END CASE;
			END IF;
		END IF;
	END PROCESS;

-- load the data	
	reload_timer_proc: PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN			
			phase_ch0 						<= std_logic_vector(iv_set_phase_ch0);
			phase_ch1 						<= std_logic_vector(iv_set_phase_ch1);
			frequency_ch0 					<= std_logic_vector(iv_set_frequency_ch0);
			frequency_ch1 					<= std_logic_vector(iv_set_frequency_ch1);
			config_dds_data_ch0				<= phase_ch0 & frequency_ch0;
			config_dds_data_ch1				<= phase_ch1 & frequency_ch1;
		END IF;
	END PROCESS;

-- load the data for dds	
	reload_dds_proc: PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			tx_pulse <= '0';
			rx_pulse <= '0';
			IF d1_en = '1' THEN
			
				CASE(to_integer(section_type)) IS
					WHEN C_STYPE_TX =>
					
						tx_pulse <= '1';
						rx_pulse <= '0';
						
					WHEN C_STYPE_RX =>
					
						tx_pulse <= '0';					
						rx_pulse <= '1';
						
					WHEN OTHERS =>
						tx_pulse <= '0';
						rx_pulse <= '0';
				END CASE;
			ELSE
				tx_pulse <= '0';
				rx_pulse <= '0';				
			END IF;	
		END IF;
	END PROCESS;

-- OUTPUT

-- Gradient control
	-- gradient control process
	-- gradient_sweep 	0  x: off y: off z: off
	--					1  x: on  y: off z: off
	--					2  x: off y: on  z: off
	--					3  x: on  y: on  z: off
	-- @ function  		y = kx + b linear fuction
	-- 						y control DAC digital output
	--						k sweep_step
	--						x repetition number
	--						 y
	--					     |  / y = kx + b 
	--						 | /
	--						 |/
	--						 |------ b  B0z = 0 
	--						/|
	--					   / |
	--					-----*--------->x
	--					 /   |0
	--						 |
	Gradient_control_x: process(clk)
	BEGIN
		IF rising_edge (clk) THEN
			IF (iv_set_gradient_sweep(0) = '1') then
				d1_set_gradient_x <=   	std_logic_vector(to_unsigned(to_integer(iv_set_gradient_x_sweep_step) * to_integer(iv_repetition_gradient_sweep_number),C_DATA_WIDTH) + iv_set_gradient_x_sweep_offset);
				d2_set_gradient_x <=   	std_logic_vector(unsigned(d1_set_gradient_x));
			ELSE
				d1_set_gradient_x <= 	std_logic_vector(iv_set_gradient_x);
				d2_set_gradient_x <= 	std_logic_vector(d1_set_gradient_x);	
			END IF;
		END IF;
	END PROCESS;
	
	Gradient_control_y: process(clk)
	BEGIN
		IF rising_edge (clk) THEN
			IF (iv_set_gradient_sweep(1) = '1') then
				d1_set_gradient_y <=   	std_logic_vector(to_unsigned(to_integer(iv_set_gradient_y_sweep_step) * to_integer(iv_repetition_gradient_sweep_number),C_DATA_WIDTH)+ iv_set_gradient_y_sweep_offset);
				d2_set_gradient_y <=   	std_logic_vector(unsigned(d1_set_gradient_y));
			ELSE
				d1_set_gradient_y <= 	std_logic_vector(iv_set_gradient_y);
				d2_set_gradient_y <= 	std_logic_vector(d1_set_gradient_y);	
			END IF;
		END IF;
	END PROCESS;

	Gradient_control_z: process(clk)
	BEGIN
		IF rising_edge (clk) THEN
			IF (iv_set_gradient_sweep(2) = '1') then
				d1_set_gradient_z <=   	std_logic_vector(to_unsigned(to_integer(iv_set_gradient_z_sweep_step) * to_integer(iv_repetition_gradient_sweep_number),C_DATA_WIDTH)+ iv_set_gradient_z_sweep_offset);
				d2_set_gradient_z <=   	std_logic_vector(unsigned(d1_set_gradient_z));
			ELSE
				d1_set_gradient_z <= 	std_logic_vector(iv_set_gradient_z);
				d2_set_gradient_z <= 	std_logic_vector(d1_set_gradient_z);	
			END IF;
		END IF;
	END PROCESS;
	
-- DDS
	o_tx_pulse					<=	tx_pulse;	
	o_rx_pulse					<=	rx_pulse;
	o_config_tvalid_ch0		 	<= 	d1_config_tvalid_ch0;
	o_config_tvalid_ch1 		<= 	d1_config_tvalid_ch1;
	ov_config_dds_data_ch0		<=  config_dds_data_ch0;
	ov_config_dds_data_ch1		<=  config_dds_data_ch1;
	o_dds_rstn					<=  '1' WHEN d1_resetn_dds(0) = '1' ELSE '0';
	o_mux_ch					<=  d1_mux_ch;
	o_mem_wr_en					<= 	mem_wr_en;
	ov_sel_section				<=  to_unsigned(sel_section,ov_sel_section'length);

-- gradient control
	ov_set_gradient_x			<= d2_set_gradient_x;
	ov_set_gradient_y			<= d2_set_gradient_y;
	ov_set_gradient_z			<= d2_set_gradient_z;	
-- gradient control reference
	ov_set_gradient_x_ref 		<= std_logic_vector(iv_set_gradient_x_ref);
	ov_set_gradient_y_ref 		<= std_logic_vector(iv_set_gradient_y_ref);
	ov_set_gradient_z_ref 		<= std_logic_vector(iv_set_gradient_z_ref);
	
	o_gradient_tvalid			<= d1_gradient_tvalid;
					
end Behavioral;