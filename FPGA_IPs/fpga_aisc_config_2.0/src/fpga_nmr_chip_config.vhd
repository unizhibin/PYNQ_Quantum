----------------------------------------------------------------------------------
-- Company:  Universty of stuttgart IIS 
-- Engineer: Zhibin Zhao 
-- 
-- Create Date: 2022/10/12 13:08:47
-- Design Name: 
-- Module Name: fpga_nmr_chip_config - Behavioral
-- Project Name: the pre state is for heiko chip
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- V 1.0 Chip configuration for nmr
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
		C_SCLK_FREQUENCY : integer 		:= 100;
		-- the total number of spi clock in need to config the chip  75 
		C_NUMBER_SCLK : integer 		:= 75;		
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32
  
  );
  Port 
  ( 
		-- input axi main clock
		clk 		: in std_logic;
		-- rest low enable
		rst_n 		: in std_logic;
		-- control command from axi bus start spi bus transfer the configuration data to the chip
		i_tx_start : in std_logic;		
		-- input data from axi bus length 32 bits
		iv_tx_config_nmr_data : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- input data from axi bus length 32 bits
		iv_tx_config_adc_data : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- input number of effective bits information for configuration NMR chip
		iv_nmr_effective_bits_nr  : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- input number of effective bits information for configuration adc chip
		iv_adc_effective_bits_nr  : in std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
		-- tx config data to the chip 
		o_mosi : out std_logic;
		-- SPI sclock
		o_sclk : out std_logic;
		-- Chip selection signal
		o_cs_NMR : out std_logic;
		-- Chip selection signal		
		o_cs_ADC : out std_logic
  );
end fpga_nmr_chip_config;

architecture Behavioral of fpga_nmr_chip_config is

	constant c_sclk_delay : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) - 1;
	
	signal   delay 		  : integer range (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY))- 1 downto 0 := 0;
	
	
	
	type t_state is
	(
		spi_idle,
		spi_active_NMR,
		spi_deactive,
		spi_active_ADC,
		spi_etx
	);
	
	signal
	s_state 
	: t_state := spi_idle;
	
	signal
	cs_nmr,
	cs_adc,
	mosi,
	sclk,
	d1_sclk
	: std_logic := '0';
	
	signal
	counter_sclk,
	counter_nmr_config,
	counter_adc_config
	: integer range C_NUMBER_SCLK downto 0 := 0;

	
	signal
	tx_re_data,
	tx_reg
	: std_logic_vector(C_NUMBER_SCLK - 1 downto 0) := (others => '0');
	
	
