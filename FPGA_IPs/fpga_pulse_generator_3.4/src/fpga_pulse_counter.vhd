----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 20.06.2022 14:50:48
-- Design Name: 
-- Module Name: fpga_pulse_counter - Behavioral
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
-- 
----------------------------------------------------------------------------------


-- ! Use standard library ieee
library IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;

-- ! Use library fpga_pulse_gen_pkg
USE work.fpga_pulse_gen_pkg.ALL;

entity fpga_pulse_counter is
  Port 
  ( 
  		clk 						: IN std_logic;
		i_rstn						: IN std_logic;
		i_counter_en				: IN std_logic;
		i_counter_load_en			: IN std_logic;
		iv_counter_data				: IN unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		ov_counter_data				: OUT unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		o_pre_counter_done			: OUT std_logic;
		o_counter_done				: OUT std_logic
  );
end fpga_pulse_counter;

architecture Behavioral of fpga_pulse_counter is

	signal
	counter_data
	: unsigned (C_DATA_WIDTH - 1 DOWNTO 0) := (others => '0');
begin
	
	counter_proc: PROCESS(clk)
	BEGIN
		
		IF rising_edge(clk) THEN
			IF i_rstn = '0' THEN
				counter_data 	<= (others => '0');
			ELSE
			    IF i_counter_load_en = '1' THEN 
					counter_data 	<= iv_counter_data;
				ELSIF i_counter_en = '1' and counter_data > 0 THEN 
					counter_data	<= counter_data - to_unsigned(1,counter_data'length);
			    END IF;
			END IF;
		END IF;
		
	END PROCESS;
o_counter_done 		<= '1' when counter_data = 0 else '0' ;
o_pre_counter_done 	<= '1' when counter_data = 1 else '0' ;
ov_counter_data <= counter_data;
end Behavioral;
