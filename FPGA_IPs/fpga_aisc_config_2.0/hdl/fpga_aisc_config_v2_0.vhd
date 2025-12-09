-- rebuild on 10.05.2024

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.Vcomponents.all;

entity fpga_aisc_config_v2_0 is
	generic (
		-- Users to add parameters here
		C_CLK_FREQENCY : integer 		:= 200000000;
		-- the frequency of spi clock 100 Hz	
		C_SCLK_FREQUENCY : integer 		:= 100;
		-- the total number of spi clock in need to config the chip  75 
		C_NUMBER_SCLK : integer 		:= 75;
		-- output bits width 
		C_CIC_output_bitwidth : integer := 16;
		-- Highest order of CIC
		C_CIC_buffer_depth  	: integer := 16;
		-- Convertered signal (from 0/1 to -voltage_level/voltage_level)		
		C_CIC_voltage_level 	: integer := 1;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
		
		-- ADC port Jianyu ADC 
		o_adc_rst	  	: out std_logic;
		ov_data_q       : out std_logic_vector(C_CIC_output_bitwidth - 1 downto 0);
		ov_data_i       : out std_logic_vector(C_CIC_output_bitwidth - 1 downto 0);
		i_d_q_p         : in  std_logic;
		i_d_q_n         : in  std_logic;
		i_d_i_p         : in  std_logic;
		i_d_i_n         : in  std_logic;
		i_ufl_n			: in  std_logic;
		i_ufl_p 		: in  std_logic;
		o_data_i_debug	: out std_logic;
		o_data_q_debug  : out std_logic;
		
		-- NMR Chip config freddy
		o_mosi 				: out std_logic;
		o_sclk 				: out std_logic;
		o_cs_NMR   			: out std_logic;
		o_cs_ADC   			: out std_logic;
		o_clk_n				: out std_logic;  -- differetial clock output
		o_clk_p				: out std_logic;
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
end fpga_aisc_config_v2_0;

architecture arch_imp of fpga_aisc_config_v2_0 is

	-- component declaration
	component fpga_aisc_config_v2_0_S00_AXI is
		generic (
		C_CLK_FREQENCY : integer 		:= 250000000;
		-- the frequency of spi clock 100 Hz	
		C_SCLK_FREQUENCY : integer 		:= 100;
		-- the total number of spi clock in need to config the chip  75 
		C_NUMBER_SCLK : integer 		:= 75;
		-- output bits width 
		C_CIC_output_bitwidth : integer := 16;
		-- Highest order of CIC
		C_CIC_buffer_depth  	: integer := 16;
		-- Convertered signal (from 0/1 to -voltage_level/voltage_level)		
		C_CIC_voltage_level 	: integer := 1;
		
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
		);
		port (
		-- ADC port Jianyu ADC 
		o_adc_rst	  	: out std_logic;
		ov_data_q       : out std_logic_vector(C_CIC_output_bitwidth - 1 downto 0);
		ov_data_i       : out std_logic_vector(C_CIC_output_bitwidth - 1 downto 0);
		i_d_q_p         : in  std_logic;
		i_d_q_n         : in  std_logic;
		i_d_i_p         : in  std_logic;
		i_d_i_n         : in  std_logic;
		o_data_i_debug	: out std_logic;
		o_data_q_debug  : out std_logic;
		i_ufl_n			: in  std_logic;
		i_ufl_p 		: in  std_logic;		
		-- NMR Chip config freddy
		o_mosi 				: out std_logic;
		o_sclk 				: out std_logic;
		o_cs_NMR   			: out std_logic;
		o_cs_ADC   			: out std_logic;
		
		S_AXI_ACLK			: in std_logic;
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
	end component fpga_aisc_config_v2_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
fpga_aisc_config_v2_0_S00_AXI_inst : fpga_aisc_config_v2_0_S00_AXI
	generic map (
		C_CLK_FREQENCY 	   		=> C_CLK_FREQENCY,		-- the frequency of main clock 
		C_SCLK_FREQUENCY   		=> C_SCLK_FREQUENCY,		-- the frequency of spi clock
		C_NUMBER_SCLK      		=> C_NUMBER_SCLK,		-- the total number of spi clock in need to config the chip
		C_CIC_output_bitwidth 	=> C_CIC_output_bitwidth,
		C_CIC_buffer_depth  	=> C_CIC_buffer_depth,
		C_CIC_voltage_level 	=> C_CIC_voltage_level,
		C_S_AXI_DATA_WIDTH		=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH		=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		o_adc_rst	  	=> o_adc_rst,
		ov_data_q       => ov_data_q,
		ov_data_i       => ov_data_i,
		i_d_q_p         => i_d_q_p,
		i_d_q_n         => i_d_q_n,
		i_d_i_p         => i_d_i_p,
		i_d_i_n         => i_d_i_n,
		o_data_i_debug	=> o_data_i_debug,
		o_data_q_debug  => o_data_q_debug,
		i_ufl_n			=> i_ufl_n,
		i_ufl_p			=> i_ufl_p,		
		-- NMR Chip config freddy
		o_mosi 			=> o_mosi,
		o_sclk 			=> o_sclk,
		o_cs_NMR   		=> o_cs_NMR,
		o_cs_ADC   		=> o_cs_ADC,
		
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
		S_AXI_RRESP		 => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
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
			I                    => s00_axi_aclk
		  );
	-- User logic ends

end arch_imp;
