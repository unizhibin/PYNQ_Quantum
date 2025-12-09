----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 20.06.2022 14:50:48
-- Design Name: 
-- Module Name: fpga_pulse_timer - Behavioral
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

entity fpga_pulse_timer is
  Port 
  ( 
  		clk 						: IN std_logic;
		i_rstn						: IN std_logic;
		i_timer_en					: IN std_logic;
		i_timer_load_en				: IN std_logic;
		iv_timer_data				: IN unsigned (C_DATA_WIDTH - 1 DOWNTO 0);
		o_timer_pre_done			: OUT std_logic;
		o_timer_done				: OUT std_logic
  );
end fpga_pulse_timer;

architecture Behavioral of fpga_pulse_timer is

	signal
	timer_data,
	d1_timer_data
	: unsigned (C_DATA_WIDTH - 1 DOWNTO 0) := (others => '0');
	signal
	timer_done,
	d1_timer_load_en
	: std_logic := '0';
begin
	
	timer_proc: PROCESS(clk)
	BEGIN
		
		IF rising_edge(clk) THEN
				d1_timer_data 		<= timer_data;
				d1_timer_load_en 	<= i_timer_load_en;
			IF i_rstn = '0' THEN
				timer_data 			<= (others => '0');
				d1_timer_data 		<= (others => '0');
			ELSE
			    IF d1_timer_load_en = '1' OR ((d1_timer_data = 1)AND (i_timer_en = '1')) THEN 
						timer_data 	<= iv_timer_data - to_unsigned(1,timer_data'length);
				ELSIF i_timer_en = '1' and timer_data > 0 THEN
						timer_data	<= timer_data - to_unsigned(1,timer_data'length);
				END IF;
			END IF;
		END IF;
		
	END PROCESS;
o_timer_pre_done 	<= '1' WHEN  (timer_data = 2) AND (i_timer_en = '1')ELSE '0';
o_timer_done 		<= '1' WHEN  (d1_timer_data/=0)	AND (timer_data = 0) AND (i_timer_en = '1')ELSE '0';
end Behavioral;
