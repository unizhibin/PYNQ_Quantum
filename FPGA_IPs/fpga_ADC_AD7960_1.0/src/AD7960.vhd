----------------------------------------------------------------------------------
-- Company: universty of stuttgart (IIS)
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 26.08.2022 14:50:48
-- Design Name: 
-- Module Name: AD7960 LVDS FMC eval Board driver - rtl
-- Project Name: NMR EPR
-- Target Devices: 
-- Tool Versions: 2020.1 vivado
-- Description:  
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
-- ! Use standard library ieee
library IEEE;
-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
-- ! Use xilinx library
library UNISIM;
use UNISIM.Vcomponents.all;

entity AD7960 is
  generic
	(
		CLK_FREQ    :  INTEGER := 200 --system clock frequency in MHz
	);  
  port
   (
		i_clk               	: in    std_logic;
		i_reset_n				: in 	std_logic;
		o_data_ready        	: out   std_logic;
		ov_data             	: out   std_logic_vector(17 downto 0);
		o_clk_p                 : out   std_logic;
		o_clk_n                 : out   std_logic;
		o_cnv_p                 : out   std_logic;
		o_cnv_n                 : out   std_logic;
		i_dco_p                 : in    std_logic;
		i_dco_n                 : in    std_logic;
		i_d_p                   : in    std_logic;
		i_d_n                   : in    std_logic
   );
end AD7960;

architecture rtl of AD7960 is

	
	constant 
		TIME_CYC
		: real := 0.200;
	constant 
		TIME_CNVH
		: real := 0.010;		
	constant
		TIME_CYC_CNT
		: integer := integer( real(TIME_CYC) * real(CLK_FREQ));
	constant
		TIME_CNVH_CNT
		: integer := integer(ceil(real(TIME_CNVH) * real(CLK_FREQ)));
	constant
		BIT_CNT
		: integer := 18;
		
	type t_state IS
	(
		IDLE, 
		READ_DATA,
		READ_DONE	
	);
	
	signal
		state
		: t_state := IDLE; -- idle state
	
	signal 
		i_dco,
		i_d,
		o_clk,
		o_cnv,
		rdy_i
		: std_logic := '0';

	signal 
		data_buffer,
		data 
		: std_logic_vector(17 downto 0) := (others => '0');
		
	signal 
		cnt_global           
		: integer range TIME_CYC_CNT - 1 downto 0 := 0;

	signal 
		cnt_cnvh           
		: integer range TIME_CNVH_CNT - 1 downto 0 := 0;

begin
-- clock output 	
	o_clk 	<= i_clk when (state = READ_DATA) else '0';
-- cnv
	o_cnv 	<= '1' when ((state = READ_DATA) and ( cnt_global <= TIME_CNVH_CNT - 1) ) else '0';		
-- data output	
	ov_data <= data;
-- ready signal
	o_data_ready <= rdy_i;
-- control process	
	ctrl_proc : process (i_clk)
	begin
		if rising_edge(i_clk) then
		
			if i_reset_n = '0' then
				
				state <= IDLE;
				cnt_global <= 0;
				rdy_i <= '0';
				data  <= (others => '0');
			else
				
				if cnt_global <= TIME_CYC_CNT - 1 then 
					cnt_global <= cnt_global + 1;
				else
					cnt_global <= 0;
				end if;
				rdy_i  <= '0';
				data   <= data;
				
				case(state) is
				
					when IDLE =>
						
						cnt_global <= 0;
						state <= READ_DATA;
						
					when READ_DATA =>
						
						if cnt_global < BIT_CNT - 1 then 
							state <= READ_DATA;
						else
							state <= READ_DONE;
						end if;
						
					when READ_DONE =>
					
						if cnt_global = TIME_CYC_CNT - 1 then 
							state <= IDLE;
							rdy_i <= '1';
							data <= data_buffer;
						else
							state <= READ_DONE;
						end if;	
					
				end case;
			end if;
		end if;	
	end process;
	
-- data loading process
	DATA_BUFFER_prc: process(i_dco,i_reset_n)										
		begin
			if i_reset_n = '0' then 
			    data_buffer <= (others => '0');
		    else
				if rising_edge(i_dco) then
					data_buffer <= data_buffer(16 downto 0) & i_d;	-- shif
				end if;
			end if;
		end process;
	
	IBUFDS_DCO: IBUFDS							-- input dco 
		  generic map
		  (
			DIFF_TERM            => TRUE,
			IBUF_LOW_PWR         => FALSE,
			IOSTANDARD           => "LVDS"
		  )
		  port map
		  (
			O                    => i_dco,
			I                    => i_dco_p,
			IB                   => i_dco_n
		  );
		  
	IBUFDS_D: IBUFDS							-- input data 
		  generic map
		  (
			DIFF_TERM            => TRUE,
			IBUF_LOW_PWR         => FALSE,
			IOSTANDARD           => "LVDS"
		  )
		  port map
		  (
			O                    => i_d,
			I                    => i_d_p,
			IB                   => i_d_n
		  );
		  
	OBUFDS_CLK: OBUFDS							-- output clock
		  generic map
		  (
			IOSTANDARD           => "LVDS",
			SLEW                 => "FAST"
		  )
		  port map
		  (
			O                    => o_clk_p, 
			OB                   => o_clk_n,
			I                    => o_clk
		  );
		  
	OBUFDS_CNV: OBUFDS							-- output cnv
		  generic map
		  (
			IOSTANDARD           => "LVDS",
			SLEW                 => "FAST"
		  )
		  port map
		  (
			O                    => o_cnv_p, 
			OB                   => o_cnv_n,
			I                    => o_cnv
		  );
	  
end rtl;