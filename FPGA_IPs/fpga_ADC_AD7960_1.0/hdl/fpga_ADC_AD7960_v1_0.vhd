library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fpga_ADC_AD7960_v1_0 is
	generic (
		-- Users to add parameters here
		CLK_FREQ 				: integer   := 200;
		C_ADC_DATA_WIDTH 		: integer	:= 18;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
		i_ADC_data_pos	: in std_logic;
		i_ADC_data_neg	: in std_logic;
		o_adc_en_0  	: out std_logic;
		o_adc_en_1  	: out std_logic;
		o_adc_en_2		: out std_logic;
		o_adc_en_3  	: out std_logic;
		i_ADC_dco_pos 	: in std_logic;
		i_ADC_dco_neg 	: in std_logic;
		o_ADC_cnv_pos 	: out std_logic;
		o_ADC_cnv_neg 	: out std_logic;
		o_ADC_clk_pos 	: out std_logic;
		o_ADC_clk_neg 	: out std_logic;
		ov_data			  : out std_logic_vector(C_ADC_DATA_WIDTH - 1 downto 0);	
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
end fpga_ADC_AD7960_v1_0;

architecture arch_imp of fpga_ADC_AD7960_v1_0 is

	-- component declaration
	component fpga_ADC_AD7960_v1_0_S00_AXI is
		generic (
		CLK_FREQ 			: integer	:= 200;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		d_pos_i			: in std_logic;
		d_neg_i 		: in std_logic;
		dco_pos_i 		: in std_logic;
		dco_neg_i 		: in std_logic;
		en_o 			: out std_logic_vector(3 downto 0);
		cnv_pos_o 		: out std_logic;
		cnv_neg_o 		: out std_logic;
		clk_pos_o 		: out std_logic;
		clk_neg_o 		: out std_logic;
		data_o 			: out std_logic_vector(17 downto 0);		
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component fpga_ADC_AD7960_v1_0_S00_AXI;
	
	signal
	en
	: std_logic_vector(3 downto 0) := (others => '0');
	signal
	data_top
	: std_logic_vector(17 downto 0) := (others => '0');	
begin

-- Instantiation of Axi Bus Interface S00_AXI
fpga_ADC_AD7960_v1_0_S00_AXI_inst : fpga_ADC_AD7960_v1_0_S00_AXI
	generic map (
		CLK_FREQ			=> CLK_FREQ,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		d_pos_i 	=> i_ADC_data_pos,
		d_neg_i	 	=> i_ADC_data_neg,
		dco_pos_i 	=> i_ADC_dco_pos,
		dco_neg_i 	=> i_ADC_dco_neg,
		en_o 		=> en,
		cnv_pos_o 	=> o_ADC_cnv_pos,
		cnv_neg_o 	=> o_ADC_cnv_neg,
		clk_pos_o 	=> o_ADC_clk_pos,
		clk_neg_o 	=> o_ADC_clk_neg,
		data_o 		=> data_top,	
		S_AXI_ACLK		=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);


	
	-- Add user logic here
	o_adc_en_0 <= en(0);
	o_adc_en_1 <= en(1);
	o_adc_en_2 <= en(2);
	o_adc_en_3 <= en(3);	
	ov_data <= std_logic_vector(resize(signed(data_top),ov_data'length));
	-- User logic ends

end arch_imp;
