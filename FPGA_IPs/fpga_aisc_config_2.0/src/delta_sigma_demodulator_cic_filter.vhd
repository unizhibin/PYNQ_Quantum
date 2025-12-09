----------------------------------------------------------------------------------
-- Title: ENTITY delta_sigma_demodulator_cic_filter
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Integrator block as delta-sigma demodulator, add CIC filter for filtering.
--				1-bit digital signal as input, decimated signal as output (e.g. sine wave).
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/24 16:05
--  Version 0.2 add I Q part, Zhibin Zhao, 25.01.2024 14:05
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY delta_sigma_demodulator_cic_filter IS
	GENERIC(
		output_bitwidth : integer := 16;
		bus_width     	: integer := 32;
		buffer_depth  	: integer := 16;
		voltage_level 	: integer := 1
	);
	PORT(
		clk  				: IN std_logic;
		rstn 				: IN std_logic;
		select_filter		: IN std_logic;																	-- '1'-cic filter; '0'-no filter 					
		N    				: IN std_logic_vector(bus_width - 1 DOWNTO 0);
		M 					: IN std_logic_vector(bus_width - 1 DOWNTO 0);
		R 	 				: IN std_logic_vector(bus_width - 1 DOWNTO 0);
		i_modulated_I 		: IN std_logic;																-- Digital signal (1-bit) after delta-sigma ADC, e.g. sine wave
		i_modulated_Q 		: IN std_logic;																-- Digital signal (1-bit) after delta-sigma ADC, e.g. sine wave
		ov_demodulator_I 	: OUT std_logic_vector(output_bitwidth - 1 DOWNTO 0);							-- Filtered signal
		ov_demodulator_Q 	: OUT std_logic_vector(output_bitwidth - 1 DOWNTO 0)							-- Filtered signal
	);
END ENTITY;

ARCHITECTURE Behavioral OF delta_sigma_demodulator_cic_filter IS

	SIGNAL ov_converted_I   : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0'); 			-- Convertered signal (from 0/1 to -voltage_level/voltage_level)
	SIGNAL ov_converted_Q   : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0'); 			-- Convertered signal (from 0/1 to -voltage_level/voltage_level)
	SIGNAL ov_demodulated_I : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0');   			-- Rough signal after integration (demodulation): r(t)
	SIGNAL ov_demodulated_Q : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0');   			-- Rough signal after integration (demodulation): r(t)
	SIGNAL ov_demodulation_filtered_I : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0');	-- Filtered signal					
	SIGNAL ov_demodulation_filtered_Q : std_logic_vector(output_bitwidth-1 DOWNTO 0) := (OTHERS => '0');	-- Filtered signal					
	
BEGIN

	-- Instantiation

	Inst_da_converter_I : ENTITY work.da_converter
	GENERIC MAP(
		Nbit => output_bitwidth,
		voltage_level => voltage_level
	)
	PORT MAP(
		clk		=> clk,
		i_data  => i_modulated_I,
		ov_data => ov_converted_I
	);

	Inst_da_converter_Q : ENTITY work.da_converter
	GENERIC MAP(
		Nbit => output_bitwidth,
		voltage_level => voltage_level
	)
	PORT MAP(
		clk     => clk,
		i_data  => i_modulated_Q,
		ov_data => ov_converted_Q
	);


	Inst_integrator_block_I : ENTITY work.CIC_Filter_v2	-- Delta-sigma demodulator
	GENERIC MAP(
		N => 3,         -- Number of integrator and comb stages
        R => 5,          -- Decimation factor
        DATA_WIDTH =>16 -- Data bit width
	)
	PORT MAP(
        clk 	=> clk,
        rstn 	=> rstn,
        iv_cic 	=> ov_converted_I,
        ov_cic 	=> ov_demodulated_I
	);

	Inst_integrator_block_Q : ENTITY work.CIC_Filter_v2	-- Delta-sigma demodulator
	GENERIC MAP(
		N => 3,         -- Number of integrator and comb stages
        R => 5,          -- Decimation factor
        DATA_WIDTH =>16 -- Data bit width
	)
	PORT MAP(
        clk 	=> clk,
        rstn 	=> rstn,
        iv_cic 	=> ov_converted_Q,
        ov_cic 	=> ov_demodulated_Q
	);
	
	-- Inst_cic_filter_I : ENTITY work.cic_filter
	-- GENERIC MAP(
		-- bus_width 	 => bus_width,
		-- Nbit 	  	 => output_bitwidth,
		-- buffer_depth => buffer_depth
	-- )
	-- PORT MAP(
		-- clk    => clk,
		-- rstn   => rstn,
		-- N      => N,
		-- M	   => M,
		-- R      => R,
		-- iv_cic => ov_demodulated_I,
		-- ov_cic => ov_demodulation_filtered_I
	-- );

	-- Inst_cic_filter_Q : ENTITY work.cic_filter
	-- GENERIC MAP(
		-- bus_width 	 => bus_width,
		-- Nbit 	  	 => output_bitwidth,
		-- buffer_depth => buffer_depth
	-- )
	-- PORT MAP(
		-- clk    => clk,
		-- rstn   => rstn,
		-- N      => N,
		-- M 	   => M,
		-- R      => R,
		-- iv_cic => ov_demodulated_Q,
		-- ov_cic => ov_demodulation_filtered_Q
	-- );
	
	filter_select_proc : PROCESS (clk)
	BEGIN 
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				ov_demodulator_I <= (OTHERS => '0');
				ov_demodulator_Q <= (OTHERS => '0');
			ELSE
				IF select_filter = '1' THEN
					ov_demodulator_I <= ov_demodulation_filtered_I;
					ov_demodulator_Q <= ov_demodulation_filtered_Q;
				ELSE
					ov_demodulator_I <= ov_converted_I;
					ov_demodulator_Q <= ov_converted_Q;
				END IF;
			END IF;
		END IF;
	END PROCESS;
		
END Behavioral;