----------------------------------------------------------------------------------
-- Title: Entity combs
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC Filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: N order combs (stages) by re-using only one block. (Save space)
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/24 11:52
--  Version 0.2 change a lot ... Zhibin
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


ENTITY combs IS
	GENERIC (
		Nbit : integer	:= 32;			-- Integrator input data width
		Ibit : integer  := 64;			-- Internal result data width
		Mbit : integer	:= 18;			-- Integrator output data width
		bus_width : integer := 32;		-- Data bus width
		buffer_depth : integer := 16	-- Store result from all stages
	);
	PORT (
		N      		  : IN std_logic_vector(bus_width - 1 DOWNTO 0);						-- # of integrator blocks (order of CIC filter)
		clk			  : IN std_logic;
		rstn		  : IN std_logic;
		iv_combs	  : IN std_logic_vector(Nbit - 1 DOWNTO 0);
		ov_combs      : OUT std_logic_vector(Mbit - 1 DOWNTO 0)												-- Output valid only when all N stages are processed
	);
END combs;

ARCHITECTURE Behavioral OF combs IS

	TYPE result_buffer_type IS ARRAY(buffer_depth - 1 DOWNTO 0) OF std_logic_vector(Ibit - 1 DOWNTO 0);
	SIGNAL result_buffer 		: result_buffer_type := (OTHERS => (OTHERS => '0'));			-- Internal result buffer

BEGIN

	-- Equation of each comb stage: c(n+1) = x(n) - c(n)
	
	comb_proc : PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				ov_combs 			<= (OTHERS => '0');
				result_buffer 		<= (OTHERS => (OTHERS => '0'));		
			ELSE
				ov_combs			<= 	std_logic_vector(to_signed(to_integer(signed(result_buffer(to_integer(unsigned(N))))), ov_combs'length));			
				result_buffer(0) <= std_logic_vector(resize(signed(iv_combs),result_buffer(0)'length));				
				for I in 0 to (buffer_depth - 2) Loop
						result_buffer(I+1) <= std_logic_vector(shift_right((-signed(result_buffer(I)) + signed(result_buffer(I+1))),1));
				end loop;
			END IF;
		END IF;
	END PROCESS;
	
END Behavioral;