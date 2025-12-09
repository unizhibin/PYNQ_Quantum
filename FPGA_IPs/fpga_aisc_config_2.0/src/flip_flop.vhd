----------------------------------------------------------------------------------
-- Title: Entity flip_flop
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC Filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/1 15:23
--  
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY flip_flop IS
	GENERIC(
		Nbit : integer := 4										-- input and output width
	);
	PORT(
		clk         : IN  std_logic;
		enabler     : IN  std_logic;							-- input assign to output only when enabler high
		rstn        : IN  std_logic;							-- active low reset
		inputData   : IN  std_logic_vector(Nbit-1 DOWNTO 0);
		outputData  : OUT std_logic_vector(Nbit-1 DOWNTO 0)
	);
END flip_flop;

ARCHITECTURE Behavioral OF flip_flop IS
	SIGNAL temp : std_logic_vector(Nbit-1 DOWNTO 0) := (OTHERS => '0');
BEGIN

	register_proc: PROCESS(clk) BEGIN
		IF (clk'event and clk = '1') THEN
			IF (rstn = '0') THEN
				temp <= (OTHERS => '0');
			ELSE
				IF (enabler = '1') THEN
					temp <= inputData;
				ELSE
					temp <= temp;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	outputData <= temp;
	
END Behavioral;