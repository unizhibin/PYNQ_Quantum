library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpga_DAC_AD9767_v1_0_S00_AXIS is
	generic (
		-- Users to add parameters here
		C_DAC_RESOLUTION          : integer  := 14;

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 16
	);
	port (
		-- Users to add ports here
		ov_dac_data       : out std_logic_vector(C_DAC_RESOLUTION - 1 downto 0);
		o_clk_dac		  : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end fpga_DAC_AD9767_v1_0_S00_AXIS;

architecture arch_imp of fpga_DAC_AD9767_v1_0_S00_AXIS is

	constant   C_OFFSET  									
	: std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0):= "1000000000000000";
	signal     clk_div
	: std_logic := '0';
	signal 	   d1_data,data_i,data_o
	: std_logic_vector(C_S_AXIS_TDATA_WIDTH - 1 downto 0) := (others => '0');
begin
	process (S_AXIS_ACLK) -- to generate the output clk
	begin
		if rising_edge (S_AXIS_ACLK) then
			-- clk_div    		<= not(clk_div);
			data_i			<= S_AXIS_TDATA;
			data_o			<= data_i xor C_OFFSET;
			--if (clk_div = '1') then
				d1_data	<= data_o;
			--end if;
        end if;
	end process;
	
	ov_dac_data <= d1_data(C_S_AXIS_TDATA_WIDTH - 1 downto C_S_AXIS_TDATA_WIDTH - C_DAC_RESOLUTION); -- output data
	o_clk_dac	<= S_AXIS_ACLK;
	S_AXIS_TREADY <= '1';
	
end arch_imp;
