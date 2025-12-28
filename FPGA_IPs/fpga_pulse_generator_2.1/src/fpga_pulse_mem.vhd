----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 18.06.2022 08:59:20
-- Design Name: 
-- Module Name: fpga_pulse_mem - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- version 2.0 add gradient control
----------------------------------------------------------------------------------

-- ! Use standard library ieee
library IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

-- ! Use library fpga_pulse_gen_pkg
USE work.fpga_pulse_gen_pkg.ALL;

entity fpga_pulse_mem is
    PORT (
        clk        						: IN  std_logic;
        i_wr_en    						: IN  std_logic;
		iv_write_sel_section			: IN  unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		
		iv_set_section_type				: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_delay					: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);		
		iv_set_mux						: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_phase_ch0				: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_frequency_ch0			: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_phase_ch1				: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_frequency_ch1			: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_resetn_dds				: IN  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x				: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y				: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z				: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_ref			: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_ref			: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_ref			: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_x_sweep_offset	: IN	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_y_sweep_offset	: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_z_sweep_offset	: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		iv_set_gradient_sweep			: IN 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);		

		iv_read_sel_section				: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		
		ov_section_type					: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_delay					: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);	
		ov_set_mux						: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_phase_ch0				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_frequency_ch0			: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_phase_ch1				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_frequency_ch1			: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_resetn_dds				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_x				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z				: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);		
		ov_set_gradient_x_ref			: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y_ref			: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z_ref			: OUT  	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_x_sweep_offset	: OUT	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_y_sweep_offset	: OUT 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		ov_set_gradient_z_sweep_offset	: OUT 	unsigned(C_DATA_WIDTH - 1 DOWNTO 0);		
		ov_set_gradient_sweep			: OUT 	unsigned (C_DATA_WIDTH - 1 DOWNTO 0)
        );
end fpga_pulse_mem;

