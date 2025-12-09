----------------------------------------------------------------------------------
-- Company: university of stuttgart
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 16.03.2023 20:29:19
-- Design Name: testbench for pid controller
-- Module Name: tb_fpga_pid_controller - Behavioral
-- Project Name: NMR spetrometer
-- Target Devices: PYNQ Z2
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tb_fpga_pid_controller is
--  Port ( );
end tb_fpga_pid_controller;

architecture Behavioral of tb_fpga_pid_controller is

	CONSTANT
		C_CLK_PERIOD
		: time := 5 ns;
	
	CONSTANT
		C_S_AXI_DATA_WIDTH
		: integer := 32 ;		

	CONSTANT C_FILE_NAME :string  := "C:\Users\ac138004\Desktop\Github\NMR-spectrometer\IP_core\fpga_magnet_controller_1.0\src\actual_value.txt";

	CONSTANT
		NR_Samples
		: integer := 200;
	signal
		clk,
		rst_n,
		done,
		en: std_logic := '0';
	
	signal
		Kp,
		Ki,
		Kd,
		iv_time,
		iv_time_safety,
		iv_voltage_safety,
		iv_target_value,
		iv_actual_value,
		export_voltage_i
		: std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		
	file fptr: text;
	type			 	t_integer_array       		is array(integer range <> )  of integer;
	shared variable 	v_data_read      			:t_integer_array(1 to NR_Samples):= (others=> -1);
	
begin

		
inst_fpga_pid_controller : ENTITY work.fpga_pid_controller(Behavioral)
	generic map
	(
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH
	)
    PORT MAP
    (
    		clk 	=> clk,
			rst_n 	=> rst_n,
            iv_Kp   => Kp,
            iv_Ki   => Ki,
            iv_Kd   => Kd,
            iv_time => iv_time,
            iv_time_safety      => iv_time_safety,
            iv_voltage_safety   => iv_voltage_safety,
            iv_target_value     => iv_target_value,
            iv_actual_value     => iv_actual_value,
            ov_export_value     => export_voltage_i,
			i_pid_en			=> en,
			o_done				=> done
    );

	PROCESS -- system reference clock
	BEGIN
		clk <= '1';
		WAIT FOR C_CLK_PERIOD/2;
		clk <= '0';
		WAIT FOR C_CLK_PERIOD/2;
	END PROCESS;
	
	rst_n <= '0', '1' after 20 ns ;
	en  <= '0', '1' after 30 ns ;
	GetData_proc: process(clk)
			variable fstatus       :file_open_status;
			variable file_line     :line;		
			begin

				if rising_edge(clk) then				
					file_open(fstatus, fptr, C_FILE_NAME, read_mode);			

					if(not endfile(fptr)) then
						readline(fptr,file_line);
					end if;	
					
					for kk in 1 to NR_Samples loop
					read(file_line,v_data_read(kk));
					end loop;
					
					file_close(fptr);
				end if;

			end process;
			
	finish_sim_time : PROCESS(clk,done)
	
		variable read_pointer : integer := 1;
		
		BEGIN
		
			Kp					<= std_logic_vector(to_signed(100, C_S_AXI_DATA_WIDTH));
			Ki					<= std_logic_vector(to_signed(0, C_S_AXI_DATA_WIDTH));
			Kd					<= std_logic_vector(to_signed(0, C_S_AXI_DATA_WIDTH));
			iv_time				<= std_logic_vector(to_signed(2, C_S_AXI_DATA_WIDTH));
			iv_time_safety		<= std_logic_vector(to_signed(4, C_S_AXI_DATA_WIDTH));
			iv_voltage_safety	<= std_logic_vector(to_signed(10000, C_S_AXI_DATA_WIDTH));
			iv_target_value		<= std_logic_vector(to_signed(10000, C_S_AXI_DATA_WIDTH));
			
			if rising_edge (clk) then 
				
				if done = '1' then 
				
					read_pointer := read_pointer + 1;
					iv_actual_value <= (others => '0');
				else 

					read_pointer := read_pointer;
				end if;
				
				iv_actual_value	<= std_logic_vector(to_signed(v_data_read(read_pointer),C_S_AXI_DATA_WIDTH));				
			end if;
			
			-- WAIT FOR 300 ns;			
	        -- ASSERT false
            -- REPORT "simulation finished"
            -- SEVERITY failure;
    END PROCESS finish_sim_time;

end Behavioral;
