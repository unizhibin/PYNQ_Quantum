----------------------------------------------------------------------------------
-- Company: University of Stuttgart (IIS)
-- Engineer: Codex / Yitian Chen
--
-- Module Name: fpga_pulse_gen_if_top_tb_w5_watergate_config - Behavioral
-- Description:
-- Self-checking testbench generated from:
--   W5_WATERGATE_PAPER_V3_PREFETCH.txt
--
-- This bench programs the latest pulse generator through the same register-style
-- interface used by the AXI-Lite software stack:
--   delay_us      -> integer(delay_us * 100) clocks at 100 MHz
--   phase_deg     -> integer(phase_deg * 536870912 / 180)
--   frequency_MHz -> integer(frequency_MHz * 21474836)
--
-- The sequence is the paper-derived double-gradient W5 WATERGATE sequence:
--   pre-delay, hard 90, g1, Delta1, W5, Delta1, g1, g2,
--   Delta2, W5, Delta2, g2, FID/RX.
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

USE work.fpga_pulse_gen_pkg.ALL;

ENTITY fpga_pulse_gen_if_top_tb_w5_watergate_config IS
END fpga_pulse_gen_if_top_tb_w5_watergate_config;

ARCHITECTURE Behavioral OF fpga_pulse_gen_if_top_tb_w5_watergate_config IS

	CONSTANT C_TB_NR_SECTIONS            : integer := 49;
	CONSTANT C_TB_REPEAT_START           : integer := 4;
	CONSTANT C_TB_REPEAT_END             : integer := 45;
	CONSTANT C_TB_CYCLE_REPETITIONS      : integer := 1;
	CONSTANT C_TB_EXPERIMENT_REPETITIONS : integer := 1;
	CONSTANT clk_period                  : time := 10 ns;

	CONSTANT C_TX_FREQ_WORD              : integer := 161015099;
	CONSTANT C_RX_FREQ_WORD              : integer := 160156105;
	CONSTANT C_PHASE_180_WORD            : integer := 536870912;
	CONSTANT C_GRAD_CENTER               : integer := 2000;

	TYPE t_section_int_array IS ARRAY (0 TO C_TB_NR_SECTIONS - 1) OF integer;
	TYPE t_expected_order IS ARRAY (natural RANGE <>) OF integer;

	CONSTANT C_SECTION_TYPE_VALUES : t_section_int_array :=
	(
		2, 0, 2, 2, 0, 2, 0, 2, 0, 2,
		0, 2, 0, 2, 0, 2, 0, 2, 0, 2,
		0, 2, 0, 2, 2, 2, 2, 0, 2, 0,
		2, 0, 2, 0, 2, 0, 2, 0, 2, 0,
		2, 0, 2, 0, 2, 0, 2, 2, 1
	);

	CONSTANT C_DELAY_VALUES : t_section_int_array :=
	(
		10000, 1000, 100000, 30000, 87, 33184, 206, 33021, 413, 32735,
		778, 32195, 1491, 31839, 1491, 32195, 778, 32735, 413, 33021,
		206, 33184, 87, 30000, 100000, 100000, 30000, 87, 33184, 206,
		33021, 413, 32735, 778, 32195, 1491, 31839, 1491, 32195, 778,
		32735, 413, 33021, 206, 33184, 87, 30000, 100000, 500000
	);

	CONSTANT C_MUX_VALUES : t_section_int_array :=
	(
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 1
	);

	CONSTANT C_PHASE_VALUES : t_section_int_array :=
	(
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, C_PHASE_180_WORD, 0, C_PHASE_180_WORD, 0, C_PHASE_180_WORD, 0,
		C_PHASE_180_WORD, 0, C_PHASE_180_WORD, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, C_PHASE_180_WORD, 0, C_PHASE_180_WORD,
		0, C_PHASE_180_WORD, 0, C_PHASE_180_WORD, 0, C_PHASE_180_WORD, 0, 0, 0
	);

	CONSTANT C_RSTN_VALUES : t_section_int_array :=
	(
		0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1
	);

	CONSTANT C_Z_GRADIENT_VALUES : t_section_int_array :=
	(
		2000, 2000, 3500, 2000, 2000, 2000, 2000, 2000, 2000, 2000,
		2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000,
		2000, 2000, 2000, 2000, 3500, 3050, 2000, 2000, 2000, 2000,
		2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000, 2000,
		2000, 2000, 2000, 2000, 2000, 2000, 2000, 3050, 2000
	);

	CONSTANT C_EXPECTED_ORDER : t_expected_order :=
	(
		1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
		11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
		21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
		31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
		41, 42, 43, 44, 45, 46, 47, 48
	);

	SIGNAL clk                                : std_logic := '0';
	SIGNAL i_en                               : std_logic := '0';
	SIGNAL tx_pulse                           : std_logic := '0';
	SIGNAL rx_pulse                           : std_logic := '0';
	SIGNAL config_tvalid_ch0                  : std_logic := '0';
	SIGNAL config_tvalid_ch1                  : std_logic := '0';
	SIGNAL mux_ch                             : std_logic := '0';
	SIGNAL dds_rstn                           : std_logic := '0';
	SIGNAL busy                               : std_logic := '0';
	SIGNAL data_ready                         : std_logic := '0';
	SIGNAL gradient_tvalid                    : std_logic := '0';
	SIGNAL config_dds_data_ch0                : std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL config_dds_data_ch1                : std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL iv_set_nr_sections                 : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_write_sel_section               : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL i_section_commit                   : std_logic := '0';
	SIGNAL iv_set_section_type                : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_delay                       : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_mux                         : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_start_repeat_pointer        : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_end_repeat_pointer          : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_cycle_repetition_number     : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_experiment_repetition_number: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_phase_ch0                   : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_frequency_ch0               : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_phase_ch1                   : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_frequency_ch1               : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_resetn_dds                  : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL nr_dds_ch                          : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL mem_depth                          : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL nr_activity                        : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL iv_set_gradient_x                  : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_y                  : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_z                  : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_x_ref              : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_y_ref              : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_z_ref              : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_sweep              : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_x_sweep_step       : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_y_sweep_step       : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_z_sweep_step       : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_x_sweep_offset     : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_y_sweep_offset     : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_gradient_z_sweep_offset     : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_readback_sel_section            : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_readback_word_index             : unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL readback_word_data                 : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL gradient_x                         : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL gradient_y                         : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL gradient_z                         : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL gradient_x_ref                     : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL gradient_y_ref                     : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL gradient_z_ref                     : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');

