library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity dds_mux_v1_0 is
	generic (
		-- Users to add parameters here
		 C_NMR_PULSE_DATA_WIDTH: integer := 32;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S01_AXIS
		C_S01_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
		 i_mux 			: in std_logic;
		 m_axis_tdata 	: out std_logic_vector(C_NMR_PULSE_DATA_WIDTH - 1 downto 0);
		 m_axis_tvalid 	: out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk		: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tdata		: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tvalid		: in std_logic;

		-- Ports of Axi Slave Bus Interface S01_AXIS
		s01_axis_aclk		: in std_logic;
		s01_axis_aresetn	: in std_logic;
		s01_axis_tdata		: in std_logic_vector(C_S01_AXIS_TDATA_WIDTH-1 downto 0);
		s01_axis_tvalid		: in std_logic
	);
end dds_mux_v1_0;

architecture arch_imp of dds_mux_v1_0 is


 signal s0_axis_tdata : std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0):= (others=>'0');
 signal s1_axis_tdata : std_logic_vector(C_S01_AXIS_TDATA_WIDTH-1 downto 0):= (others=>'0');
 signal s0_tvalid : std_logic := '0';
 signal s1_tvalid : std_logic := '0';
 
begin

	process (s00_axis_aclk) is
	begin
		if rising_edge(s00_axis_aclk)then 
			if (s00_axis_aresetn = '0') then
					s0_axis_tdata <= (others => '0');
					s0_tvalid <= '0';
				else
					if (i_mux = '0') then 
						s0_axis_tdata <= s00_axis_tdata ;
						s0_tvalid <= '1';
					else
						s0_axis_tdata <= (others => '0');
						s0_tvalid <= '0';
					end if; 
			end if;
		end if;
	end process;

	process (s01_axis_aclk) is
	begin
		if rising_edge(s01_axis_aclk)then 
			if (s01_axis_aresetn = '0') then
					s1_axis_tdata <= (others => '0');
					s1_tvalid <= '0';
				else
					if (i_mux = '1') then 
						s1_axis_tdata <= s01_axis_tdata ;
						s1_tvalid <= '1';
					else
						s1_axis_tdata <= (others => '0');
						s1_tvalid <= '0';
					end if; 
			end if;
		end if;
	end process;
	
	m_axis_tdata  <= s0_axis_tdata or s1_axis_tdata;
	m_axis_tvalid <= s0_tvalid or s1_tvalid;
	
end arch_imp;
