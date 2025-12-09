----------------------------------------------------------------------------------
-- Title: Entity da_converter
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: CIC Filter
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Digital to analog amplitude converter. Take 1-bit ('0' or '1') digital output from delta-sigma ADC(modulator),
--				convert '0' to low voltage level and '1' to high voltage level.
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/8/16 15:13
--  
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY da_converter IS
	GENERIC(
		Nbit          : integer := 16;									-- Output width
		voltage_level : integer := 1							
	);
	PORT(
		clk	   : in std_logic; 
		i_data : IN std_logic;
		ov_data : OUT std_logic_vector(Nbit-1 DOWNTO 0)
	);
END da_converter;

ARCHITECTURE Behavioral OF da_converter IS

signal data_buffer, d1_data_buffer : std_logic_vector(Nbit -1 downto 0);

BEGIN

	-- Combinational logic only

	register_proc: PROCESS(clk) 
	BEGIN
	if rising_edge (clk) then 
		IF i_data = '1' THEN
			data_buffer <= std_logic_vector(to_signed(voltage_level, Nbit));
		ELSE
			data_buffer <= std_logic_vector(to_signed(-voltage_level, Nbit));
		END IF;
	end if;
	
	END PROCESS;

	reg_proc: PROCESS(clk) 
	BEGIN
		if rising_edge (clk) then 
		
				d1_data_buffer <= std_logic_vector(signed(d1_data_buffer) + signed(data_buffer));
		
		end if;
		
	END PROCESS;
	
	ov_data <= d1_data_buffer;
	
END Behavioral;