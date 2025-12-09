----------------------------------------------------------------------------------
-- Title: Entity cic_filter
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng 
-- 
-- Project Name: CIC Filter 
--
-- Target Devices: 
-- Tool Versions: 
-- Description: CIC filter with insertion: integrator_stages + decimator + comb_stages.
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/24 16:47
--  
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cic_filter IS
	GENERIC(
		bus_width 		: integer := 32;		-- Bus width
		Nbit 			: integer := 18;		-- Data width
		buffer_depth 	: integer := 8 			-- Highest order of CIC
	);
	PORT(
		clk 	: IN  std_logic;
		rstn	: IN  std_logic;
		N       : IN  std_logic_vector(bus_width-1 DOWNTO 0);	-- Order of CIC -> Combs
		M       : IN  std_logic_vector(bus_width-1 DOWNTO 0);	-- Order of CIC -> Integrators
		R       : IN  std_logic_vector(bus_width-1 DOWNTO 0);   -- Decimation parameter
		iv_cic  : IN  std_logic_vector(Nbit-1 DOWNTO 0);
		ov_cic  : OUT std_logic_vector(Nbit-1 DOWNTO 0)
	);
END cic_filter;

ARCHITECTURE Behavioral OF cic_filter IS

	SIGNAL combs_output_v : std_logic_vector(Nbit - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL integrators_o_valid  : std_logic := '0';
	SIGNAL decimator_output_v	: std_logic_vector(Nbit - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL decimator_valid    : std_logic := '1';

BEGIN
	
	-- Component instantiations
	
	Inst_combs : ENTITY work.combs
	GENERIC MAP(
		Nbit 			=> Nbit,
		Mbit 			=> Nbit,
		bus_width       => bus_width,
		buffer_depth 	=> buffer_depth
	)
	PORT MAP(
		N      	 => N,
		clk		 => clk,
		rstn	 => rstn,
		iv_combs => iv_cic,
		ov_combs =>	combs_output_v
	);	
	
	Inst_decimator : ENTITY work.decimator
	GENERIC MAP(
		Nbit => Nbit,
		bus_width => bus_width
	)
	PORT MAP(
		clk 		   => clk,
		rstn 		   => rstn,
		R 			   => R,
		iv_decimator   => combs_output_v,
		o_decimator_valid => decimator_valid,
		ov_decimator   => decimator_output_v
	);	

	Inst_integrators : ENTITY work.integrators
	GENERIC MAP(
		Nbit 			=> Nbit,
		Mbit		 	=> Nbit,
		bus_width       => bus_width,
		buffer_depth 	=> buffer_depth
	)
	PORT MAP(
		M 				=> M,
		clk 			=> clk,
		rstn 			=> rstn,
		i_integrators_ready => decimator_valid,
		iv_integrators 	=> decimator_output_v,
		ov_integrators 	=> ov_cic
	);
	
END Behavioral;