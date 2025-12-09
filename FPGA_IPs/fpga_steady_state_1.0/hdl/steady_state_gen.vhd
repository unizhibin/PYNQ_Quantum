----------------------------------------------------------------------------------
-- Company: university of stuttgart
-- Engineer: Zhibin Zhao
-- 
-- Create Date: 2023/03/08 09:23:58
-- Design Name: steady state NMR generator
-- Module Name: steady_state_gen - Behavioral
-- Project Name: NMR TÜbingen
-- Target Devices:  PYNQ-Z2
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

entity steady_state_gen is
    Port ( 
			clk 		: in STD_LOGIC;
			rstn 		: in STD_LOGIC;
			i_mux 		: in STD_LOGIC;		   
			i_en 		: in STD_LOGIC;
			iv_f0 		: in STD_LOGIC_VECTOR (31 downto 0);
			iv_f1 		: in STD_LOGIC_VECTOR (31 downto 0);
			o_rstn_dds  : out STD_LOGIC;		   
			m_axis_config_tdata_dds0 	: out std_logic_vector(63 downto 0);
			m_axis_config_tvalid_dds0	: out std_logic;		
			m_axis_config_tdata_dds1 	: out std_logic_vector(63 downto 0);
			m_axis_config_tvalid_dds1	: out std_logic;			
			s_axis_phase_tdata_dds0		: in  std_logic_vector(31 downto 0 );
			s_axis_phase_tvalid_dds0	: in  std_logic;
			s_axis_phase_tdata_dds1		: in  std_logic_vector(31 downto 0 );
			s_axis_phase_tvalid_dds1	: in  std_logic
		  );
end steady_state_gen;

architecture Behavioral of steady_state_gen is

constant
	c_dds_phase_full_range
	:signed(31 downto 0):= (others =>'1'); -- 30 bit phase data width 2pi
	
signal
	dds0_config_tvalid,
	dds1_config_tvalid,
	d1_dds0_config_tvalid,
	d1_dds1_config_tvalid,	
	mux,
	d1_mux,
	rstn_dds
	: std_logic:= '0';
	
signal
	d1_f0,
	d1_f1, 
	d1_phase_data_dds0,
	d1_phase_data_dds1
	: std_logic_vector(31 downto 0) := (others=>'0');
signal
	d1_phase_diff
	: signed(31 downto 0) := (others=>'0');
	
signal
	config_tdata_dds0,
	config_tdata_dds1,
	d1_config_tdata_dds0,
	d1_config_tdata_dds1	
	: std_logic_vector(63 downto 0) := (others => '0');

type t_state is
	(
		s_idle,
		s_start,
		s_wait,
		s_mux_re,
		s_mux_fe
	);
signal
	s_state : t_state := s_idle;
	
begin
	process(clk)
	begin
		if rising_edge (clk) then
			if rstn = '0' then
				d1_phase_data_dds0 		<= (others => '0');
			else 
				d1_phase_data_dds0 <= s_axis_phase_tdata_dds0;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge (clk) then
			if rstn = '0' then
				d1_phase_data_dds1 		<= (others => '0');
			else 
				d1_phase_data_dds1 <= s_axis_phase_tdata_dds1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge (clk) then
			if rstn = '0' then
				d1_phase_diff 	<= (others => '0');
			else 
				d1_phase_diff 	<=  signed(s_axis_phase_tdata_dds0) - signed(s_axis_phase_tdata_dds1);
			end if;
		end if;
	end process;	
	
	process (clk)
	begin
		if rising_edge (clk) then
		
				mux 						<= i_mux;
				d1_mux						<= mux;
				d1_config_tdata_dds0 		<= config_tdata_dds0;
				d1_config_tdata_dds1 		<= config_tdata_dds1;
				dds0_config_tvalid			<= '0';
				dds1_config_tvalid			<= '0';
				d1_dds0_config_tvalid			<= dds0_config_tvalid;
				d1_dds1_config_tvalid			<= dds1_config_tvalid;
				rstn_dds						<= '1';
				
			if rstn = '0' then
			
				d1_mux 					<= '0';	
				config_tdata_dds0 		<= (others =>'0');
				d1_config_tdata_dds0 	<= (others =>'0');
				config_tdata_dds1 		<= (others =>'0');
				d1_config_tdata_dds1 	<= (others =>'0');
				
				dds0_config_tvalid	<= '0';
				dds1_config_tvalid	<= '0';
				d1_dds0_config_tvalid <= '0';
				d1_dds1_config_tvalid <= '0';
				
				rstn_dds		    <= '0';		
				s_state				<= s_idle;
			else
				case s_state is
					
					when s_idle =>
						
						config_tdata_dds0 		 <= (others =>'0');
						config_tdata_dds1 		 <= (others =>'0');						
						dds0_config_tvalid 		 <= '1';
						dds1_config_tvalid 		 <= '1';
						
						s_state 			 	 <= s_start;

					when s_start =>
						
						if i_en = '1' then
							
							config_tdata_dds0( iv_f0'length - 1  downto 0) 	<= iv_f0;
							config_tdata_dds1( iv_f1'length - 1  downto 0) 	<= iv_f1;
							dds0_config_tvalid 	<=  '1';
							dds1_config_tvalid 	<=  '1';							
							s_state 	        <=  s_wait;
							rstn_dds		    <= '1';									
						else
						
							config_tdata_dds0 	<=  (others =>'0');
							config_tdata_dds1 	<=  (others =>'0');								
							dds0_config_tvalid 	<=  '0';
							dds1_config_tvalid 	<=  '0';
							s_state 			<=  s_idle;
							rstn_dds		    <= '0';	
							
						end if;
						
					when s_wait =>
						
						if i_en = '1' then 
						
							if (d1_mux = '0') and (mux = '1') then				-- rising edge 
								s_state <= s_mux_re;
							elsif (d1_mux = '1') and (mux = '0') then
								s_state <= s_mux_fe;	
							elsif (d1_mux = mux) then
								s_state <= s_wait;
							end if;
							
						else
							s_state  <=  s_idle;
						end if;
						
					when s_mux_re =>
					
						config_tdata_dds1 	<= std_logic_vector(to_unsigned(0,32)) & iv_f1;--std_logic_vector(unsigned(s_axis_phase_tdata_dds0) + to_unsigned(9*(to_integer(unsigned(iv_f1))),32)) & iv_f1;
						dds1_config_tvalid 	<=  '1';
						s_state 			<= s_wait;	
						rstn_dds		    <=  '0';
							
					when s_mux_fe =>
							
						s_state 			<= s_wait;
						
				end case;
			end if;
		end if;
	end process;
	
			m_axis_config_tdata_dds0  	<= d1_config_tdata_dds0;
			m_axis_config_tvalid_dds0	<= d1_dds0_config_tvalid;
			m_axis_config_tdata_dds1 	<= d1_config_tdata_dds1;
			m_axis_config_tvalid_dds1	<= d1_dds1_config_tvalid;	
			o_rstn_dds					<= rstn_dds;
			
end Behavioral;