BEGIN

	inst_fpga_pulse_gen_if_top : ENTITY work.fpga_pulse_gen_top(Behavioral)
		PORT MAP
		(
			clk 								=> clk,
			o_tx_pulse							=> tx_pulse,
			o_rx_pulse							=> rx_pulse,
			ov_config_dds_data_ch0				=> config_dds_data_ch0,
			o_config_tvalid_ch0					=> config_tvalid_ch0,
			ov_config_dds_data_ch1				=> config_dds_data_ch1,
			o_config_tvalid_ch1					=> config_tvalid_ch1,
			o_mux_ch							=> mux_ch,
			i_en								=> i_en,
			iv_set_nr_sections					=> iv_set_nr_sections,
			iv_write_sel_section				=> iv_write_sel_section,
			i_section_commit					=> i_section_commit,
			iv_set_section_type					=> iv_set_section_type,
			iv_set_delay 						=> iv_set_delay,
			iv_set_mux 							=> iv_set_mux,
			iv_set_start_repeat_pointer			=> iv_set_start_repeat_pointer,
			iv_set_end_repeat_pointer 			=> iv_set_end_repeat_pointer,
			iv_set_cycle_repetition_number		=> iv_set_cycle_repetition_number,
			iv_set_experiment_repetition_number	=> iv_set_experiment_repetition_number,
			o_dds_rstn							=> dds_rstn,
			iv_set_phase_ch0		 			=> iv_set_phase_ch0,
			iv_set_frequency_ch0		 		=> iv_set_frequency_ch0,
			iv_set_phase_ch1			 		=> iv_set_phase_ch1,
			iv_set_frequency_ch1		 		=> iv_set_frequency_ch1,
			iv_set_resetn_dds					=> iv_set_resetn_dds,
			o_busy						 		=> busy,
			o_data_ready				 		=> data_ready,
			ov_nr_dds_ch				 		=> nr_dds_ch,
			ov_mem_depth						=> mem_depth,
			ov_nr_activity						=> nr_activity,
			iv_set_gradient_x					=> iv_set_gradient_x,
			iv_set_gradient_y					=> iv_set_gradient_y,
			iv_set_gradient_z					=> iv_set_gradient_z,
			iv_set_gradient_x_ref				=> iv_set_gradient_x_ref,
			iv_set_gradient_y_ref				=> iv_set_gradient_y_ref,
			iv_set_gradient_z_ref				=> iv_set_gradient_z_ref,
			iv_set_gradient_x_sweep_offset		=> iv_set_gradient_x_sweep_offset,
			iv_set_gradient_y_sweep_offset		=> iv_set_gradient_y_sweep_offset,
			iv_set_gradient_z_sweep_offset		=> iv_set_gradient_z_sweep_offset,
			ov_set_gradient_x					=> gradient_x,
			ov_set_gradient_y					=> gradient_y,
			ov_set_gradient_z					=> gradient_z,
			ov_set_gradient_x_ref				=> gradient_x_ref,
			ov_set_gradient_y_ref				=> gradient_y_ref,
			ov_set_gradient_z_ref				=> gradient_z_ref,
			o_gradient_tvalid					=> gradient_tvalid,
			iv_set_gradient_sweep		 		=> iv_set_gradient_sweep,
			iv_set_gradient_x_sweep_step 		=> iv_set_gradient_x_sweep_step,
			iv_set_gradient_y_sweep_step 		=> iv_set_gradient_y_sweep_step,
			iv_set_gradient_z_sweep_step 		=> iv_set_gradient_z_sweep_step,
			iv_readback_sel_section				=> iv_readback_sel_section,
			iv_readback_word_index				=> iv_readback_word_index,
			ov_readback_word_data				=> readback_word_data
		);

	clk_process : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period / 2;
		clk <= '1';
		WAIT FOR clk_period / 2;
	END PROCESS;

	stim_proc : PROCESS
		PROCEDURE write_general_settings IS
		BEGIN
			WAIT UNTIL rising_edge(clk);
			i_en <= '0';
			iv_set_nr_sections                  <= to_unsigned(C_TB_NR_SECTIONS, C_DATA_WIDTH);
			iv_set_start_repeat_pointer         <= to_unsigned(C_TB_REPEAT_START, C_DATA_WIDTH);
			iv_set_end_repeat_pointer           <= to_unsigned(C_TB_REPEAT_END, C_DATA_WIDTH);
			iv_set_cycle_repetition_number      <= to_unsigned(C_TB_CYCLE_REPETITIONS, C_DATA_WIDTH);
			iv_set_experiment_repetition_number <= to_unsigned(C_TB_EXPERIMENT_REPETITIONS, C_DATA_WIDTH);
			iv_set_gradient_x_sweep_step        <= to_unsigned(0, C_DATA_WIDTH);
			iv_set_gradient_y_sweep_step        <= to_unsigned(0, C_DATA_WIDTH);
			iv_set_gradient_z_sweep_step        <= to_unsigned(0, C_DATA_WIDTH);
			WAIT UNTIL rising_edge(clk);
		END write_general_settings;

		PROCEDURE write_section
		(
			CONSTANT section_id : IN integer
		)
		IS
		BEGIN
			WAIT UNTIL rising_edge(clk);
			i_en <= '0';
			iv_write_sel_section           <= to_unsigned(section_id, C_DATA_WIDTH);
			iv_set_section_type            <= to_unsigned(C_SECTION_TYPE_VALUES(section_id), C_DATA_WIDTH);
			iv_set_delay                   <= to_unsigned(C_DELAY_VALUES(section_id), C_DATA_WIDTH);
			iv_set_mux                     <= to_unsigned(C_MUX_VALUES(section_id), C_DATA_WIDTH);
			iv_set_phase_ch0               <= to_unsigned(C_PHASE_VALUES(section_id), C_DATA_WIDTH);
			iv_set_frequency_ch0           <= to_unsigned(C_TX_FREQ_WORD, C_DATA_WIDTH);
			iv_set_phase_ch1               <= to_unsigned(C_PHASE_VALUES(section_id), C_DATA_WIDTH);
			iv_set_frequency_ch1           <= to_unsigned(C_RX_FREQ_WORD, C_DATA_WIDTH);
			iv_set_resetn_dds              <= to_unsigned(C_RSTN_VALUES(section_id), C_DATA_WIDTH);
			iv_set_gradient_x              <= to_unsigned(C_GRAD_CENTER, C_DATA_WIDTH);
			iv_set_gradient_y              <= to_unsigned(C_GRAD_CENTER, C_DATA_WIDTH);
			iv_set_gradient_z              <= to_unsigned(C_Z_GRADIENT_VALUES(section_id), C_DATA_WIDTH);
			iv_set_gradient_x_ref          <= to_unsigned(C_GRAD_CENTER, C_DATA_WIDTH);
			iv_set_gradient_y_ref          <= to_unsigned(C_GRAD_CENTER, C_DATA_WIDTH);
			iv_set_gradient_z_ref          <= to_unsigned(C_GRAD_CENTER, C_DATA_WIDTH);
			iv_set_gradient_x_sweep_offset <= to_unsigned(0, C_DATA_WIDTH);
			iv_set_gradient_y_sweep_offset <= to_unsigned(0, C_DATA_WIDTH);
			iv_set_gradient_z_sweep_offset <= to_unsigned(0, C_DATA_WIDTH);
			iv_set_gradient_sweep          <= to_unsigned(0, C_DATA_WIDTH);
			WAIT UNTIL rising_edge(clk);
			i_section_commit <= '1';
			WAIT UNTIL rising_edge(clk);
			i_section_commit <= '0';
		END write_section;
	BEGIN
		WAIT FOR 5 * clk_period;
		write_general_settings;

		ASSERT to_integer(unsigned(mem_depth)) >= C_TB_NR_SECTIONS
			REPORT "Configured section memory depth is smaller than W5_WATERGATE_PAPER_V3_PREFETCH."
			SEVERITY failure;

		FOR section_id IN 0 TO C_TB_NR_SECTIONS - 1 LOOP
			write_section(section_id);
		END LOOP;

		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		i_en <= '1';

		WAIT;
	END PROCESS;

	monitor_proc : PROCESS
		VARIABLE cycle_count    : integer := 0;
		VARIABLE last_event     : integer := 0;
		VARIABLE expected_index : integer := 0;
		VARIABLE expected_id    : integer := 0;
		VARIABLE elapsed        : integer := 0;
	BEGIN
		WAIT UNTIL rising_edge(clk);
		cycle_count := cycle_count + 1;

		IF gradient_tvalid = '1' THEN
			IF expected_index > C_EXPECTED_ORDER'high THEN
				ASSERT false
					REPORT "Observed more section-valid events than expected."
					SEVERITY failure;
			ELSE
				expected_id := C_EXPECTED_ORDER(expected_index);

				REPORT "Config-derived W5 section event " & integer'image(expected_index) &
					   " at " & time'image(now) &
					   ": expected section " & integer'image(expected_id)
					SEVERITY note;

				ASSERT to_integer(unsigned(gradient_z)) = C_Z_GRADIENT_VALUES(expected_id)
					REPORT "Gradient Z mismatch at event " & integer'image(expected_index) &
						   ". Expected " & integer'image(C_Z_GRADIENT_VALUES(expected_id)) &
						   ", observed " & integer'image(to_integer(unsigned(gradient_z)))
					SEVERITY failure;

				ASSERT to_integer(unsigned(gradient_x)) = C_GRAD_CENTER
					REPORT "Gradient X mismatch at event " & integer'image(expected_index)
					SEVERITY failure;

				ASSERT to_integer(unsigned(gradient_y)) = C_GRAD_CENTER
					REPORT "Gradient Y mismatch at event " & integer'image(expected_index)
					SEVERITY failure;

				IF expected_index > 0 THEN
					elapsed := cycle_count - last_event;
					ASSERT elapsed = C_DELAY_VALUES(C_EXPECTED_ORDER(expected_index - 1))
						REPORT "Section duration mismatch before event " & integer'image(expected_index) &
							   ". Expected " & integer'image(C_DELAY_VALUES(C_EXPECTED_ORDER(expected_index - 1))) &
							   " clocks, observed " & integer'image(elapsed) & " clocks."
						SEVERITY failure;
				END IF;

				last_event := cycle_count;
				expected_index := expected_index + 1;

				IF expected_index = C_EXPECTED_ORDER'length THEN
					REPORT "Config-derived W5 WATERGATE sequence passed." SEVERITY note;
					WAIT FOR 20 * clk_period;
					ASSERT false REPORT "Simulation finished successfully." SEVERITY failure;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	watchdog_proc : PROCESS
	BEGIN
		WAIT FOR 1000 ms;
		ASSERT false REPORT "Timeout waiting for W5_WATERGATE_PAPER_V3_PREFETCH sequence." SEVERITY failure;
	END PROCESS;

END Behavioral;