begin
	-- process for reform the input data from axi bus
	-- | NMR useful config data -0...0- ADC useful config data |--
		process(clk)
		begin
			if rising_edge (clk) then 
				if rst_n = '0' then -- reset the data when reset low  
					tx_re_data <= (others => '0'); 
				else
				
					tx_re_data(C_NUMBER_SCLK - 1 downto C_NUMBER_SCLK - C_S_AXI_DATA_WIDTH ) <= iv_tx_config_nmr_data; -- clock in register slove timing problem
					
					tx_re_data(C_S_AXI_DATA_WIDTH - 1 downto 0) <= iv_tx_config_adc_data; 
					
					tx_re_data(C_NUMBER_SCLK - C_S_AXI_DATA_WIDTH - 1  downto C_S_AXI_DATA_WIDTH) <= (others =>'0');
					
				end if;
			end if;
		end process;
				
		process(clk)
		begin
			if rising_edge (clk) then
				if rst_n = '0' then
					s_state <= spi_idle;
					delay <= 0; 					-- reset the spi clock delay counter
					counter_sclk 			<= 0;
					counter_nmr_config 		<= 0;
					counter_adc_config		<= 0;
					cs_nmr 					<= '1';
					cs_adc					<= '0';
					mosi					<= '0';
					sclk					<= '0';
					d1_sclk 				<= '0';
					tx_reg 					<= (others => '0');						
				else 
					
					s_state <= s_state;
					
					if (delay > 0) then 
						delay <= delay - 1;
					else 
						delay <= c_sclk_delay;
					end if;
					
								
					if (delay = 0) then
						sclk <= not(sclk);
					else
						sclk <= sclk;
					end if;
					
					d1_sclk <= sclk;
					
					case s_state is 
						
						when spi_idle =>

							sclk				<= '0';							
							counter_sclk 		<=  C_NUMBER_SCLK;
							counter_nmr_config  <=  0 ;
							counter_adc_config  <=  0 ;
							cs_nmr 				<= '1';
							cs_adc				<= '0';
							mosi				<= '0';	
							if (i_tx_start = '1') then
								s_state 	<= spi_active_NMR;
								delay   	<= c_sclk_delay;
								tx_reg 		<= tx_re_data;
								counter_nmr_config  <=  to_integer(unsigned(iv_nmr_effective_bits_nr));
								counter_adc_config  <=  to_integer(unsigned(iv_adc_effective_bits_nr));								
								cs_nmr 				<= '0';
							else
								s_state 	<= spi_idle;
							end if;
							
						when spi_active_NMR =>
							
							-- state change 
							
							if (counter_sclk = C_NUMBER_SCLK - C_S_AXI_DATA_WIDTH) and (sclk = '1' and d1_sclk = '0')then
								s_state <= spi_deactive;
							else
								s_state <= spi_active_NMR;
							end if;
							
							-- clock counter and output mosi
							
							if (sclk = '1' and d1_sclk = '0') then
								counter_sclk <= counter_sclk - 1;							
								tx_reg  	 <= tx_reg(tx_reg'left - 1 downto 0) & '0';
							else
								counter_sclk <= counter_sclk;							
								tx_reg  	 <= tx_reg;
							end if;
							mosi 			<= tx_reg(tx_reg'left); 
							
							-- cs control 
							
							if 	(counter_sclk >= C_NUMBER_SCLK - counter_nmr_config) then 
								cs_nmr <= '0';
							else
								cs_nmr <= '1';
							end if;
							
							cs_adc <= '0';
						
						when spi_deactive =>

							-- state change 
							
							if (counter_sclk = counter_adc_config) and (sclk = '0' and d1_sclk = '1') then
								s_state <= spi_deactive;
							else
								s_state <= spi_active_ADC;
							end if;
							
							-- clock counter and output mosi
							
							if (sclk = '1' and d1_sclk = '0') then
								counter_sclk <= counter_sclk - 1;							
								tx_reg  	 <= tx_reg(tx_reg'left - 1 downto 0) & '0';
							else
								counter_sclk <= counter_sclk;							
								tx_reg  	 <= tx_reg;
							end if;
							
							mosi 			<= '0'; 
							
							-- cs control
							cs_nmr <= '1';	
							cs_adc <= '0';							
						
						when spi_active_ADC => 

							-- state change 							
							if (counter_sclk = 0) and (sclk = '1' and d1_sclk = '0')then
								s_state <= spi_etx;
							else
								s_state <= spi_active_ADC;
							end if;
							
							-- clock counter and output mosi
							
							if (sclk = '1' and d1_sclk = '0') then
								counter_sclk <= counter_sclk - 1;							
								tx_reg  	 <= tx_reg(tx_reg'left - 1 downto 0) & '0';
							else
								counter_sclk <= counter_sclk;							
								tx_reg  	 <= tx_reg;
							end if;
							
							mosi 			 <= tx_reg(tx_reg'left);					
						
							-- cs control
							cs_nmr <= '1';
							
							if (counter_sclk >= C_S_AXI_DATA_WIDTH )or(counter_sclk <= C_S_AXI_DATA_WIDTH - counter_adc_config )  then 
								cs_adc <= '0';
							else 
								cs_adc <= '1';
							end if;
						when spi_etx =>
						
							cs_nmr 					<= '1';
							cs_adc					<= '0';
							mosi					<= '0';
							s_state					<= spi_idle;
							
					end case; 
				end if;
			end if;	
		end process;

	o_sclk 	<= d1_sclk when ((s_state = spi_active_NMR) or (s_state = spi_deactive) or (s_state = spi_active_ADC)) else '0';
	o_mosi 	<= mosi;
	o_cs_NMR	<= cs_nmr;
	o_cs_adc	<= cs_adc;
	
end Behavioral;
	