architecture Behavioral of fpga_pulse_mem is
 TYPE t_ram IS ARRAY (2**C_MEM_ADDR_WIDTH - 1 DOWNTO 0) OF std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);

    FUNCTION f_init_mem
        RETURN t_ram
    IS
        VARIABLE
            v_init_data
            : t_ram;
    BEGIN
        FOR i IN 0 TO 2**C_MEM_ADDR_WIDTH - 1 LOOP
            v_init_data(i) := std_logic_vector(std_logic_vector(to_unsigned(0, v_init_data(i)'length)));
        END LOOP;

        RETURN v_init_data;
    END f_init_mem;

    SIGNAL
	-- signal ram of type t_ram, function f_init_mem is used to initialize the ram with all zeros
        ram  : t_ram := f_init_mem;
    SIGNAL
        set_section_type,
		set_delay,
		set_mux,
		set_phase_ch0,
		set_frequency_ch0,
		set_phase_ch1,
		set_frequency_ch1,
		set_resetn_dds,
		set_gradient_x,
		set_gradient_y,
		set_gradient_z,
		set_gradient_x_ref,
		set_gradient_y_ref,
		set_gradient_z_ref,
		set_gradient_x_sweep_offset,
		set_gradient_y_sweep_offset,
		set_gradient_z_sweep_offset,		
		set_gradient_sweep		
        : std_logic_vector (C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

BEGIN
-- RAM with seperate read and write address signals
    proc_ram : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (i_wr_en = '1') THEN
                ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_SECTION_TYPE) 				<= std_logic_vector(iv_set_section_type);
                ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_DELAY) 						<= std_logic_vector(iv_set_delay);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_SET_MUX) 					<= std_logic_vector(iv_set_mux);
                ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_PHASE_OFFSET_CH0) 			<= std_logic_vector(iv_set_phase_ch0);
                ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_FREQUENCY_OFFSET_CH0) 		<= std_logic_vector(iv_set_frequency_ch0);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_PHASE_OFFSET_CH1) 			<= std_logic_vector(iv_set_phase_ch1);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_FREQUENCY_OFFSET_CH1) 		<= std_logic_vector(iv_set_frequency_ch1);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_DDS_RESETN) 					<= std_logic_vector(iv_set_resetn_dds);
	--Version 2.0 add the  gradient control unit
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT) 					<= std_logic_vector(iv_set_gradient_x);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT) 					<= std_logic_vector(iv_set_gradient_y);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT) 					<= std_logic_vector(iv_set_gradient_z);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT_REF) 				<= std_logic_vector(iv_set_gradient_x_ref);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT_REF) 				<= std_logic_vector(iv_set_gradient_y_ref);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT_REF) 				<= std_logic_vector(iv_set_gradient_z_ref);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT_OFFSET) 			<= std_logic_vector(iv_set_gradient_x_sweep_offset);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT_OFFSET) 			<= std_logic_vector(iv_set_gradient_y_sweep_offset);
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT_OFFSET) 			<= std_logic_vector(iv_set_gradient_z_sweep_offset);				
				ram(to_integer(iv_write_sel_section)*C_NR_ACTIVITY + C_GRADIENT_SWEEP) 				<= std_logic_vector(iv_set_gradient_sweep);
				
		   END IF;
				set_section_type			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_SECTION_TYPE);
				set_delay					<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_DELAY);
				set_mux						<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_SET_MUX);
				set_phase_ch0				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_PHASE_OFFSET_CH0);
				set_frequency_ch0			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_FREQUENCY_OFFSET_CH0);
				set_phase_ch1				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_PHASE_OFFSET_CH1);
				set_frequency_ch1			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_FREQUENCY_OFFSET_CH1);			
				set_resetn_dds				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_DDS_RESETN);
				set_gradient_x				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT);
				set_gradient_y				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT);
				set_gradient_z				<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT);
				set_gradient_x_ref			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT_REF);
				set_gradient_y_ref			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT_REF);
				set_gradient_z_ref			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT_REF);
				set_gradient_x_sweep_offset <= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_X_GRADIENT_OFFSET);
				set_gradient_y_sweep_offset <= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Y_GRADIENT_OFFSET);
				set_gradient_z_sweep_offset <= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_Z_GRADIENT_OFFSET);				
				set_gradient_sweep			<= ram(to_integer(iv_read_sel_section)*C_NR_ACTIVITY + C_GRADIENT_SWEEP);
	   END IF;
    END PROCESS;
	ov_section_type					<=	unsigned(set_section_type);
	ov_set_delay					<=	unsigned(set_delay);
	ov_set_mux						<=	unsigned(set_mux);
	ov_set_phase_ch0				<=	unsigned(set_phase_ch0);
	ov_set_frequency_ch0			<=	unsigned(set_frequency_ch0);
	ov_set_phase_ch1				<=	unsigned(set_phase_ch1);
	ov_set_frequency_ch1			<=	unsigned(set_frequency_ch1);
	ov_set_resetn_dds				<=	unsigned(set_resetn_dds);
	ov_set_gradient_x				<=	unsigned(set_gradient_x);
	ov_set_gradient_y				<=	unsigned(set_gradient_y);
	ov_set_gradient_z				<=	unsigned(set_gradient_z);
	ov_set_gradient_x_ref			<=	unsigned(set_gradient_x_ref);
	ov_set_gradient_y_ref			<=	unsigned(set_gradient_y_ref);
	ov_set_gradient_z_ref			<=	unsigned(set_gradient_z_ref);
	ov_set_gradient_x_sweep_offset	<=	unsigned(set_gradient_x_sweep_offset);
	ov_set_gradient_y_sweep_offset	<=	unsigned(set_gradient_y_sweep_offset);
	ov_set_gradient_z_sweep_offset	<=	unsigned(set_gradient_z_sweep_offset);	
	ov_set_gradient_sweep			<=	unsigned(set_gradient_sweep);
	end Behavioral;
