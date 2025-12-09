----------------------------------------------------------------------------------
-- Company: university of stuttgart
-- Engineer: Zhibin Zhao
-- Modified: Dongyan Zhu
-- Create Date: 2023/02/21 11:29:37
-- Design Name: fpga dac AD9881 driver form: SPI
-- Module Name: fpga_DAC_AD9881 - Behavioral
-- Project Name: magnet controller 
-- Target Devices: PYNQ - Z2
-- Tool Versions: 2020.2
-- Description: driver for AD9881 voltage control for the magnet
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity fpga_DAC_AD9881 is
  generic
  (
		-- the frequency of main clock 100 MHz 
		C_CLK_FREQENCY : integer 		:= 100000000;
		-- the frequency of spi clock 20 MHz
		C_SCLK_FREQUENCY : integer 		:= 20000000;
		-- the total number of spi clock in need to config the chip
		C_NUMBER_SCLK : integer 		:= 24;
		-- the useful data width of data 24 bit 
		C_DATA_WIDTH : integer 			:= 24;			
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32
		
  
  );
  Port 
  ( 
		clk 		: in std_logic;
		-- reset low enable
		rst_n 		: in std_logic;
		-- input data from axi bus length 32 bits
		iv_tx_data 	: in std_logic_vector (C_S_AXI_DATA_WIDTH - 1 downto 0); 
 		-- tx config data to the chip 
		o_sdi : out std_logic;
		-- SPI sclock
		o_sclk : out std_logic;
		-- Chip selection signal
		o_cs : out std_logic;
		-- load dac
		o_ldac : out std_logic
  );
end fpga_DAC_AD9881;

architecture Behavioral of fpga_DAC_AD9881 is
	
	constant 
	C_SCLK_DELAY : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)); --100/(100/(2*x))
    -- C_SCLK_DELAY : integer := 9; --5MHz
	
	constant 
	C_CS_DELAY 	 : integer := 13; -- delay 13 clk for cs

	constant 
	C_LDAC_high_DELAY 	 : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY))*4; -- delay 3 clk for cs
	
	constant 
	C_LDAC_low_DELAY 	 : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY))*4; -- delay 4 clk for cs
	
	constant
	C_SAMTOSAM_DELAY  : integer := 450; -- delay  times clk sample between sample  <200kSPS
	
	
	signal 
	d_SCLK_delay : integer range (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) downto 0 := 0;
    -- d_SCLK_delay : integer range C_SCLK_DELAY downto 0 := 0;
	
	signal
	d_CS_delay : integer range 13 downto 0 := C_CS_DELAY;
	
	signal
	d_LDAC_high_delay : integer range 8 downto 0 := C_LDAC_high_DELAY;
	
	signal
	d_LDAC_low_delay : integer range 8 downto 0 := C_LDAC_low_DELAY;
	
	signal
	d_SAMTOSAM_delay : integer range 450 downto 0 := C_SAMTOSAM_DELAY;
	
	type t_state is
	(
		spi_idle,
		spi_active,
		spi_etx,
		spi_wait
	);
	
	signal
	s_state 
	: t_state := spi_idle;
	
	signal
	counter_sclk
	: integer range C_NUMBER_SCLK - 1 downto 0 := 0;
	
	signal
	tx_re_data,
	tx_reg
	: std_logic_vector(C_NUMBER_SCLK - 1 downto 0) := (others => '0');
	
	signal
	cs,
	sdi,
	sclk,
	d1_sclk
	: std_logic := '0';
	
	signal
	ldac
	: std_logic := '1';
	
