----------------------------------------------------------------------------------
-- Company: University of Stuttgart IIS 
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2025/05/09 08:55:06
-- Design Name: 
-- Module Name: fpga_gradient_pmod_da4 - Behavioral
-- Project Name: MRI gradient control
-- Target Devices: ZCU 104
-- Tool Versions: 2023.1
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

entity fpga_gradient_pmod_da4 is
		generic (
			-- the frequency of main clock 
			C_CLK_FREQENCY	 : integer	:= 100;
			-- the frequency of spi clock
			C_SCLK_FREQUENCY : integer	:= 50;
			-- the DAC WIDTH		
			C_GRADIENT_DAC_WIDTH	: integer	:= 12
		);
		Port 
		( 
			o_mosi 				: out   std_logic;
			o_sclk				: out	std_logic;
			o_cs				: out	std_logic;
			clk					: in 	std_logic;
			rstn				: in 	std_logic;
			iv_tx_data			: in 	std_logic_vector(6*C_GRADIENT_DAC_WIDTH-1 downto 0);
			i_tvalid			: in 	std_logic

		);
end fpga_gradient_pmod_da4;

architecture Behavioral of fpga_gradient_pmod_da4 is
	
	CONSTANT 	C_SCLK_DELAY : integer := (C_CLK_FREQENCY/(2*C_SCLK_FREQUENCY)) ;
		
	CONSTANT	C_COMMAND_NR : integer := 4;
	
	CONSTANT	C_ADD_NR : integer := 4;
	
	CONSTANT	C_DATA_NR : integer := 12;
	
	CONSTANT 	C_PRE_NR_CLK : integer := 4;
	
	CONSTANT 	C_AFTER_NR_CLK : integer := 8;
	
	CONSTANT 	C_NUMBER_SCLK : integer := C_COMMAND_NR + C_ADD_NR + C_DATA_NR;
	
	CONSTANT	C_NMUBER_COMAND	: integer := 7; -- write to input register n + Updata DAC register ALL
	
	CONSTANT    WIRTE_REGISTER 	: std_logic_vector(3 downto 0) := (others => '0');
	
	CONSTANT    UPDATE_REGISTER : std_logic_vector(3 downto 0) := "0001";
	
	CONSTANT    ALL_DAC_CH 				: std_logic_vector(3 downto 0) := (others => '1');
	
	CONSTANT	DAC_DATA_DontCare 		: std_logic_vector(C_DATA_NR - 1 downto 0) := (others => '0');
	
	CONSTANT    C_DELAY_CS			: integer := 3;
	
	
	signal		delay 				: integer range C_SCLK_DELAY downto 0 := 0;

	signal   	delay_cs			: integer range C_DELAY_CS downto 0 := 0;
	
	signal 		ch_write_address	: unsigned (3 downto 0) := (others => '0');

	type t_state is
	(
		spi_idle,
		spi_before_state,
		spi_active,
		spi_after_state,
		spi_upload_state
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
	counter_after_sclk
	: integer range c_after_nr_clk downto 0 := 0;
	
	signal
	tx_reg
	: std_logic_vector(C_COMMAND_NR + C_ADD_NR + C_DATA_NR - 1 downto 0) := (others => '0');
	
	type t_gradient_array is array (0 to 5) of std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 downto 0);
	signal Gradient : t_gradient_array := (others => (others => '0'));

	
begin
	--  s to p (in Array form)
		process(clk)
		begin
			if rising_edge (clk) then
				if rstn = '0' then
					Gradient	<= (others => (others => '0'));
				else
					for i in 0 to 5 loop
						Gradient(i) <= iv_tx_data(((5 - i + 1) * C_GRADIENT_DAC_WIDTH - 1) downto ((5 - i) * C_GRADIENT_DAC_WIDTH));
					end loop;
				end if;
			end if;
		end process;
		
		
		process(clk)
		begin
			if rising_edge (clk) then
				if rstn = '0' then
				
					s_state 			<= spi_idle;
					delay   			<= 0;
					delay_cs			<= 0;
					tx_reg  			<= (others => '0');
					d1_sclk 			<= '0';
					
					counter_pre_sclk	<= 0;					
					counter_sclk 		<= 0;
					counter_after_sclk	<= 0;
					
					ch_write_address	<= to_unsigned(0,4);
					
													
				else
				
					d1_sclk 			<= sclk;
					s_state 			<= s_state;
					counter_sclk    	<= counter_sclk;
					counter_pre_sclk  	<= counter_pre_sclk;
					counter_after_sclk	<= counter_after_sclk;
					delay_cs			<= delay_cs;
					ch_write_address	<= ch_write_address;
					
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
								counter_after_sclk 	<= c_after_nr_clk -1;
								delay_cs			<= C_DELAY_CS;
								
								ch_write_address	<= to_unsigned(0,4);
								
								if (i_tvalid = '1') then
								
									s_state <= spi_before_state;
									delay   <= c_sclk_delay;
									cs 		<= '0';

									
								else
									s_state <= spi_idle;
									mosi	<= '0';								
								end if;
								
							when spi_before_state =>
								
								cs 				<= '0';
								mosi  			<= '0';
								if ch_write_address <= 5 then 
									tx_reg 			<= WIRTE_REGISTER  & std_logic_vector(ch_write_address) & Gradient(to_integer(ch_write_address)) ;
								else
									tx_reg 			<= UPDATE_REGISTER & ALL_DAC_CH & DAC_DATA_DontCare;
								end if;								
								

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
								
								cs 				<= '0';						
								mosi 			<= tx_reg(tx_reg'left);
							
								if (counter_sclk = 0) and (sclk = '0' and d1_sclk = '1')then -- falling edge
									s_state <= spi_after_state;									
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
							
							when spi_after_state =>

								cs 				<= '0';
								mosi  			<= '0';
								

								if (counter_after_sclk = 0) and (sclk = '0' and d1_sclk = '1')then
									s_state <= spi_upload_state;
		
								else
									s_state <= spi_after_state;
									
									if (delay = 0) then
										sclk <= not(sclk);
									else
										sclk <= sclk;
									end if;
								end if;

								
								if (sclk = '0' and d1_sclk = '1') then
									counter_after_sclk <= counter_after_sclk - 1;							
								else
									counter_after_sclk <= counter_after_sclk;					
								end if;
							
							when spi_upload_state =>
								
								cs 				<= '1';
								mosi  			<= '0';
								if (delay_cs > 0 ) then 
									delay_cs <= delay_cs - 1;
									s_state <= spi_upload_state;
								else
									delay_cs <= C_DELAY_CS;
									
									if (ch_write_address < 6) then 
											ch_write_address 	<= ch_write_address + 1;
											s_state 			<= spi_before_state;
									else
											s_state 			<= spi_idle;
									end if;
									
								end if;
								counter_pre_sclk 	<= c_pre_nr_clk -1;	
								counter_sclk 		<= C_NUMBER_SCLK - 1;
								counter_after_sclk 	<= c_after_nr_clk -1;		
					end case;								
				end if;
			end if;
		end process;
		
		o_mosi 		<= mosi;
		o_sclk		<= sclk;
		o_cs		<= cs;
		
end Behavioral;
