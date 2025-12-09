----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.09.2022 10:00:21
-- Design Name: 
-- Module Name: tb_dac_ghh - Behavioral
-- Project Name: 
-- Target Devices: 
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
use ieee.math_real.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tb_dac is
--  Port ( );
end tb_dac;

architecture Behavioral of tb_dac is

    CONSTANT
        C_CLK_PERIOD
        : time := 4 ns;  -- input 250MHz (output 125MHz)
		        
    signal 
		data_i
		: std_logic_vector(15 downto 0) := (others => '0');
	signal
		ov_data
		: std_logic_vector(13 downto 0) := (others => '0');
		
	signal
		clk,
		clk_out
		: std_logic := '0';
		
    type ROM512kx18 is 
	   array (0 to 511) of signed(15 downto 0);

	signal 
		ROM
		: ROM512kx18;
		
begin

	uut: ENTITY work.fpga_DAC_AD9767_v1_0(arch_imp)
	generic map
	(
		C_DAC_RESOLUTION => 14,
		C_S00_AXIS_TDATA_WIDTH => 16
	)
	port map
	(
		ov_dac_data => ov_data,
		o_clk_dac => clk_out,
		s00_axis_aclk => clk,
		s00_axis_aresetn => '1',
		s00_axis_tready => open,
		s00_axis_tdata => data_i,
		s00_axis_tstrb => (others => '0'),
		s00_axis_tlast => '0',
		s00_axis_tvalid => '0'
	);
    -- Clock process definitions
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR C_CLK_PERIOD/2;
        clk <= '1';
        WAIT FOR C_CLK_PERIOD/2;
    END PROCESS;
    
    data_in : PROCESS(clk)
        variable i : integer := 0;
    BEGIN
        
		if rising_edge (clk) then
		      data_i <= std_logic_vector(ROM(i)) after 1 ns;
        end if;
        i := i+1;
           
    END PROCESS;




    tabel: for I in 0 to 511 generate
	  ROM(I)                   <= to_signed(integer(sin(2.0*MATH_PI*(real(I)+0.5)/512.0)*32767.5),16);
	end generate;

	
end Behavioral;
