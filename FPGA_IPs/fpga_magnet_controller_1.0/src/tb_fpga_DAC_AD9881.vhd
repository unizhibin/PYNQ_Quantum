----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2023/02/21 12:55:46
-- Design Name: 
-- Module Name: tb_fpga_DAC_AD9881 - Behavioral
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


entity tb_fpga_DAC_AD9881 is
--  Port ( );
end tb_fpga_DAC_AD9881;

architecture Behavioral of tb_fpga_DAC_AD9881 is
 -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT fpga_DAC_AD9881
	  generic
	  (
	  
		-- the frequency of main clock 250 MHz 
		C_CLK_FREQENCY : integer 		:= 100000000;
		-- the frequency of spi clock 100 Hz	
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
	END COMPONENT;
	
	signal
	clk,
	rst,
	sdi,
	sclk,
	cs
	: std_logic := '0';
	
	signal
	ldac
	: std_logic := '1';
	
	signal
	tx_data
	:std_logic_vector (31 downto 0) := (others =>'0'); 
	
begin
  -- Instantiate the Unit Under Test (UUT)
  uut: fpga_DAC_AD9881
	GENERIC MAP
	(	
		C_CLK_FREQENCY =>  100000000,		-- the frequency of main clock 
		C_SCLK_FREQUENCY => 20000000,	-- the frequency of spi clock
		C_NUMBER_SCLK => 24,			-- the total number of spi clock in need to config the chip 
		C_DATA_WIDTH => 24,			-- the useful data width of data 
		C_S_AXI_DATA_WIDTH => 32	-- data width from axi bus
	)
	PORT MAP
	(
		clk 		=> clk,
		rst_n 		=> '1',
		iv_tx_data 	=> tx_data,
		o_sdi 		=> sdi,
		o_sclk 		=> sclk,
		o_cs 		=> cs,
		o_ldac 		=> ldac
	);

	clk <= not clk after 5 ns; -- 100 MHz
	
		process
		begin
		tx_data <= "00000000000000000000010100000111";
		wait for 4000 ns ;
		end process;
		
end Behavioral;
