----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/02/21 11:25:26
-- Design Name: 
-- Module Name: fpga_magnet_controller - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity fpga_magnet_controller is
  
  generic
  (
		-- the frequency of main clock 100 MHz 
		C_CLK_FREQENCY : integer 		:= 100000000;
		-- the frequency of spi clock 20 MHz	
		C_SCLK_FREQUENCY : integer 		:= 20000000;
		-- the total number of spi clock in need to config the chip  75 
		C_NUMBER_SCLK : integer 		:= 24;
		-- the useful data width of data  12 bit 
		C_DATA_WIDTH : integer 			:= 24;			
		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32
		
  
  );
  Port 
  ( 
		clk 		: in std_logic;
		-- rest low enable
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
end fpga_magnet_controller;

architecture Behavioral of fpga_magnet_controller is
	-- component declaration
	component fpga_DAC_AD9881 is
	  generic
	  (
			-- the frequency of main clock 100 MHz 
			C_CLK_FREQENCY : integer 		:= 100000000;
			-- the frequency of spi clock 20 MHz	
			C_SCLK_FREQUENCY : integer 		:= 20000000;
			-- the total number of spi clock in need to config the chip  75 
			C_NUMBER_SCLK : integer 		:= 24;
			-- the useful data width of data  12 bit 
			C_DATA_WIDTH : integer 			:= 24;			
			-- Width of S_AXI data bus
			C_S_AXI_DATA_WIDTH	: integer	:= 32
			
	  
	  );
	  Port 
	  ( 
			clk 		: in std_logic;
			-- rest low enable
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
	end component fpga_DAC_AD9881;
	
begin

inst_fpga_DAC_AD9881 : fpga_DAC_AD9881
	generic map
	(
		C_CLK_FREQENCY 		=> C_CLK_FREQENCY,		-- the frequency of main clock 
		C_SCLK_FREQUENCY	=> C_SCLK_FREQUENCY,
		C_NUMBER_SCLK		=> C_NUMBER_SCLK,
		C_DATA_WIDTH 		=> C_DATA_WIDTH,		-- the useful data width of data 
		C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH
	)
	port map (
			clk 	=> clk,
			-- rest low enable
			rst_n 	=> rst_n,
			-- input data from axi bus length 32 bits
			iv_tx_data => iv_tx_data,
			-- tx config data to the chip 
			o_sdi	=> o_sdi,
			-- SPI sclock
			o_sclk 	=> o_sclk,
			-- Chip selection signal
			o_cs	=> o_cs,
			-- load dac
			o_ldac 	=> o_ldac
	);


end Behavioral;
