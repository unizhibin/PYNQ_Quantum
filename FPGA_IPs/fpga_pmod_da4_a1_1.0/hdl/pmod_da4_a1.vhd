----------------------------------------------------------------------------------
-- Company: University of Stuttgart IIS 
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2024/07/11 1 
-- Design Name: Pmod driver
-- Module Name: fpga_pmod_da4_a1 - Behavioral
-- Project Name: AI Shimming
-- Target Devices: ZCU104
-- Tool Versions: Vivado 2023.1
-- Tool Versions: Vivado 2022.1
-- Description: 
-- driver for AD5268 with axi interface
-- Dependencies: 
-- 
-- Revision 1.2 - By CYT, attempt to enable last Byte of not cares for trigger interal REF 
-- Revision:1.1
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

entity fpga_pmod_da4_a1 is
	generic 
	(
		-- the frequency of main clock 
		C_CLK_FREQENCY	 : integer	:= 100;
		-- the frequency of spi clock
		C_SCLK_FREQUENCY : integer	:= 50;
		-- data width from axi bus
		C_S_AXI_DATA_WIDTH : integer	:= 32;
		
		C_COMMAND_NR : integer := 4;
		C_ADD_NR : integer := 4;
		C_DATA_NR : integer := 12;
		-- number of not cares in the last byte, the last bit is the trigger for internal REF
		C_LASTNC_NR: integer :=  8
		
	);
	Port 
	( 
		clk 		: in 	std_logic;
		rstn 		: in 	std_logic;
		iv_tx_data 	: in 	std_logic_vector(C_COMMAND_NR + C_ADD_NR + C_DATA_NR + C_LASTNC_NR - 1 downto 0);
		o_mosi_shim 		: out   std_logic;
		o_sclk_shim		: out	std_logic;
		o_cs_shim		: out   std_logic;
		i_tx_start  : in 	std_logic
	);
end fpga_pmod_da4_a1;

architecture Behavioral of fpga_pmod_da4_a1 is
	
	constant c_sclk_delay : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) ;
	
	constant c_pre_nr_clk : integer := 4;
	
	--constant c_after_nr_clk : integer := 8;
	
	constant C_NUMBER_SCLK : integer := C_COMMAND_NR + C_ADD_NR + C_DATA_NR + C_LASTNC_NR;
	
	signal delay : integer range (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) downto 0 := 0;
		
	type t_state is
	(
		spi_idle,
		spi_before_state,
		spi_active 
		--spi_after_state
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

	-- signal
	-- counter_after_sclk
	-- : integer range c_after_nr_clk downto 0 := 0;
	
	signal
	tx_re_data,
	tx_reg
	: std_logic_vector(C_COMMAND_NR + C_ADD_NR + C_DATA_NR + C_LASTNC_NR - 1 downto 0) := (others => '0');
	
begin
		process(clk)
		begin
			if rising_edge (clk) then
				if rstn = '0' then
					s_state <= spi_idle;
					delay   <= 0; 	-- reset the spi clock delay counter
					tx_reg  <= (others => '0');
					d1_sclk <= '0';
					tx_re_data <= (others => '0');
				else 
					
					d1_sclk <= sclk;
					s_state <= s_state;
					tx_re_data <= iv_tx_data;
					
					if (delay > 0) then 
						delay <= delay - 1;
					else 
						delay <= c_sclk_delay;
					end if;
					
					case s_state is
						
						when spi_idle =>
						
							cs 					<= '1';
							counter_sclk 		<= C_NUMBER_SCLK - 1;
							sclk				<= '0';
							counter_pre_sclk 	<= c_pre_nr_clk -1;
							-- counter_after_sclk 	<= c_after_nr_clk -1;
							
							if (i_tx_start = '1') then
							
								s_state <= spi_before_state;
								delay   <= c_sclk_delay;
								cs 		<= '0';
								tx_reg 	<= tx_re_data;
								
							else
								s_state <= spi_idle;
								mosi	<= '0';								
							end if;
							
						when spi_before_state =>
						
							cs <= '0';
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
						
							cs <= '0';						
							mosi 			<= tx_reg(tx_reg'left);
							
							if (counter_sclk = 0) and (sclk = '0' and d1_sclk = '1')then -- falling edge
								-- s_state <= spi_after_state;
								s_state <= spi_idle;
							else
								s_state <= spi_active;
								if (delay = 0) then
									sclk <= not(sclk);
								else
									sclk <= sclk;
								end if;
							end if;
							
							if (sclk = '0' and d1_sclk = '1') then
								counter_sclk <= counter_sclk - 1;							
								tx_reg  <= tx_reg(tx_reg'left - 1 downto 0) & '0';
							else
								counter_sclk <= counter_sclk;							
								tx_reg  <= tx_reg;
							end if;

						-- when spi_after_state =>

						-- 	cs 				<= '0';
						-- 	counter_sclk    <= counter_sclk;
						-- 	mosi  			<= '0'; 
						-- 	if (counter_after_sclk = 0) and (sclk = '0' and d1_sclk = '1')then 
						-- 		s_state <= spi_idle;
						-- 	else
						-- 		s_state <= spi_after_state;
						-- 		if (delay = 0) then
						-- 			sclk <= not(sclk);
						-- 		else
						-- 			sclk <= sclk;
						-- 		end if;
						-- 	end if;
							
						-- 	if (sclk = '0' and d1_sclk = '1') then
						-- 		counter_after_sclk <= counter_after_sclk - 1;							
						-- 	else
						-- 		counter_after_sclk <= counter_after_sclk;					
						-- 	end if;
							
					end case; 
				end if;
			end if;	
		end process;
		o_mosi_shim 		<= mosi;
		o_sclk_shim		<= sclk;
		o_cs_shim		<= cs;

end Behavioral;
