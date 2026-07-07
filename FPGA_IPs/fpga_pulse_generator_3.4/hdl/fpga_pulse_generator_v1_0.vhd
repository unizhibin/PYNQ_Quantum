library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.fpga_pulse_gen_pkg.ALL;
entity fpga_pulse_generator_v1_0 is
	generic (
		-- Users to add parameters here
		C_GRADIENT_DAC_WIDTH	: integer := 12;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 10
	);
	port (
		-- Users to add ports here
		o_tx_pulse								: OUT std_logic; 	--tx pulse
		o_rx_pulse								: OUT std_logic; 	--rx pulse			
		ov_config_dds_data_ch0					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output
		o_config_tvalid_ch0						: OUT std_logic; -- DDS valid signal output		
		ov_config_dds_data_ch1					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output	
		o_config_tvalid_ch1						: OUT std_logic; -- DDS valid signal output	
		o_dds_rstn								: OUT std_logic; 		
		o_mux_ch								: OUT std_logic;
		o_pulse_gen_led							: OUT std_logic;
		ov_gradient_tdata						: OUT std_logic_vector(6*C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		o_gradient_tvalid						: OUT std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end fpga_pulse_generator_v1_0;

architecture arch_imp of fpga_pulse_generator_v1_0 is

	-- component declaration
	component fpga_pulse_generator_v1_0_S00_AXI is
		generic (
		C_GRADIENT_DAC_WIDTH	: integer 	:= 14;		
		C_S_AXI_DATA_WIDTH		: integer	:= 32;
		C_S_AXI_ADDR_WIDTH		: integer	:= 10
		);
		port (
		o_tx_pulse								: OUT std_logic; 	--tx pulse
		o_rx_pulse								: OUT std_logic; 	--rx pulse			
		ov_config_dds_data_ch0					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output
		o_config_tvalid_ch0						: OUT std_logic; -- DDS valid signal output		
		ov_config_dds_data_ch1					: OUT std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0); -- DDS config data output	
		o_config_tvalid_ch1						: OUT std_logic; -- DDS valid signal output	
		o_dds_rstn								: OUT std_logic; 		
		o_mux_ch								: OUT std_logic;
		o_pulse_gen_led							: OUT std_logic;
		ov_gradient_x							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_y							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_z							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_x_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_y_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_z_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );	
		o_gradient_tvalid						: OUT std_logic;		
		S_AXI_ACLK		: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA		: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB		: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP		: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA		: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP		: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component fpga_pulse_generator_v1_0_S00_AXI;
	
	signal gradient_x   	: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	signal gradient_y		: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	signal gradient_z		: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	signal gradient_x_ref	: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	signal gradient_y_ref	: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	signal gradient_z_ref	: std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 ):= (others => '0' );
	
begin

-- Instantiation of Axi Bus Interface S00_AXI
fpga_pulse_generator_v1_0_S00_AXI_inst : fpga_pulse_generator_v1_0_S00_AXI
	generic map (
		C_GRADIENT_DAC_WIDTH 	=> C_GRADIENT_DAC_WIDTH,
		C_S_AXI_DATA_WIDTH		=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH		=> C_S00_AXI_ADDR_WIDTH
	)
	port map
	(
		o_tx_pulse					 		=> o_tx_pulse,					-- transmitter activation pulse
		o_rx_pulse					 		=> o_rx_pulse,					-- receiver activation pulse
		ov_config_dds_data_ch0				=> ov_config_dds_data_ch0,
		o_config_tvalid_ch0					=> o_config_tvalid_ch0,
		ov_config_dds_data_ch1				=> ov_config_dds_data_ch1,
		o_config_tvalid_ch1					=> o_config_tvalid_ch1,
		o_dds_rstn							=> o_dds_rstn,		
		o_mux_ch							=> o_mux_ch,
		o_pulse_gen_led						=> o_pulse_gen_led,
		ov_gradient_x						=> gradient_x,
		ov_gradient_y						=> gradient_y,
		ov_gradient_z						=> gradient_z,
		ov_gradient_x_ref					=> gradient_x_ref,
		ov_gradient_y_ref					=> gradient_y_ref,
		ov_gradient_z_ref					=> gradient_z_ref,
		o_gradient_tvalid					=> o_gradient_tvalid,		
		S_AXI_ACLK		=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA		=> s00_axi_wdata,
		S_AXI_WSTRB		=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP		=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA		=> s00_axi_rdata,
		S_AXI_RRESP		=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
	ov_gradient_tdata <= gradient_x & gradient_y & gradient_z & gradient_x_ref & gradient_y_ref & gradient_z_ref;
	-- User logic ends

end arch_imp;