begin
	-- process for reform the input data from axi bus
		process(clk)
		begin 
			if rising_edge (clk) then 
				if rst_n = '0' then -- reset the data when reset low  
					tx_re_data <= (others => '0'); 
				else 
					tx_re_data(C_NUMBER_SCLK - 1 downto C_NUMBER_SCLK - C_DATA_WIDTH) <= iv_tx_data(C_DATA_WIDTH - 1 downto 0); -- clock in register slove timing problem
				end if;
			end if;	
		end process;
		
		process(clk)
		begin
			if rising_edge (clk) then 
				if rst_n = '0' then 
					s_state 			<= spi_idle;
					d_SCLK_delay 		<= 0; 				-- reset the spi clock d_SCLK_delay counter
					d_SCLK_delay   		<= 0;
					d_LDAC_high_delay 	<= 0;
					d_LDAC_low_delay  	<= 0;								
					counter_sclk 		<= 0;					
					tx_reg 				<= (others => '0');
					d1_sclk 			<= '0';
				else 
					d1_sclk <= sclk;
					s_state <= s_state;
					
					if (d_SCLK_delay > 0) then 
						d_SCLK_delay <= d_SCLK_delay - 1;
					else 
						d_SCLK_delay <= c_sclk_delay;
					end if;
					
						case s_state is 
							when spi_idle =>
								sdi				<= '0';
								ldac 			<= '1';
								sclk			<= '0';
								d_SCLK_delay   	<= C_SCLK_DELAY;
								d_LDAC_high_delay <= C_LDAC_high_DELAY;
								d_LDAC_low_delay  <= C_LDAC_low_DELAY;
								d_SAMTOSAM_delay <= C_SAMTOSAM_DELAY;										
								counter_sclk 	<= C_NUMBER_SCLK - 1;
								tx_reg 			<= tx_re_data;									
								if (d_CS_delay > 0) then 
									cs 				<= '1';
									d_CS_delay		<= d_CS_delay - 1;
									s_state 		<= spi_idle;
								else
									cs 				<= '0';								
									d_CS_delay		<= C_CS_DELAY;
									s_state 		<= spi_active;						
								end if;
							when spi_active =>
								
								cs 				<= '0';
								sdi 			<= tx_reg(tx_reg'left);
								ldac 			<= '1';
								
								if (counter_sclk = 0) and (sclk = '0' and d1_sclk = '1')then 
									cs 		<= '1';	
									ldac 	<= '1';
									s_state <= spi_etx;
								else								
									s_state <= spi_active;
									if (d_SCLK_delay = 0) then
										sclk <= not(sclk);
									else
										sclk <= sclk;
									end if;
								end if;
								
								if (sclk = '0' and d1_sclk = '1') then
									counter_sclk 	<= counter_sclk - 1;							
									tx_reg 	 		<= tx_reg(tx_reg'left - 1 downto 0) & '0';
								else
		
									counter_sclk 	<= counter_sclk;							
									tx_reg  		<= tx_reg;
									
								end if;
			
							when spi_etx =>
				
								cs 				<= '1';
								sdi				<= '0';
								sclk			<= '0';
								if (d_LDAC_high_delay > 0) then 
									ldac 			<= '1';
									d_LDAC_high_delay	<= d_LDAC_high_delay - 1;
									s_state			<= spi_etx;
								elsif (d_LDAC_low_delay > 0) and (d_LDAC_high_delay = 0)  then
										ldac 		<= '0';
										d_LDAC_low_delay <= d_LDAC_low_delay - 1;
										s_state			<= spi_etx;
								elsif (d_LDAC_low_delay = 0) and (d_LDAC_high_delay = 0)  then
										ldac 		<= '1';								
										s_state		<= spi_wait;

								end if;
                                
							when spi_wait =>

								cs 				<= '1';
								sclk			<= '0';								
								sdi				<= '0';
								ldac 			<= '1';
								if (d_SAMTOSAM_delay > 0) then
									s_state <= spi_wait;
									d_SAMTOSAM_delay <= d_SAMTOSAM_delay - 1;
								else
									s_state <= spi_idle;					
								end if;
						end case; 
				end if;
			end if;	
		end process;

 		-- tx config data to the chip 
		o_sdi  <= sdi;
		-- SPI sclock
		o_sclk <= sclk;
		-- Chip selection signal
		o_cs   <= cs;
		-- load dac
		o_ldac <= ldac;
		
end Behavioral;
