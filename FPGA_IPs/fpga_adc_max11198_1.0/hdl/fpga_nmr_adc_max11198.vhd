----------------------------------------------------------------------------------
-- Company: University of Stuttgart IIS
-- Engineer: Zhibin
-- 
-- Create Date: 2022/10/14 15:26:24
-- Design Name: Max 11192 adc driver
-- Module Name: fpga_adc_max11192 - Behavioral
-- Project Name: Compact nmr
-- Target Devices: PNYNQ Z2
-- Tool Versions: Vivado 2020.2
-- Description: Mode 1:
--						initiate read right after cnvst rising edge
-- 				Mode 2:
--						initiate read right after cnvst falling edge
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- math library
USE ieee.math_real.ALL;

entity fpga_nmr_adc_max11198 is

	generic
	(
		-- the frequency of main clock 100 MHz 
		C_CLK_FREQENCY : integer 		:= 100000000;
		-- the frequency of spi clock 50 MHz	
		C_SCLK_FREQUENCY : integer 		:= 50000000
		
	);
    Port 
	( 
        clk 		    : in STD_LOGIC;
        rst_n 		    : in STD_LOGIC;
		o_cnvst 	    : out STD_LOGIC;
        o_sclk 		    : out STD_LOGIC;
		i_miso_0 		: in STD_LOGIC;		
		i_miso_1 		: in STD_LOGIC;
		ov_analog_0 	: out STD_LOGIC_VECTOR (15 downto 0);	
		ov_analog_1 	: out STD_LOGIC_VECTOR (15 downto 0)
	);
	
end fpga_nmr_adc_max11198;

architecture Behavioral of fpga_nmr_adc_max11198 is

	constant c_adc_data_width 	: integer := 16; 	-- 16 bit adc
	
	constant c_number_sclk 		: integer := 17; 	-- 16 bit adc
	
	constant c_CNVST_high_delay : integer := 6; 	-- 60 ns CNVST
	
	constant c_CNVST_low_delay 	: integer := 40; 	-- 400 ns CNVST
	
	constant c_sclk_delay 		: integer := 2;  	-- 20 ns sclk Period   16*20 = 320 ns
	
	constant c_falling_delay 	: integer := 2;		-- delay after CNVST falling edge
	
	constant c_samtosam_delay	: integer := 4; 	-- delay sample to the next sample
	
	
	signal cnt_nr_sclk		: integer range c_number_sclk 			downto 0 := 0;
	
	signal d_CNVST_high		: integer range c_CNVST_high_delay - 1 	downto 0 := 0;
	
	signal d_CNVST_low		: integer range c_CNVST_low_delay - 1 	downto 0 := 0;
	
	signal d_sclk_delay 	: integer range c_sclk_delay - 1  		downto 0 := 0;
		
	signal d_falling_delay 	: integer range c_falling_delay - 1 	downto 0 := 0;
	
	signal d_samtosam_delay : integer range c_samtosam_delay - 1 	downto 0 := c_samtosam_delay - 1;
	
	
	type t_state is
	(
		spi_idle,
		spi_CNVST_high,
		spi_CNVST_low	
	);
	
	signal
	s_state 
	: t_state := spi_idle;
	
	signal
	rx_re_data_0,
	rx_re_data_1,
	rx_reg_0,	
	rx_reg_1
	: std_logic_vector(c_adc_data_width - 1 downto 0) := (others => '0');
	
	signal
	cnvst,
	sclk,
	d1_sclk
	: std_logic := '0';
	
begin
	process(clk)
	begin
		if rising_edge (clk) then 
			if rst_n = '0' then
				s_state 			<= spi_idle;
				cnt_nr_sclk			<= 0;
				d_CNVST_high		<= 0;
				d_CNVST_low			<= 0;
				d_sclk_delay		<= 0;
				d_falling_delay		<= 0;
				d_samtosam_delay 	<= 0;				
				cnvst			<= '0';
				sclk			<= '0';
				d1_sclk			<= '0';
				rx_re_data_0		<= (others => '0');
				rx_re_data_1		<= (others => '0');
				rx_reg_0			<= (others => '0');
				rx_reg_1			<= (others => '0');
			else
				d1_sclk				<= sclk;
				rx_re_data_0		<= rx_re_data_0;
				rx_re_data_1		<= rx_re_data_1;				
				case s_state is 
				
					when spi_idle =>
					
						cnt_nr_sclk			<= c_number_sclk;
						d_CNVST_high		<= c_CNVST_high_delay - 1;
						d_CNVST_low			<= c_CNVST_low_delay - 1;
						d_sclk_delay		<= c_sclk_delay - 1;
						d_falling_delay		<= c_falling_delay - 1;
						
						cnvst			<= '0';
						sclk			<= '0';						
						rx_reg_0			<= (others => '0');
						rx_reg_1			<= (others => '0');
						
						if (d_samtosam_delay > 0) then 
							d_samtosam_delay <= d_samtosam_delay - 1;
							s_state			 <= spi_idle;
						else
							d_samtosam_delay <= c_samtosam_delay - 1;
							s_state			 <= spi_CNVST_high;
						end if;
						
					when spi_CNVST_high =>
					
						cnvst			<= '1';
						sclk			<= '0';
						rx_reg_0			<= (others => '0');
						rx_reg_1			<= (others => '0');					
	
						if d_CNVST_high > 0 then
							d_CNVST_high <= d_CNVST_high - 1;
							s_state <= spi_CNVST_high;
						else
							s_state <= spi_CNVST_low;
						end if;
					
					when spi_CNVST_low =>
					
						cnvst			<= '0';
						
						if (d_falling_delay > 0) then
							d_falling_delay <= d_falling_delay - 1;
							sclk			<= '0';
						else
							if (cnt_nr_sclk > 0) then 
								if (d_sclk_delay > 0) then
									d_sclk_delay <= d_sclk_delay - 1;
									sclk		 <= sclk;
									cnt_nr_sclk	 <= cnt_nr_sclk;
								else
									d_sclk_delay <= c_sclk_delay - 1;
									sclk		 <= not(sclk);
									cnt_nr_sclk	 <= cnt_nr_sclk - 1;
								end if;
							
								if (cnt_nr_sclk = 0) and (d_sclk_delay > 0) then
									d_sclk_delay <= d_sclk_delay - 1;
									sclk		 <= sclk;
								else
									sclk		 <= not(sclk);
								end if;
							else
							
								sclk <= '0';
							end if;
						end if;
						
						if (sclk = '1') and (d1_sclk = '0') and (cnt_nr_sclk < c_number_sclk )then
							rx_reg_0 <= rx_reg_0(rx_reg_0'left-1 downto 0) & i_miso_0;					
							rx_reg_1 <= rx_reg_1(rx_reg_1'left-1 downto 0) & i_miso_1;
						else
							rx_reg_0 <= rx_reg_0;
							rx_reg_1 <= rx_reg_1;
						end if;
				
						if d_CNVST_low > 0 then 
							d_CNVST_low <= d_CNVST_low - 1;
							s_state <= spi_CNVST_low;
						else
							rx_re_data_0 <= rx_reg_0;
							rx_re_data_1 <= rx_reg_1;
							s_state <= spi_idle;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	o_cnvst <= cnvst;
	o_sclk  <= sclk;
	ov_analog_0	<= rx_re_data_0;
	ov_analog_1 <= rx_re_data_1;
	
end Behavioral;
