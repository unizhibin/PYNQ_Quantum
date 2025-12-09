----------------------------------------------------------------------------------
-- Company: Universty of Sttutgart  IIS
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2022/10/18 10:35:05
-- Design Name: testbench for adc max 11198 16 bit 2Msps 
-- Module Name: tb_fpga_nmr_adc_max11198 - Behavioral
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

entity tb_fpga_nmr_adc_max11198 is
--  Port ( );
end tb_fpga_nmr_adc_max11198;

architecture Behavioral of tb_fpga_nmr_adc_max11198 is

 -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT fpga_nmr_adc_max11198
	generic
	(
		-- the frequency of main clock 250 MHz 
		C_CLK_FREQENCY : integer 		:= 100000000;
		-- the frequency of spi clock 100 Hz	
		C_SCLK_FREQUENCY : integer 		:= 50000000
		
	);
    Port 
	( 
		clk 		: in STD_LOGIC;
		rst_n 		: in STD_LOGIC;
		o_cnvst 	: out STD_LOGIC;
		o_sclk 		: out STD_LOGIC;
		i_miso_0 		: in STD_LOGIC;		
		i_miso_1 		: in STD_LOGIC;
		ov_analog_0 	: out STD_LOGIC_VECTOR (15 downto 0);	
		ov_analog_1 	: out STD_LOGIC_VECTOR (15 downto 0)
	);
  END COMPONENT;
  
    signal
	clk,
	rst,
	miso,
	sclk,
	d1_sclk,	
	cs,
	d1_cs,
	busy,
	done
	: std_logic := '0';
	
	signal
	rx_data
	:std_logic_vector (15 downto 0) := (others =>'0');

	signal 
		ADC_Data_buff         
		: std_logic_vector(15 downto 0) := (others => '0');
	signal 
		ADC_Data_SR           
		: std_logic_vector(15 downto 0) := (others => '0');
	
	signal 
		counter               
		: unsigned(8 downto 0) := (others => '0');
	signal 
		samplecounter         
		: unsigned(8 downto 0) := (others => '0');
	signal 
		speed                 
		: unsigned(8 downto 0) := "000000001";
	signal 
		pause_counter         
		: unsigned(7 downto 0) := (others => '0');		
	--- DATA ---
	type ROM512kx18 is 
	array (0 to 511) of signed(15 downto 0);
	
	signal 
		ROM
		: ROM512kx18;
		
begin

	clk <= not clk after 5 ns; -- 250 MHz

  -- Instantiate the Unit Under Test (UUT)
  uut: fpga_nmr_adc_max11198
	GENERIC MAP
	(	
		C_CLK_FREQENCY =>  100000000,		-- the frequency of main clock 
		C_SCLK_FREQUENCY => 50000000	-- the frequency of spi clock

	)
	PORT MAP
	(
		clk => clk,
		rst_n => '1',
		o_cnvst => cs,
		o_sclk => sclk,
		i_miso_0 => ADC_Data_SR(15),
		i_miso_1 => '0',		
		ov_analog_0 => rx_data,
		ov_analog_1 => open
		
	);
	
	
	process
	begin
		wait for 4 ns;
		d1_sclk <= sclk;
		d1_cs	<= cs;
		
		if d1_sclk = '1' and sclk = '0' then
			ADC_Data_SR          <= ADC_Data_SR(14 downto 0) & '0';
		end if;
		
		if d1_cs = '0' and cs = '1' then
			samplecounter        <= samplecounter + 1;
			counter              <= counter + speed;
			if samplecounter = 511 then
				speed            <= speed + 4;
				samplecounter    <= (others => '0');
			end if;
			if speed > 510 and samplecounter = 511 then
			wait;
			end if;
			ADC_Data_buff        <= std_logic_vector(ROM(to_integer(counter)));
		end if;
			pause_counter            <= pause_counter + 1;
		if sclk = '1' then
			pause_counter        <= (others => '0');
		end if;
		if pause_counter = 4 then -- set new sample after 20 ns CLK pause
			ADC_Data_SR          <= ADC_Data_buff;
		end if;		
		
	end process;

Tabel:  for I in 0 to 511 generate
			ROM(I) <= to_signed(integer(sin(2.0*MATH_PI*(real(I)+0.5)/512.0)*32767.5),16);
		end generate;
		
end Behavioral;
