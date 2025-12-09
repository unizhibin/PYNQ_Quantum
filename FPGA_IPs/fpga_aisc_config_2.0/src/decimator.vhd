----------------------------------------------------------------------------------
-- Title: Entity decimator
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC Filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Decimation
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/24 16:11
--  
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY decimator IS
	GENERIC(
		Nbit 	: integer := 8;											-- Input and output width
	bus_width 	: integer := 32
	);
	PORT(
		clk			  		: IN  std_logic;
		rstn		  		: IN  std_logic;
		R       			: IN  std_logic_vector(bus_width-1 DOWNTO 0);   -- Decimation parameter
		iv_decimator  		: IN  std_logic_vector(Nbit-1 DOWNTO 0);
		ov_decimator  		: OUT std_logic_vector(Nbit-1 DOWNTO 0);
		o_decimator_valid 	: OUT std_logic
	);
END ENTITY decimator;

ARCHITECTURE Behavioral OF decimator IS

	SIGNAL temp : std_logic_vector(Nbit-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL cnt_decimation	: integer   := 0;
BEGIN

	-- Processes
	
	counter_proc : PROCESS(clk)						-- Decimation based on integrators output samples
	BEGIN
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				cnt_decimation 		<= to_integer(signed(R)) - 1;
				o_decimator_valid	<= '0';			
			ELSE

				IF cnt_decimation = to_integer(signed(R))- 1 THEN
					cnt_decimation <= 0;
					o_decimator_valid <= '1';
				ELSE
					cnt_decimation <= cnt_decimation + 1;
					o_decimator_valid <= '0';					
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF rstn = '0' THEN
				temp <= (OTHERS => '0');
			ELSE
				-- Combinational logic
				IF cnt_decimation = to_integer(signed(R)) - 1 THEN
					temp <= iv_decimator;
				ELSE
					temp <= temp;					
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	ov_decimator <= temp;
	
END Behavioral;