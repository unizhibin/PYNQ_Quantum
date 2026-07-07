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
		iv_prefetch_section_0			: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_prefetch_section_1			: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_prefetch_section_2			: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_readback_sel_section			: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		iv_readback_word_index			: IN   unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		o_prefetch_ready				: OUT  std_logic;
		
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
		ov_set_gradient_sweep			: OUT 	unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_readback_word_data			: OUT 	std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0)
        );
end fpga_pulse_mem;

architecture Behavioral of fpga_pulse_mem is
	CONSTANT C_SECTION_WIDTH : integer := C_DATA_WIDTH * C_NR_ACTIVITY;
	CONSTANT C_SECTION_DEPTH : integer := 2**C_MEM_ADDR_WIDTH;

	SUBTYPE t_section_data IS std_logic_vector(C_SECTION_WIDTH - 1 DOWNTO 0);
	TYPE t_section_ram IS ARRAY (0 TO C_SECTION_DEPTH - 1) OF t_section_data;
	TYPE t_prefetch_data IS ARRAY (0 TO C_PREFETCH_SECTIONS - 1) OF t_section_data;
	TYPE t_prefetch_addr IS ARRAY (0 TO C_PREFETCH_SECTIONS - 1) OF unsigned(C_DATA_WIDTH - 1 DOWNTO 0);

	FUNCTION f_init_ram
		RETURN t_section_ram
	IS
		VARIABLE v_init_data : t_section_ram;
	BEGIN
		FOR i IN 0 TO C_SECTION_DEPTH - 1 LOOP
			v_init_data(i) := (OTHERS => '0');
		END LOOP;

		RETURN v_init_data;
	END f_init_ram;

	FUNCTION f_section_index
	(
		CONSTANT section_addr : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
	)
		RETURN integer
	IS
	BEGIN
		RETURN to_integer(section_addr(C_MEM_ADDR_WIDTH - 1 DOWNTO 0));
	END f_section_index;

	FUNCTION f_get_word
	(
		CONSTANT section_data : IN t_section_data;
		CONSTANT word_index   : IN integer
	)
		RETURN std_logic_vector
	IS
	BEGIN
		RETURN section_data((word_index + 1) * C_DATA_WIDTH - 1 DOWNTO word_index * C_DATA_WIDTH);
	END f_get_word;

	FUNCTION f_word_index
	(
		CONSTANT word_addr : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
	)
		RETURN integer
	IS
		VARIABLE v_index : integer := 0;
	BEGIN
		v_index := to_integer(word_addr(4 DOWNTO 0));
		IF v_index >= C_NR_ACTIVITY THEN
			RETURN 0;
		END IF;

		RETURN v_index;
	END f_word_index;

	FUNCTION f_pack_section
	(
		CONSTANT section_type             : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT delay                    : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT mux                      : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT phase_ch0                : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT frequency_ch0            : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT phase_ch1                : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT frequency_ch1            : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT resetn_dds               : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_x               : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_y               : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_z               : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_x_ref           : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_y_ref           : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_z_ref           : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_x_sweep_offset  : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_y_sweep_offset  : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_z_sweep_offset  : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0);
		CONSTANT gradient_sweep           : IN unsigned(C_DATA_WIDTH - 1 DOWNTO 0)
	)
		RETURN t_section_data
	IS
		VARIABLE v_section : t_section_data := (OTHERS => '0');
	BEGIN
		v_section((C_SECTION_TYPE + 1) * C_DATA_WIDTH - 1 DOWNTO C_SECTION_TYPE * C_DATA_WIDTH) := std_logic_vector(section_type);
		v_section((C_DELAY + 1) * C_DATA_WIDTH - 1 DOWNTO C_DELAY * C_DATA_WIDTH) := std_logic_vector(delay);
		v_section((C_SET_MUX + 1) * C_DATA_WIDTH - 1 DOWNTO C_SET_MUX * C_DATA_WIDTH) := std_logic_vector(mux);
		v_section((C_PHASE_OFFSET_CH0 + 1) * C_DATA_WIDTH - 1 DOWNTO C_PHASE_OFFSET_CH0 * C_DATA_WIDTH) := std_logic_vector(phase_ch0);
		v_section((C_FREQUENCY_OFFSET_CH0 + 1) * C_DATA_WIDTH - 1 DOWNTO C_FREQUENCY_OFFSET_CH0 * C_DATA_WIDTH) := std_logic_vector(frequency_ch0);
		v_section((C_PHASE_OFFSET_CH1 + 1) * C_DATA_WIDTH - 1 DOWNTO C_PHASE_OFFSET_CH1 * C_DATA_WIDTH) := std_logic_vector(phase_ch1);
		v_section((C_FREQUENCY_OFFSET_CH1 + 1) * C_DATA_WIDTH - 1 DOWNTO C_FREQUENCY_OFFSET_CH1 * C_DATA_WIDTH) := std_logic_vector(frequency_ch1);
		v_section((C_DDS_RESETN + 1) * C_DATA_WIDTH - 1 DOWNTO C_DDS_RESETN * C_DATA_WIDTH) := std_logic_vector(resetn_dds);
		v_section((C_X_GRADIENT + 1) * C_DATA_WIDTH - 1 DOWNTO C_X_GRADIENT * C_DATA_WIDTH) := std_logic_vector(gradient_x);
		v_section((C_Y_GRADIENT + 1) * C_DATA_WIDTH - 1 DOWNTO C_Y_GRADIENT * C_DATA_WIDTH) := std_logic_vector(gradient_y);
		v_section((C_Z_GRADIENT + 1) * C_DATA_WIDTH - 1 DOWNTO C_Z_GRADIENT * C_DATA_WIDTH) := std_logic_vector(gradient_z);
		v_section((C_X_GRADIENT_REF + 1) * C_DATA_WIDTH - 1 DOWNTO C_X_GRADIENT_REF * C_DATA_WIDTH) := std_logic_vector(gradient_x_ref);
		v_section((C_Y_GRADIENT_REF + 1) * C_DATA_WIDTH - 1 DOWNTO C_Y_GRADIENT_REF * C_DATA_WIDTH) := std_logic_vector(gradient_y_ref);
		v_section((C_Z_GRADIENT_REF + 1) * C_DATA_WIDTH - 1 DOWNTO C_Z_GRADIENT_REF * C_DATA_WIDTH) := std_logic_vector(gradient_z_ref);
		v_section((C_X_GRADIENT_OFFSET + 1) * C_DATA_WIDTH - 1 DOWNTO C_X_GRADIENT_OFFSET * C_DATA_WIDTH) := std_logic_vector(gradient_x_sweep_offset);
		v_section((C_Y_GRADIENT_OFFSET + 1) * C_DATA_WIDTH - 1 DOWNTO C_Y_GRADIENT_OFFSET * C_DATA_WIDTH) := std_logic_vector(gradient_y_sweep_offset);
		v_section((C_Z_GRADIENT_OFFSET + 1) * C_DATA_WIDTH - 1 DOWNTO C_Z_GRADIENT_OFFSET * C_DATA_WIDTH) := std_logic_vector(gradient_z_sweep_offset);
		v_section((C_GRADIENT_SWEEP + 1) * C_DATA_WIDTH - 1 DOWNTO C_GRADIENT_SWEEP * C_DATA_WIDTH) := std_logic_vector(gradient_sweep);

		RETURN v_section;
	END f_pack_section;

	SIGNAL ram : t_section_ram := f_init_ram;
	ATTRIBUTE ram_style : string;
	ATTRIBUTE ram_style OF ram : SIGNAL IS "distributed";

	SIGNAL prefetch_data  : t_prefetch_data := (OTHERS => (OTHERS => '0'));
	SIGNAL prefetch_addr  : t_prefetch_addr := (OTHERS => (OTHERS => '0'));
	SIGNAL prefetch_valid : std_logic_vector(C_PREFETCH_SECTIONS - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL prefetch_slot  : integer RANGE 0 TO C_PREFETCH_SECTIONS - 1 := 0;
	SIGNAL section_out    : t_section_data := (OTHERS => '0');
	SIGNAL readback_word_data : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL prefetch_ready : std_logic := '0';

BEGIN
-- LUTRAM-backed section table with a small three-section prefetch window.
    proc_ram : PROCESS (clk)
		VARIABLE v_desired_addr : t_prefetch_addr;
		VARIABLE v_slot         : integer RANGE 0 TO C_PREFETCH_SECTIONS - 1;
    BEGIN
        IF rising_edge(clk) THEN
			v_desired_addr(0) := iv_prefetch_section_0;
			v_desired_addr(1) := iv_prefetch_section_1;
			v_desired_addr(2) := iv_prefetch_section_2;
			readback_word_data <= f_get_word
			(
				ram(f_section_index(iv_readback_sel_section)),
				f_word_index(iv_readback_word_index)
			);

            IF (i_wr_en = '1') THEN
                ram(f_section_index(iv_write_sel_section)) <= f_pack_section
				(
					iv_set_section_type,
					iv_set_delay,
					iv_set_mux,
					iv_set_phase_ch0,
					iv_set_frequency_ch0,
					iv_set_phase_ch1,
					iv_set_frequency_ch1,
					iv_set_resetn_dds,
					iv_set_gradient_x,
					iv_set_gradient_y,
					iv_set_gradient_z,
					iv_set_gradient_x_ref,
					iv_set_gradient_y_ref,
					iv_set_gradient_z_ref,
					iv_set_gradient_x_sweep_offset,
					iv_set_gradient_y_sweep_offset,
					iv_set_gradient_z_sweep_offset,
					iv_set_gradient_sweep
				);
				prefetch_valid <= (OTHERS => '0');
				prefetch_slot  <= 0;
		    ELSE
				v_slot := prefetch_slot;
				IF (prefetch_valid(v_slot) = '0') OR (prefetch_addr(v_slot) /= v_desired_addr(v_slot)) THEN
					prefetch_data(v_slot)  <= ram(f_section_index(v_desired_addr(v_slot)));
					prefetch_addr(v_slot)  <= v_desired_addr(v_slot);
					prefetch_valid(v_slot) <= '1';
				END IF;

				IF prefetch_slot = C_PREFETCH_SECTIONS - 1 THEN
					prefetch_slot <= 0;
				ELSE
					prefetch_slot <= prefetch_slot + 1;
				END IF;

		   END IF;
	   END IF;
    END PROCESS;

	-- Active section fields use the LUTRAM read path directly. The timer samples
	-- these fields one clock after the CU updates iv_read_sel_section.
	section_out <= ram(f_section_index(iv_read_sel_section));

	prefetch_ready <= '1' WHEN
		(prefetch_valid(0) = '1') AND (prefetch_addr(0) = iv_prefetch_section_0) AND
		(prefetch_valid(1) = '1') AND (prefetch_addr(1) = iv_prefetch_section_1) AND
		(prefetch_valid(2) = '1') AND (prefetch_addr(2) = iv_prefetch_section_2)
	ELSE '0';

	o_prefetch_ready				<= prefetch_ready;
	ov_section_type					<= unsigned(f_get_word(section_out, C_SECTION_TYPE));
	ov_set_delay					<= unsigned(f_get_word(section_out, C_DELAY));
	ov_set_mux						<= unsigned(f_get_word(section_out, C_SET_MUX));
	ov_set_phase_ch0				<= unsigned(f_get_word(section_out, C_PHASE_OFFSET_CH0));
	ov_set_frequency_ch0			<= unsigned(f_get_word(section_out, C_FREQUENCY_OFFSET_CH0));
	ov_set_phase_ch1				<= unsigned(f_get_word(section_out, C_PHASE_OFFSET_CH1));
	ov_set_frequency_ch1			<= unsigned(f_get_word(section_out, C_FREQUENCY_OFFSET_CH1));
	ov_set_resetn_dds				<= unsigned(f_get_word(section_out, C_DDS_RESETN));
	ov_set_gradient_x				<= unsigned(f_get_word(section_out, C_X_GRADIENT));
	ov_set_gradient_y				<= unsigned(f_get_word(section_out, C_Y_GRADIENT));
	ov_set_gradient_z				<= unsigned(f_get_word(section_out, C_Z_GRADIENT));
	ov_set_gradient_x_ref			<= unsigned(f_get_word(section_out, C_X_GRADIENT_REF));
	ov_set_gradient_y_ref			<= unsigned(f_get_word(section_out, C_Y_GRADIENT_REF));
	ov_set_gradient_z_ref			<= unsigned(f_get_word(section_out, C_Z_GRADIENT_REF));
	ov_set_gradient_x_sweep_offset	<= unsigned(f_get_word(section_out, C_X_GRADIENT_OFFSET));
	ov_set_gradient_y_sweep_offset	<= unsigned(f_get_word(section_out, C_Y_GRADIENT_OFFSET));
	ov_set_gradient_z_sweep_offset	<= unsigned(f_get_word(section_out, C_Z_GRADIENT_OFFSET));	
	ov_set_gradient_sweep			<= unsigned(f_get_word(section_out, C_GRADIENT_SWEEP));
	ov_readback_word_data			<= readback_word_data;
	end Behavioral;
