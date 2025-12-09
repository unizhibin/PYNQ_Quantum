----------------------------------------------------------------------------------
-- Company:  Universty of stuttgart IIS 
-- Engineer: Zhibin Zhao 
-- 
-- Create Date: 2022/10/12 13:08:47
-- Design Name: 
-- Module Name: fpga_nmr_chip_config - Behavioral
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
-- V 1.0 Chip configuration for nmr, SPI data changes on rising edge
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

entity fpga_nmr_chip_config is
  generic
  (
		-- the frequency of main clock 250 MHz 
		C_CLK_FREQENCY : integer 		:= 250000000;
		-- the frequency of spi clock 100 Hz	
		C_SCLK_FREQUENCY : integer 		:= 50;
		-- the total number of spi clock in need to config the chip  75 
		C_NUMBER_SCLK : integer 		:= 75;
		-- the useful data width of data  12 bit 
		C_DATA_WIDTH : integer 			:= 55;			
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32
  
  );
  Port 
  ( 
		-- input axi main clock
		clk 		: in std_logic;
		-- rest low enable
		rst_n 		: in std_logic;
		-- input data from axi bus length 32 bits
		iv_tx_data 	: in std_logic_vector (2*C_S_AXI_DATA_WIDTH - 1 downto 0); 
		-- tx config data to the chip 
		o_mosi : out std_logic;
		-- SPI sclock
		o_sclk : out std_logic;
		-- Chip selection signal
		o_cs : out std_logic;
		-- control command from axi bus start spi bus transfer the configuration data to the chip
		i_tx_start : in std_logic;
		-- output busy signal if busy hight, the transfer not finish
		o_busy	: out std_logic;
		-- ouput pulse transfer done 
		o_tx_done : out std_logic
  
  );
end fpga_nmr_chip_config;

architecture Behavioral of fpga_nmr_chip_config is

	constant c_sclk_delay : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) - 1;
	
	signal delay : integer range (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY))- 1 downto 0 := 0;
	
	constant c_pre_nr_clk : integer := 16;
	
	type t_state is
	(
		spi_idle,
		spi_before_state,
		spi_active,
		spi_etx
	);
	
	signal
	s_state 
	: t_state := spi_idle;
	
	signal
	cs,
	mosi,
	sclk,
	d1_sclk
	: std_logic := '0';
	
	signal
	counter_sclk
	: integer range C_NUMBER_SCLK downto 0 := 0;

	signal
	counter_pre_sclk
	: integer range c_pre_nr_clk downto 0 := 0;
	
	signal
	tx_re_data,
	tx_reg
	: std_logic_vector(C_NUMBER_SCLK - 1 downto 0) := (others => '0');
	
	
begin
	-- process for reform the input data from axi bus
		process(clk)
		begin
			if rising_edge (clk) then 
				if rst_n = '0' then -- reset the data when reset low  
					tx_re_data <= (others => '0'); 
				else
					tx_re_data(C_NUMBER_SCLK - 1 downto C_NUMBER_SCLK - C_DATA_WIDTH) <= iv_tx_data(iv_tx_data'high downto iv_tx_data'high - C_DATA_WIDTH + 1); -- clock in register slove timing problem
				end if;
			end if;
		end process;
		
		process(clk)
		begin
			if rising_edge (clk) then
				if rst_n = '0' then
					s_state <= spi_idle;
					delay <= 0; 	-- reset the spi clock delay counter
					tx_reg <= (others => '0');
					d1_sclk <= '0';
				else
					d1_sclk <= sclk;
					s_state <= s_state;
					
					if (delay > 0) then 
						delay <= delay - 1;
					else 
						delay <= c_sclk_delay;
					end if;
					
					case s_state is 
						
						when spi_idle =>
						
							cs 				<= '1';
							o_tx_done 		<= '0';
							counter_sclk 	<= C_NUMBER_SCLK - 1;
							sclk			<= '0';
							o_busy			<= '0';
							counter_pre_sclk <= c_pre_nr_clk -1;
							
							if (i_tx_start = '1') then 				-- Start signal from AXI interface
								s_state <= spi_before_state;
								delay   <= c_sclk_delay;
								cs 		<= '0';
								tx_reg 	<= tx_re_data;
							else
								s_state <= spi_idle;
								mosi	<= '0';
							end if;
							
						when spi_before_state =>
						
							o_tx_done 		<= '0';
							o_busy			<= '1';
							counter_sclk    <= counter_sclk;
							
							if (counter_pre_sclk = 0) and (sclk = '0' and d1_sclk = '1')then 
								s_state <= spi_active;
							else
								s_state <= spi_before_state;
								if (delay = 0) then
									sclk <= not(sclk);
								else
									sclk <= sclk;
								end if;
							end if;
							
							if (sclk = '0' and d1_sclk = '1') then
								counter_pre_sclk <= counter_pre_sclk - 1;							
							else
								counter_pre_sclk <= counter_pre_sclk;							
							end if;
							
						when spi_active =>
							o_tx_done 		<= '0';
							o_busy			<= '1';
							mosi 			<= tx_reg(tx_reg'left);
							if (counter_sclk = 0) and (sclk = '1' and d1_sclk = '0')then 	-- Rising edge
								s_state <= spi_etx;
							else
								s_state <= spi_active;
								if (delay = 0) then
									sclk <= not(sclk);
								else
									sclk <= sclk;
								end if;
							end if;
							
							if (sclk = '1' and d1_sclk = '0') then
								counter_sclk <= counter_sclk - 1;							
								tx_reg  <= tx_reg(tx_reg'left - 1 downto 0) & '0';		-- Shift spi data to left
							else
								counter_sclk <= counter_sclk;							
								tx_reg  <= tx_reg;
							end if;
							
							if 	(counter_sclk >= C_NUMBER_SCLK - C_DATA_WIDTH) then   	-- For extra clocks, cs inactive
								cs <= '0';
							else
								cs <= '1';								
							end if;
							
						when spi_etx =>
						
							cs 				<= '1';
							o_tx_done 		<= '1';
							mosi			<= '0';
							s_state			<= spi_idle;
							o_busy			<= '0';
							
					end case; 
				end if;
			end if;	
		end process;

	o_sclk 	<= d1_sclk when (s_state = spi_active) or (s_state = spi_before_state)  else '0';
	o_mosi 	<= mosi;
	o_cs	<= cs;	
	
end Behavioral;
	
