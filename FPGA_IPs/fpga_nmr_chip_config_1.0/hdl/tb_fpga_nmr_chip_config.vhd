----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/10/12 16:22:52
-- Design Name: 
-- Module Name: tb_fpga_nmr_chip_config - Behavioral
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

entity tb_fpga_nmr_chip_config is
--  Port ( );
end tb_fpga_nmr_chip_config;

architecture Behavioral of tb_fpga_nmr_chip_config is
 -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT fpga_nmr_chip_config
	  generic
	  (
			-- the frequency of main clock 250 MHz 
			C_CLK_FREQENCY : integer 		:= 100000000;
			-- the frequency of spi clock 100 Hz	
			C_SCLK_FREQUENCY : integer 		:= 100;
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
			iv_tx_data 	: in std_logic_vector (63 downto 0); 
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
  END COMPONENT;
  
  signal
	clk,
	rst,
	mosi,
	sclk,
	cs,
	start,
	busy,
	done
	: std_logic := '0';
  signal
	tx_data
	:std_logic_vector (63 downto 0) := (others =>'0');
  
begin
  -- Instantiate the Unit Under Test (UUT)
  uut: fpga_nmr_chip_config
	GENERIC MAP
	(	
		C_CLK_FREQENCY =>   1000000000,		-- the frequency of main clock 
		C_SCLK_FREQUENCY => 10000000,	-- the frequency of spi clock
		C_DATA_WIDTH => 55,			-- the useful data width of data 
		C_S_AXI_DATA_WIDTH => 32	-- data width from axi bus
	)
	PORT MAP
	(
		clk => clk,
		rst_n => '1',
		iv_tx_data => tx_data,
		o_mosi => mosi,
		o_sclk => sclk,
		o_cs => cs,
		i_tx_start => start,
		o_busy	=> busy,
		o_tx_done => done
	);

	clk <= not clk after 5 ns; -- 250 MHz
	
	process
	begin
--		tx_data <= "0000 0000 0000 0000 0000 0101 0000 0111 0000 0000 0000 0000 0000 0101 0000 0111";
        tx_data <= "1011010101111110111111101111111111111111111111111111101000000000";
		wait for 20 ns ;
		start <= '1';
		wait for 10 ns;
		start <= '0';
		wait for 40 us;
	end process;


end Behavioral;
