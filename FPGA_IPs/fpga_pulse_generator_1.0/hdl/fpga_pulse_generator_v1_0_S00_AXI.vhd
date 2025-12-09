----------------------------------------------------------------------------------
-- Company: University of Stuttgart (IIS)
-- Engineer: Zhibin Zhao
--  
-- Create Date: 2022/06/17
-- Design Name: 
-- Module Name: fpga_NMR_sequence_generator_v1_0 - Behavioral
-- Project Name: NMR EPR pulse generator 
-- Target Devices: ZCU104
-- Tool Versions: 2019.1 vivado
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

USE work.fpga_pulse_gen_pkg.ALL;

entity fpga_pulse_generator_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here
		C_S_NR_SECTIONS		: integer 	:= 3 ;
		C_GRADIENT_DAC_WIDTH	: integer 	:= 14;		
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 10
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
		ov_gradient_x							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_y							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_z							: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_x_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_y_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		ov_gradient_z_ref						: OUT std_logic_vector(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0 );
		o_gradient_tvalid						: OUT std_logic;		
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end fpga_pulse_generator_v1_0_S00_AXI;

architecture arch_imp of fpga_pulse_generator_v1_0_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 7;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 256
	signal slv_reg0_sequence_generator_en :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1_set_nr_sections	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2_write_sel_section	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3_set_section_type	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg4_set_delay	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg5_set_mux	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg6_set_start_repeat_pointer	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg7_set_end_repeat_pointer	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg8_set_cycle_repetition_number	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg9_set_experiment_repetition_number	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg10_set_phase_ch0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg11_set_frequency_ch0	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg12_set_phase_ch1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg13_set_frequency_ch1	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg14_set_resetn_dds	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg15_busy	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg16_data_ready	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg17_nr_dds_ch	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg18_mem_depth	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg19_nr_activity	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg20_led	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	--Version 2.0 add gradient control
	signal slv_reg21_gradient_x	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg22_gradient_y	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg23_gradient_z	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg24_gradient_x_ref	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg25_gradient_y_ref	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg26_gradient_z_ref	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg27_gradient_sweep	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg28_gradient_x_sweep_step	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg29_gradient_y_sweep_step	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg30_gradient_z_sweep_step	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg31_gradient_x_sweep_offset	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg32_gradient_y_sweep_offset	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg33_gradient_z_sweep_offset	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg34	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg35	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg36	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg37	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg38	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg39	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg40	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg41	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg42	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg43	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg44	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg45	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg46	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg47	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg48	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg49	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg50	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg51	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg52	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg53	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg54	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg55	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg56	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg57	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg58	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg59	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg60	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg61	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg62	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg63	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg64	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg65	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg66	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg67	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg68	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg69	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg70	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg71	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg72	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg73	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg74	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg75	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg76	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg77	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg78	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg79	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg80	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg81	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg82	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg83	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg84	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg85	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg86	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg87	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg88	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg89	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg90	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg91	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg92	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg93	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg94	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg95	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg96	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg97	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg98	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg99	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg100	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg101	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg102	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg103	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg104	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg105	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg106	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg107	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg108	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg109	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg110	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg111	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg112	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg113	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg114	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg115	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg116	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg117	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg118	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg119	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg120	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg121	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg122	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg123	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg124	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg125	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg126	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg127	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg128	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg129	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg130	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg131	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg132	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg133	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg134	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg135	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg136	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg137	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg138	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg139	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg140	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg141	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg142	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg143	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg144	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg145	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg146	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg147	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg148	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg149	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg150	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg151	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg152	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg153	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg154	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg155	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg156	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg157	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg158	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg159	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg160	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg161	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg162	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg163	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg164	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg165	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg166	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg167	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg168	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg169	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg170	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg171	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg172	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg173	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg174	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg175	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg176	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg177	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg178	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg179	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg180	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg181	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg182	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg183	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg184	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg185	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg186	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg187	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg188	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg189	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg190	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg191	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg192	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg193	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg194	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg195	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg196	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg197	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg198	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg199	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg200	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg201	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg202	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg203	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg204	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg205	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg206	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg207	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg208	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg209	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg210	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg211	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg212	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg213	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg214	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg215	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg216	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg217	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg218	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg219	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg220	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg221	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg222	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg223	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg224	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg225	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg226	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg227	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg228	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg229	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg230	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg231	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg232	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg233	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg234	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg235	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg236	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg237	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg238	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg239	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg240	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg241	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg242	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg243	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg244	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg245	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg246	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg247	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg248	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg249	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg250	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg251	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg252	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg253	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg254	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	-- signal slv_reg255	:std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden	: std_logic;
	signal slv_reg_wren	: std_logic;
	signal reg_data_out	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	: integer;
	signal aw_en	: std_logic;
	signal 	gradient_x,
			gradient_y,
			gradient_z,
			gradient_x_ref,
			gradient_y_ref,
			gradient_z_ref : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0):= (others => '0');

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP		<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA		<= axi_rdata;
	S_AXI_RRESP		<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0_sequence_generator_en <= (others => '0');
	      slv_reg1_set_nr_sections <= (others => '0');
	      slv_reg2_write_sel_section <= (others => '0');
	      slv_reg3_set_section_type <= (others => '0');
	      slv_reg4_set_delay <= (others => '0');
	      slv_reg5_set_mux <= (others => '0');
	      slv_reg6_set_start_repeat_pointer <= (others => '0');
	      slv_reg7_set_end_repeat_pointer <= (others => '0');
	      slv_reg8_set_cycle_repetition_number <= (others => '0');
	      slv_reg9_set_experiment_repetition_number <= (others => '0');
	      slv_reg10_set_phase_ch0 <= (others => '0');
	      slv_reg11_set_frequency_ch0 <= (others => '0');
	      slv_reg12_set_phase_ch1 <= (others => '0');
	      slv_reg13_set_frequency_ch1 <= (others => '0');
	      slv_reg14_set_resetn_dds <= (others => '0');
--	      slv_reg15_busy(0) <= (others => '0');
--	      slv_reg16_data_ready(0) <= (others => '0');
--	      slv_reg17_nr_dds_ch <= (others => '0');
--	      slv_reg18_mem_depth <= (others => '0');
--	      slv_reg19_nr_activity <= (others => '0');
	      slv_reg20_led <= (others => '0');
	      slv_reg21_gradient_x <= (others => '0');
	      slv_reg22_gradient_y <= (others => '0');
	      slv_reg23_gradient_z <= (others => '0');
	      slv_reg24_gradient_x_ref <= (others => '0');
	      slv_reg25_gradient_y_ref <= (others => '0');
	      slv_reg26_gradient_z_ref <= (others => '0');
	      slv_reg27_gradient_sweep <= (others => '0');
	      slv_reg28_gradient_x_sweep_step <= (others => '0');
	      slv_reg29_gradient_y_sweep_step <= (others => '0');
	      slv_reg30_gradient_z_sweep_step <= (others => '0');
	      slv_reg31_gradient_x_sweep_offset <= (others => '0');
	      slv_reg32_gradient_y_sweep_offset <= (others => '0');
	      slv_reg33_gradient_z_sweep_offset <= (others => '0');
	      -- slv_reg34 <= (others => '0');
	      -- slv_reg35 <= (others => '0');
	      -- slv_reg36 <= (others => '0');
	      -- slv_reg37 <= (others => '0');
	      -- slv_reg38 <= (others => '0');
	      -- slv_reg39 <= (others => '0');
	      -- slv_reg40 <= (others => '0');
	      -- slv_reg41 <= (others => '0');
	      -- slv_reg42 <= (others => '0');
	      -- slv_reg43 <= (others => '0');
	      -- slv_reg44 <= (others => '0');
	      -- slv_reg45 <= (others => '0');
	      -- slv_reg46 <= (others => '0');
	      -- slv_reg47 <= (others => '0');
	      -- slv_reg48 <= (others => '0');
	      -- slv_reg49 <= (others => '0');
	      -- slv_reg50 <= (others => '0');
	      -- slv_reg51 <= (others => '0');
	      -- slv_reg52 <= (others => '0');
	      -- slv_reg53 <= (others => '0');
	      -- slv_reg54 <= (others => '0');
	      -- slv_reg55 <= (others => '0');
	      -- slv_reg56 <= (others => '0');
	      -- slv_reg57 <= (others => '0');
	      -- slv_reg58 <= (others => '0');
	      -- slv_reg59 <= (others => '0');
	      -- slv_reg60 <= (others => '0');
	      -- slv_reg61 <= (others => '0');
	      -- slv_reg62 <= (others => '0');
	      -- slv_reg63 <= (others => '0');
	      -- slv_reg64 <= (others => '0');
	      -- slv_reg65 <= (others => '0');
	      -- slv_reg66 <= (others => '0');
	      -- slv_reg67 <= (others => '0');
	      -- slv_reg68 <= (others => '0');
	      -- slv_reg69 <= (others => '0');
	      -- slv_reg70 <= (others => '0');
	      -- slv_reg71 <= (others => '0');
	      -- slv_reg72 <= (others => '0');
	      -- slv_reg73 <= (others => '0');
	      -- slv_reg74 <= (others => '0');
	      -- slv_reg75 <= (others => '0');
	      -- slv_reg76 <= (others => '0');
	      -- slv_reg77 <= (others => '0');
	      -- slv_reg78 <= (others => '0');
	      -- slv_reg79 <= (others => '0');
	      -- slv_reg80 <= (others => '0');
	      -- slv_reg81 <= (others => '0');
	      -- slv_reg82 <= (others => '0');
	      -- slv_reg83 <= (others => '0');
	      -- slv_reg84 <= (others => '0');
	      -- slv_reg85 <= (others => '0');
	      -- slv_reg86 <= (others => '0');
	      -- slv_reg87 <= (others => '0');
	      -- slv_reg88 <= (others => '0');
	      -- slv_reg89 <= (others => '0');
	      -- slv_reg90 <= (others => '0');
	      -- slv_reg91 <= (others => '0');
	      -- slv_reg92 <= (others => '0');
	      -- slv_reg93 <= (others => '0');
	      -- slv_reg94 <= (others => '0');
	      -- slv_reg95 <= (others => '0');
	      -- slv_reg96 <= (others => '0');
	      -- slv_reg97 <= (others => '0');
	      -- slv_reg98 <= (others => '0');
	      -- slv_reg99 <= (others => '0');
	      -- slv_reg100 <= (others => '0');
	      -- slv_reg101 <= (others => '0');
	      -- slv_reg102 <= (others => '0');
	      -- slv_reg103 <= (others => '0');
	      -- slv_reg104 <= (others => '0');
	      -- slv_reg105 <= (others => '0');
	      -- slv_reg106 <= (others => '0');
	      -- slv_reg107 <= (others => '0');
	      -- slv_reg108 <= (others => '0');
	      -- slv_reg109 <= (others => '0');
	      -- slv_reg110 <= (others => '0');
	      -- slv_reg111 <= (others => '0');
	      -- slv_reg112 <= (others => '0');
	      -- slv_reg113 <= (others => '0');
	      -- slv_reg114 <= (others => '0');
	      -- slv_reg115 <= (others => '0');
	      -- slv_reg116 <= (others => '0');
	      -- slv_reg117 <= (others => '0');
	      -- slv_reg118 <= (others => '0');
	      -- slv_reg119 <= (others => '0');
	      -- slv_reg120 <= (others => '0');
	      -- slv_reg121 <= (others => '0');
	      -- slv_reg122 <= (others => '0');
	      -- slv_reg123 <= (others => '0');
	      -- slv_reg124 <= (others => '0');
	      -- slv_reg125 <= (others => '0');
	      -- slv_reg126 <= (others => '0');
	      -- slv_reg127 <= (others => '0');
	      -- slv_reg128 <= (others => '0');
	      -- slv_reg129 <= (others => '0');
	      -- slv_reg130 <= (others => '0');
	      -- slv_reg131 <= (others => '0');
	      -- slv_reg132 <= (others => '0');
	      -- slv_reg133 <= (others => '0');
	      -- slv_reg134 <= (others => '0');
	      -- slv_reg135 <= (others => '0');
	      -- slv_reg136 <= (others => '0');
	      -- slv_reg137 <= (others => '0');
	      -- slv_reg138 <= (others => '0');
	      -- slv_reg139 <= (others => '0');
	      -- slv_reg140 <= (others => '0');
	      -- slv_reg141 <= (others => '0');
	      -- slv_reg142 <= (others => '0');
	      -- slv_reg143 <= (others => '0');
	      -- slv_reg144 <= (others => '0');
	      -- slv_reg145 <= (others => '0');
	      -- slv_reg146 <= (others => '0');
	      -- slv_reg147 <= (others => '0');
	      -- slv_reg148 <= (others => '0');
	      -- slv_reg149 <= (others => '0');
	      -- slv_reg150 <= (others => '0');
	      -- slv_reg151 <= (others => '0');
	      -- slv_reg152 <= (others => '0');
	      -- slv_reg153 <= (others => '0');
	      -- slv_reg154 <= (others => '0');
	      -- slv_reg155 <= (others => '0');
	      -- slv_reg156 <= (others => '0');
	      -- slv_reg157 <= (others => '0');
	      -- slv_reg158 <= (others => '0');
	      -- slv_reg159 <= (others => '0');
	      -- slv_reg160 <= (others => '0');
	      -- slv_reg161 <= (others => '0');
	      -- slv_reg162 <= (others => '0');
	      -- slv_reg163 <= (others => '0');
	      -- slv_reg164 <= (others => '0');
	      -- slv_reg165 <= (others => '0');
	      -- slv_reg166 <= (others => '0');
	      -- slv_reg167 <= (others => '0');
	      -- slv_reg168 <= (others => '0');
	      -- slv_reg169 <= (others => '0');
	      -- slv_reg170 <= (others => '0');
	      -- slv_reg171 <= (others => '0');
	      -- slv_reg172 <= (others => '0');
	      -- slv_reg173 <= (others => '0');
	      -- slv_reg174 <= (others => '0');
	      -- slv_reg175 <= (others => '0');
	      -- slv_reg176 <= (others => '0');
	      -- slv_reg177 <= (others => '0');
	      -- slv_reg178 <= (others => '0');
	      -- slv_reg179 <= (others => '0');
	      -- slv_reg180 <= (others => '0');
	      -- slv_reg181 <= (others => '0');
	      -- slv_reg182 <= (others => '0');
	      -- slv_reg183 <= (others => '0');
	      -- slv_reg184 <= (others => '0');
	      -- slv_reg185 <= (others => '0');
	      -- slv_reg186 <= (others => '0');
	      -- slv_reg187 <= (others => '0');
	      -- slv_reg188 <= (others => '0');
	      -- slv_reg189 <= (others => '0');
	      -- slv_reg190 <= (others => '0');
	      -- slv_reg191 <= (others => '0');
	      -- slv_reg192 <= (others => '0');
	      -- slv_reg193 <= (others => '0');
	      -- slv_reg194 <= (others => '0');
	      -- slv_reg195 <= (others => '0');
	      -- slv_reg196 <= (others => '0');
	      -- slv_reg197 <= (others => '0');
	      -- slv_reg198 <= (others => '0');
	      -- slv_reg199 <= (others => '0');
	      -- slv_reg200 <= (others => '0');
	      -- slv_reg201 <= (others => '0');
	      -- slv_reg202 <= (others => '0');
	      -- slv_reg203 <= (others => '0');
	      -- slv_reg204 <= (others => '0');
	      -- slv_reg205 <= (others => '0');
	      -- slv_reg206 <= (others => '0');
	      -- slv_reg207 <= (others => '0');
	      -- slv_reg208 <= (others => '0');
	      -- slv_reg209 <= (others => '0');
	      -- slv_reg210 <= (others => '0');
	      -- slv_reg211 <= (others => '0');
	      -- slv_reg212 <= (others => '0');
	      -- slv_reg213 <= (others => '0');
	      -- slv_reg214 <= (others => '0');
	      -- slv_reg215 <= (others => '0');
	      -- slv_reg216 <= (others => '0');
	      -- slv_reg217 <= (others => '0');
	      -- slv_reg218 <= (others => '0');
	      -- slv_reg219 <= (others => '0');
	      -- slv_reg220 <= (others => '0');
	      -- slv_reg221 <= (others => '0');
	      -- slv_reg222 <= (others => '0');
	      -- slv_reg223 <= (others => '0');
	      -- slv_reg224 <= (others => '0');
	      -- slv_reg225 <= (others => '0');
	      -- slv_reg226 <= (others => '0');
	      -- slv_reg227 <= (others => '0');
	      -- slv_reg228 <= (others => '0');
	      -- slv_reg229 <= (others => '0');
	      -- slv_reg230 <= (others => '0');
	      -- slv_reg231 <= (others => '0');
	      -- slv_reg232 <= (others => '0');
	      -- slv_reg233 <= (others => '0');
	      -- slv_reg234 <= (others => '0');
	      -- slv_reg235 <= (others => '0');
	      -- slv_reg236 <= (others => '0');
	      -- slv_reg237 <= (others => '0');
	      -- slv_reg238 <= (others => '0');
	      -- slv_reg239 <= (others => '0');
	      -- slv_reg240 <= (others => '0');
	      -- slv_reg241 <= (others => '0');
	      -- slv_reg242 <= (others => '0');
	      -- slv_reg243 <= (others => '0');
	      -- slv_reg244 <= (others => '0');
	      -- slv_reg245 <= (others => '0');
	      -- slv_reg246 <= (others => '0');
	      -- slv_reg247 <= (others => '0');
	      -- slv_reg248 <= (others => '0');
	      -- slv_reg249 <= (others => '0');
	      -- slv_reg250 <= (others => '0');
	      -- slv_reg251 <= (others => '0');
	      -- slv_reg252 <= (others => '0');
	      -- slv_reg253 <= (others => '0');
	      -- slv_reg254 <= (others => '0');
	      -- slv_reg255 <= (others => '0');
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"00000000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                slv_reg0_sequence_generator_en(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                slv_reg1_set_nr_sections(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2_write_sel_section(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3_set_section_type(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 4
	                slv_reg4_set_delay(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 5
	                slv_reg5_set_mux(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 6
	                slv_reg6_set_start_repeat_pointer(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00000111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 7
	                slv_reg7_set_end_repeat_pointer(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 8
	                slv_reg8_set_cycle_repetition_number(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 9
	                slv_reg9_set_experiment_repetition_number(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 10
	                slv_reg10_set_phase_ch0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 11
	                slv_reg11_set_frequency_ch0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 12
	                slv_reg12_set_phase_ch1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 13
	                slv_reg13_set_frequency_ch1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00001110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 14
	                slv_reg14_set_resetn_dds(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          -- when b"00001111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 15
	                -- slv_reg15_busy(0)(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00010000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 16
	                -- slv_reg16_data_ready(0)(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00010001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 17
	                -- slv_reg17_nr_dds_ch(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00010010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 18
	                -- slv_reg18_mem_depth(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00010011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 19
	                -- slv_reg19_nr_activity(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          when b"00010100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 20
	                slv_reg20_led(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00010101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 21
	                slv_reg21_gradient_x(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00010110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 22
	                slv_reg22_gradient_y(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00010111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 23
	                slv_reg23_gradient_z(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 24
	                slv_reg24_gradient_x_ref(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 25
	                slv_reg25_gradient_y_ref(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011010" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 26
	                slv_reg26_gradient_z_ref(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011011" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 27
	                slv_reg27_gradient_sweep(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011100" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 28
	                slv_reg28_gradient_x_sweep_step(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011101" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 29
	                slv_reg29_gradient_y_sweep_step(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011110" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 30
	                slv_reg30_gradient_z_sweep_step(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00011111" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 31
	                slv_reg31_gradient_x_sweep_offset(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00100000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 32
	                slv_reg32_gradient_y_sweep_offset(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"00100001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 33
	                slv_reg33_gradient_z_sweep_offset(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          -- when b"00100010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 34
	                -- slv_reg34(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00100011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 35
	                -- slv_reg35(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00100100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 36
	                -- slv_reg36(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00100101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 37
	                -- slv_reg37(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00100110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 38
	                -- slv_reg38(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00100111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 39
	                -- slv_reg39(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 40
	                -- slv_reg40(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 41
	                -- slv_reg41(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 42
	                -- slv_reg42(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 43
	                -- slv_reg43(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 44
	                -- slv_reg44(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 45
	                -- slv_reg45(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 46
	                -- slv_reg46(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00101111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 47
	                -- slv_reg47(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 48
	                -- slv_reg48(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 49
	                -- slv_reg49(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 50
	                -- slv_reg50(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 51
	                -- slv_reg51(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 52
	                -- slv_reg52(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 53
	                -- slv_reg53(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 54
	                -- slv_reg54(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00110111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 55
	                -- slv_reg55(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 56
	                -- slv_reg56(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 57
	                -- slv_reg57(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 58
	                -- slv_reg58(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 59
	                -- slv_reg59(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 60
	                -- slv_reg60(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 61
	                -- slv_reg61(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 62
	                -- slv_reg62(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"00111111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 63
	                -- slv_reg63(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 64
	                -- slv_reg64(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 65
	                -- slv_reg65(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 66
	                -- slv_reg66(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 67
	                -- slv_reg67(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 68
	                -- slv_reg68(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 69
	                -- slv_reg69(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 70
	                -- slv_reg70(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01000111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 71
	                -- slv_reg71(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 72
	                -- slv_reg72(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 73
	                -- slv_reg73(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 74
	                -- slv_reg74(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 75
	                -- slv_reg75(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 76
	                -- slv_reg76(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 77
	                -- slv_reg77(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 78
	                -- slv_reg78(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01001111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 79
	                -- slv_reg79(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 80
	                -- slv_reg80(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 81
	                -- slv_reg81(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 82
	                -- slv_reg82(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 83
	                -- slv_reg83(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 84
	                -- slv_reg84(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 85
	                -- slv_reg85(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 86
	                -- slv_reg86(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01010111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 87
	                -- slv_reg87(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 88
	                -- slv_reg88(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 89
	                -- slv_reg89(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 90
	                -- slv_reg90(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 91
	                -- slv_reg91(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 92
	                -- slv_reg92(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 93
	                -- slv_reg93(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 94
	                -- slv_reg94(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01011111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 95
	                -- slv_reg95(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 96
	                -- slv_reg96(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 97
	                -- slv_reg97(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 98
	                -- slv_reg98(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 99
	                -- slv_reg99(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 100
	                -- slv_reg100(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 101
	                -- slv_reg101(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 102
	                -- slv_reg102(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01100111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 103
	                -- slv_reg103(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 104
	                -- slv_reg104(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 105
	                -- slv_reg105(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 106
	                -- slv_reg106(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 107
	                -- slv_reg107(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 108
	                -- slv_reg108(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 109
	                -- slv_reg109(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 110
	                -- slv_reg110(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01101111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 111
	                -- slv_reg111(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 112
	                -- slv_reg112(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 113
	                -- slv_reg113(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 114
	                -- slv_reg114(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 115
	                -- slv_reg115(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 116
	                -- slv_reg116(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 117
	                -- slv_reg117(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 118
	                -- slv_reg118(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01110111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 119
	                -- slv_reg119(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 120
	                -- slv_reg120(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 121
	                -- slv_reg121(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 122
	                -- slv_reg122(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 123
	                -- slv_reg123(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 124
	                -- slv_reg124(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 125
	                -- slv_reg125(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 126
	                -- slv_reg126(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"01111111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 127
	                -- slv_reg127(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 128
	                -- slv_reg128(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 129
	                -- slv_reg129(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 130
	                -- slv_reg130(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 131
	                -- slv_reg131(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 132
	                -- slv_reg132(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 133
	                -- slv_reg133(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 134
	                -- slv_reg134(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10000111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 135
	                -- slv_reg135(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 136
	                -- slv_reg136(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 137
	                -- slv_reg137(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 138
	                -- slv_reg138(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 139
	                -- slv_reg139(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 140
	                -- slv_reg140(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 141
	                -- slv_reg141(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 142
	                -- slv_reg142(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10001111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 143
	                -- slv_reg143(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 144
	                -- slv_reg144(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 145
	                -- slv_reg145(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 146
	                -- slv_reg146(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 147
	                -- slv_reg147(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 148
	                -- slv_reg148(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 149
	                -- slv_reg149(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 150
	                -- slv_reg150(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10010111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 151
	                -- slv_reg151(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 152
	                -- slv_reg152(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 153
	                -- slv_reg153(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 154
	                -- slv_reg154(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 155
	                -- slv_reg155(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 156
	                -- slv_reg156(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 157
	                -- slv_reg157(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 158
	                -- slv_reg158(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10011111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 159
	                -- slv_reg159(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 160
	                -- slv_reg160(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 161
	                -- slv_reg161(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 162
	                -- slv_reg162(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 163
	                -- slv_reg163(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 164
	                -- slv_reg164(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 165
	                -- slv_reg165(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 166
	                -- slv_reg166(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10100111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 167
	                -- slv_reg167(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 168
	                -- slv_reg168(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 169
	                -- slv_reg169(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 170
	                -- slv_reg170(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 171
	                -- slv_reg171(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 172
	                -- slv_reg172(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 173
	                -- slv_reg173(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 174
	                -- slv_reg174(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10101111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 175
	                -- slv_reg175(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 176
	                -- slv_reg176(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 177
	                -- slv_reg177(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 178
	                -- slv_reg178(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 179
	                -- slv_reg179(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 180
	                -- slv_reg180(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 181
	                -- slv_reg181(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 182
	                -- slv_reg182(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10110111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 183
	                -- slv_reg183(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 184
	                -- slv_reg184(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 185
	                -- slv_reg185(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 186
	                -- slv_reg186(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 187
	                -- slv_reg187(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 188
	                -- slv_reg188(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 189
	                -- slv_reg189(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 190
	                -- slv_reg190(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"10111111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 191
	                -- slv_reg191(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 192
	                -- slv_reg192(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 193
	                -- slv_reg193(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 194
	                -- slv_reg194(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 195
	                -- slv_reg195(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 196
	                -- slv_reg196(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 197
	                -- slv_reg197(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 198
	                -- slv_reg198(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11000111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 199
	                -- slv_reg199(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 200
	                -- slv_reg200(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 201
	                -- slv_reg201(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 202
	                -- slv_reg202(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 203
	                -- slv_reg203(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 204
	                -- slv_reg204(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 205
	                -- slv_reg205(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 206
	                -- slv_reg206(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11001111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 207
	                -- slv_reg207(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 208
	                -- slv_reg208(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 209
	                -- slv_reg209(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 210
	                -- slv_reg210(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 211
	                -- slv_reg211(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 212
	                -- slv_reg212(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 213
	                -- slv_reg213(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 214
	                -- slv_reg214(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11010111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 215
	                -- slv_reg215(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 216
	                -- slv_reg216(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 217
	                -- slv_reg217(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 218
	                -- slv_reg218(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 219
	                -- slv_reg219(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 220
	                -- slv_reg220(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 221
	                -- slv_reg221(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 222
	                -- slv_reg222(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11011111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 223
	                -- slv_reg223(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 224
	                -- slv_reg224(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 225
	                -- slv_reg225(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 226
	                -- slv_reg226(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 227
	                -- slv_reg227(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 228
	                -- slv_reg228(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 229
	                -- slv_reg229(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 230
	                -- slv_reg230(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11100111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 231
	                -- slv_reg231(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 232
	                -- slv_reg232(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 233
	                -- slv_reg233(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 234
	                -- slv_reg234(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 235
	                -- slv_reg235(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 236
	                -- slv_reg236(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 237
	                -- slv_reg237(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 238
	                -- slv_reg238(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11101111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 239
	                -- slv_reg239(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 240
	                -- slv_reg240(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 241
	                -- slv_reg241(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 242
	                -- slv_reg242(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 243
	                -- slv_reg243(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 244
	                -- slv_reg244(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 245
	                -- slv_reg245(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 246
	                -- slv_reg246(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11110111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 247
	                -- slv_reg247(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111000" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 248
	                -- slv_reg248(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111001" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 249
	                -- slv_reg249(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111010" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 250
	                -- slv_reg250(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111011" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 251
	                -- slv_reg251(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111100" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 252
	                -- slv_reg252(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111101" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 253
	                -- slv_reg253(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111110" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 254
	                -- slv_reg254(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          -- when b"11111111" =>
	            -- for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              -- if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- -- Respective byte enables are asserted as per write strobes                   
	                -- -- slave registor 255
	                -- slv_reg255(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              -- end if;
	            -- end loop;
	          when others =>
	            slv_reg0_sequence_generator_en 	  			<= slv_reg0_sequence_generator_en;
	            slv_reg1_set_nr_sections 			<= slv_reg1_set_nr_sections;
	            slv_reg2_write_sel_section   			  			<= slv_reg2_write_sel_section;
	            slv_reg3_set_section_type    			<= slv_reg3_set_section_type;
	            slv_reg4_set_delay      		<= slv_reg4_set_delay;
	            slv_reg5_set_mux 					<= slv_reg5_set_mux;
	            slv_reg6_set_start_repeat_pointer 			<= slv_reg6_set_start_repeat_pointer;
	            slv_reg7_set_end_repeat_pointer 		<= slv_reg7_set_end_repeat_pointer;
	            slv_reg8_set_cycle_repetition_number 			<= slv_reg8_set_cycle_repetition_number;
	            slv_reg9_set_experiment_repetition_number 		<= slv_reg9_set_experiment_repetition_number;
	            slv_reg10_set_phase_ch0 			<= slv_reg10_set_phase_ch0;
	            slv_reg11_set_frequency_ch0 			<= slv_reg11_set_frequency_ch0;
	            slv_reg12_set_phase_ch1 		<= slv_reg12_set_phase_ch1;
	            slv_reg13_set_frequency_ch1 	<= slv_reg13_set_frequency_ch1;
	            slv_reg14_set_resetn_dds 				<= slv_reg14_set_resetn_dds;
				-- slv_reg15_busy(0) 						<= slv_reg15_busy(0);
	            -- slv_reg16_data_ready(0) 					<= slv_reg16_data_ready(0);
	            -- slv_reg17_nr_dds_ch <= slv_reg17_nr_dds_ch;
	            -- slv_reg18_mem_depth <= slv_reg18_mem_depth;
	            -- slv_reg19_nr_activity <= slv_reg19_nr_activity;
	            slv_reg20_led <= slv_reg20_led;
	            slv_reg21_gradient_x <= slv_reg21_gradient_x;
	            slv_reg22_gradient_y <= slv_reg22_gradient_y;
	            slv_reg23_gradient_z <= slv_reg23_gradient_z;
	            slv_reg24_gradient_x_ref <= slv_reg24_gradient_x_ref;
	            slv_reg25_gradient_y_ref <= slv_reg25_gradient_y_ref;
	            slv_reg26_gradient_z_ref <= slv_reg26_gradient_z_ref;
	            slv_reg27_gradient_sweep <= slv_reg27_gradient_sweep;
	            slv_reg28_gradient_x_sweep_step <= slv_reg28_gradient_x_sweep_step;
	            slv_reg29_gradient_y_sweep_step <= slv_reg29_gradient_y_sweep_step;
	            slv_reg30_gradient_z_sweep_step <= slv_reg30_gradient_z_sweep_step;
	            slv_reg31_gradient_x_sweep_offset <= slv_reg31_gradient_x_sweep_offset;
	            slv_reg32_gradient_y_sweep_offset <= slv_reg32_gradient_y_sweep_offset;
	            slv_reg33_gradient_z_sweep_offset <= slv_reg33_gradient_z_sweep_offset;
	            -- slv_reg34 <= slv_reg34;
	            -- slv_reg35 <= slv_reg35;
	            -- slv_reg36 <= slv_reg36;
	            -- slv_reg37 <= slv_reg37;
	            -- slv_reg38 <= slv_reg38;
	            -- slv_reg39 <= slv_reg39;
	            -- slv_reg40 <= slv_reg40;
	            -- slv_reg41 <= slv_reg41;
	            -- slv_reg42 <= slv_reg42;
	            -- slv_reg43 <= slv_reg43;
	            -- slv_reg44 <= slv_reg44;
	            -- slv_reg45 <= slv_reg45;
	            -- slv_reg46 <= slv_reg46;
	            -- slv_reg47 <= slv_reg47;
	            -- slv_reg48 <= slv_reg48;
	            -- slv_reg49 <= slv_reg49;
	            -- slv_reg50 <= slv_reg50;
	            -- slv_reg51 <= slv_reg51;
	            -- slv_reg52 <= slv_reg52;
	            -- slv_reg53 <= slv_reg53;
	            -- slv_reg54 <= slv_reg54;
	            -- slv_reg55 <= slv_reg55;
	            -- slv_reg56 <= slv_reg56;
	            -- slv_reg57 <= slv_reg57;
	            -- slv_reg58 <= slv_reg58;
	            -- slv_reg59 <= slv_reg59;
	            -- slv_reg60 <= slv_reg60;
	            -- slv_reg61 <= slv_reg61;
	            -- slv_reg62 <= slv_reg62;
	            -- slv_reg63 <= slv_reg63;
	            -- slv_reg64 <= slv_reg64;
	            -- slv_reg65 <= slv_reg65;
	            -- slv_reg66 <= slv_reg66;
	            -- slv_reg67 <= slv_reg67;
	            -- slv_reg68 <= slv_reg68;
	            -- slv_reg69 <= slv_reg69;
	            -- slv_reg70 <= slv_reg70;
	            -- slv_reg71 <= slv_reg71;
	            -- slv_reg72 <= slv_reg72;
	            -- slv_reg73 <= slv_reg73;
	            -- slv_reg74 <= slv_reg74;
	            -- slv_reg75 <= slv_reg75;
	            -- slv_reg76 <= slv_reg76;
	            -- slv_reg77 <= slv_reg77;
	            -- slv_reg78 <= slv_reg78;
	            -- slv_reg79 <= slv_reg79;
	            -- slv_reg80 <= slv_reg80;
	            -- slv_reg81 <= slv_reg81;
	            -- slv_reg82 <= slv_reg82;
	            -- slv_reg83 <= slv_reg83;
	            -- slv_reg84 <= slv_reg84;
	            -- slv_reg85 <= slv_reg85;
	            -- slv_reg86 <= slv_reg86;
	            -- slv_reg87 <= slv_reg87;
	            -- slv_reg88 <= slv_reg88;
	            -- slv_reg89 <= slv_reg89;
	            -- slv_reg90 <= slv_reg90;
	            -- slv_reg91 <= slv_reg91;
	            -- slv_reg92 <= slv_reg92;
	            -- slv_reg93 <= slv_reg93;
	            -- slv_reg94 <= slv_reg94;
	            -- slv_reg95 <= slv_reg95;
	            -- slv_reg96 <= slv_reg96;
	            -- slv_reg97 <= slv_reg97;
	            -- slv_reg98 <= slv_reg98;
	            -- slv_reg99 <= slv_reg99;
	            -- slv_reg100 <= slv_reg100;
	            -- slv_reg101 <= slv_reg101;
	            -- slv_reg102 <= slv_reg102;
	            -- slv_reg103 <= slv_reg103;
	            -- slv_reg104 <= slv_reg104;
	            -- slv_reg105 <= slv_reg105;
	            -- slv_reg106 <= slv_reg106;
	            -- slv_reg107 <= slv_reg107;
	            -- slv_reg108 <= slv_reg108;
	            -- slv_reg109 <= slv_reg109;
	            -- slv_reg110 <= slv_reg110;
	            -- slv_reg111 <= slv_reg111;
	            -- slv_reg112 <= slv_reg112;
	            -- slv_reg113 <= slv_reg113;
	            -- slv_reg114 <= slv_reg114;
	            -- slv_reg115 <= slv_reg115;
	            -- slv_reg116 <= slv_reg116;
	            -- slv_reg117 <= slv_reg117;
	            -- slv_reg118 <= slv_reg118;
	            -- slv_reg119 <= slv_reg119;
	            -- slv_reg120 <= slv_reg120;
	            -- slv_reg121 <= slv_reg121;
	            -- slv_reg122 <= slv_reg122;
	            -- slv_reg123 <= slv_reg123;
	            -- slv_reg124 <= slv_reg124;
	            -- slv_reg125 <= slv_reg125;
	            -- slv_reg126 <= slv_reg126;
	            -- slv_reg127 <= slv_reg127;
	            -- slv_reg128 <= slv_reg128;
	            -- slv_reg129 <= slv_reg129;
	            -- slv_reg130 <= slv_reg130;
	            -- slv_reg131 <= slv_reg131;
	            -- slv_reg132 <= slv_reg132;
	            -- slv_reg133 <= slv_reg133;
	            -- slv_reg134 <= slv_reg134;
	            -- slv_reg135 <= slv_reg135;
	            -- slv_reg136 <= slv_reg136;
	            -- slv_reg137 <= slv_reg137;
	            -- slv_reg138 <= slv_reg138;
	            -- slv_reg139 <= slv_reg139;
	            -- slv_reg140 <= slv_reg140;
	            -- slv_reg141 <= slv_reg141;
	            -- slv_reg142 <= slv_reg142;
	            -- slv_reg143 <= slv_reg143;
	            -- slv_reg144 <= slv_reg144;
	            -- slv_reg145 <= slv_reg145;
	            -- slv_reg146 <= slv_reg146;
	            -- slv_reg147 <= slv_reg147;
	            -- slv_reg148 <= slv_reg148;
	            -- slv_reg149 <= slv_reg149;
	            -- slv_reg150 <= slv_reg150;
	            -- slv_reg151 <= slv_reg151;
	            -- slv_reg152 <= slv_reg152;
	            -- slv_reg153 <= slv_reg153;
	            -- slv_reg154 <= slv_reg154;
	            -- slv_reg155 <= slv_reg155;
	            -- slv_reg156 <= slv_reg156;
	            -- slv_reg157 <= slv_reg157;
	            -- slv_reg158 <= slv_reg158;
	            -- slv_reg159 <= slv_reg159;
	            -- slv_reg160 <= slv_reg160;
	            -- slv_reg161 <= slv_reg161;
	            -- slv_reg162 <= slv_reg162;
	            -- slv_reg163 <= slv_reg163;
	            -- slv_reg164 <= slv_reg164;
	            -- slv_reg165 <= slv_reg165;
	            -- slv_reg166 <= slv_reg166;
	            -- slv_reg167 <= slv_reg167;
	            -- slv_reg168 <= slv_reg168;
	            -- slv_reg169 <= slv_reg169;
	            -- slv_reg170 <= slv_reg170;
	            -- slv_reg171 <= slv_reg171;
	            -- slv_reg172 <= slv_reg172;
	            -- slv_reg173 <= slv_reg173;
	            -- slv_reg174 <= slv_reg174;
	            -- slv_reg175 <= slv_reg175;
	            -- slv_reg176 <= slv_reg176;
	            -- slv_reg177 <= slv_reg177;
	            -- slv_reg178 <= slv_reg178;
	            -- slv_reg179 <= slv_reg179;
	            -- slv_reg180 <= slv_reg180;
	            -- slv_reg181 <= slv_reg181;
	            -- slv_reg182 <= slv_reg182;
	            -- slv_reg183 <= slv_reg183;
	            -- slv_reg184 <= slv_reg184;
	            -- slv_reg185 <= slv_reg185;
	            -- slv_reg186 <= slv_reg186;
	            -- slv_reg187 <= slv_reg187;
	            -- slv_reg188 <= slv_reg188;
	            -- slv_reg189 <= slv_reg189;
	            -- slv_reg190 <= slv_reg190;
	            -- slv_reg191 <= slv_reg191;
	            -- slv_reg192 <= slv_reg192;
	            -- slv_reg193 <= slv_reg193;
	            -- slv_reg194 <= slv_reg194;
	            -- slv_reg195 <= slv_reg195;
	            -- slv_reg196 <= slv_reg196;
	            -- slv_reg197 <= slv_reg197;
	            -- slv_reg198 <= slv_reg198;
	            -- slv_reg199 <= slv_reg199;
	            -- slv_reg200 <= slv_reg200;
	            -- slv_reg201 <= slv_reg201;
	            -- slv_reg202 <= slv_reg202;
	            -- slv_reg203 <= slv_reg203;
	            -- slv_reg204 <= slv_reg204;
	            -- slv_reg205 <= slv_reg205;
	            -- slv_reg206 <= slv_reg206;
	            -- slv_reg207 <= slv_reg207;
	            -- slv_reg208 <= slv_reg208;
	            -- slv_reg209 <= slv_reg209;
	            -- slv_reg210 <= slv_reg210;
	            -- slv_reg211 <= slv_reg211;
	            -- slv_reg212 <= slv_reg212;
	            -- slv_reg213 <= slv_reg213;
	            -- slv_reg214 <= slv_reg214;
	            -- slv_reg215 <= slv_reg215;
	            -- slv_reg216 <= slv_reg216;
	            -- slv_reg217 <= slv_reg217;
	            -- slv_reg218 <= slv_reg218;
	            -- slv_reg219 <= slv_reg219;
	            -- slv_reg220 <= slv_reg220;
	            -- slv_reg221 <= slv_reg221;
	            -- slv_reg222 <= slv_reg222;
	            -- slv_reg223 <= slv_reg223;
	            -- slv_reg224 <= slv_reg224;
	            -- slv_reg225 <= slv_reg225;
	            -- slv_reg226 <= slv_reg226;
	            -- slv_reg227 <= slv_reg227;
	            -- slv_reg228 <= slv_reg228;
	            -- slv_reg229 <= slv_reg229;
	            -- slv_reg230 <= slv_reg230;
	            -- slv_reg231 <= slv_reg231;
	            -- slv_reg232 <= slv_reg232;
	            -- slv_reg233 <= slv_reg233;
	            -- slv_reg234 <= slv_reg234;
	            -- slv_reg235 <= slv_reg235;
	            -- slv_reg236 <= slv_reg236;
	            -- slv_reg237 <= slv_reg237;
	            -- slv_reg238 <= slv_reg238;
	            -- slv_reg239 <= slv_reg239;
	            -- slv_reg240 <= slv_reg240;
	            -- slv_reg241 <= slv_reg241;
	            -- slv_reg242 <= slv_reg242;
	            -- slv_reg243 <= slv_reg243;
	            -- slv_reg244 <= slv_reg244;
	            -- slv_reg245 <= slv_reg245;
	            -- slv_reg246 <= slv_reg246;
	            -- slv_reg247 <= slv_reg247;
	            -- slv_reg248 <= slv_reg248;
	            -- slv_reg249 <= slv_reg249;
	            -- slv_reg250 <= slv_reg250;
	            -- slv_reg251 <= slv_reg251;
	            -- slv_reg252 <= slv_reg252;
	            -- slv_reg253 <= slv_reg253;
	            -- slv_reg254 <= slv_reg254;
	            -- slv_reg255 <= slv_reg255;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (slv_reg0_sequence_generator_en, slv_reg1_set_nr_sections, slv_reg2_write_sel_section, slv_reg3_set_section_type, slv_reg4_set_delay, slv_reg5_set_mux, slv_reg6_set_start_repeat_pointer, slv_reg7_set_end_repeat_pointer, slv_reg8_set_cycle_repetition_number, slv_reg9_set_experiment_repetition_number, slv_reg10_set_phase_ch0, slv_reg11_set_frequency_ch0, slv_reg12_set_phase_ch1, slv_reg13_set_frequency_ch1, slv_reg14_set_resetn_dds, slv_reg15_busy(0), slv_reg16_data_ready(0), slv_reg17_nr_dds_ch, slv_reg18_mem_depth, slv_reg19_nr_activity, slv_reg20_led, axi_araddr, S_AXI_ARESETN, slv_reg_rden, slv_reg21_gradient_x, slv_reg22_gradient_y, slv_reg23_gradient_z, slv_reg24_gradient_x_ref, slv_reg25_gradient_y_ref, slv_reg26_gradient_z_ref, slv_reg27_gradient_sweep, slv_reg28_gradient_x_sweep_step, slv_reg29_gradient_y_sweep_step, slv_reg30_gradient_z_sweep_step, slv_reg31_gradient_x_sweep_offset, slv_reg32_gradient_y_sweep_offset, slv_reg33_gradient_z_sweep_offset)-- , slv_reg34, slv_reg35, slv_reg36, slv_reg37, slv_reg38, slv_reg39, slv_reg40, slv_reg41, slv_reg42, slv_reg43, slv_reg44, slv_reg45, slv_reg46, slv_reg47, slv_reg48, slv_reg49, slv_reg50, slv_reg51, slv_reg52, slv_reg53, slv_reg54, slv_reg55, slv_reg56, slv_reg57, slv_reg58, slv_reg59, slv_reg60, slv_reg61, slv_reg62, slv_reg63, slv_reg64, slv_reg65, slv_reg66, slv_reg67, slv_reg68, slv_reg69, slv_reg70, slv_reg71, slv_reg72, slv_reg73, slv_reg74, slv_reg75, slv_reg76, slv_reg77, slv_reg78, slv_reg79, slv_reg80, slv_reg81, slv_reg82, slv_reg83, slv_reg84, slv_reg85, slv_reg86, slv_reg87, slv_reg88, slv_reg89, slv_reg90, slv_reg91, slv_reg92, slv_reg93, slv_reg94, slv_reg95, slv_reg96, slv_reg97, slv_reg98, slv_reg99, slv_reg100, slv_reg101, slv_reg102, slv_reg103, slv_reg104, slv_reg105, slv_reg106, slv_reg107, slv_reg108, slv_reg109, slv_reg110, slv_reg111, slv_reg112, slv_reg113, slv_reg114, slv_reg115, slv_reg116, slv_reg117, slv_reg118, slv_reg119, slv_reg120, slv_reg121, slv_reg122, slv_reg123, slv_reg124, slv_reg125, slv_reg126, slv_reg127, slv_reg128, slv_reg129, slv_reg130, slv_reg131, slv_reg132, slv_reg133, slv_reg134, slv_reg135, slv_reg136, slv_reg137, slv_reg138, slv_reg139, slv_reg140, slv_reg141, slv_reg142, slv_reg143, slv_reg144, slv_reg145, slv_reg146, slv_reg147, slv_reg148, slv_reg149, slv_reg150, slv_reg151, slv_reg152, slv_reg153, slv_reg154, slv_reg155, slv_reg156, slv_reg157, slv_reg158, slv_reg159, slv_reg160, slv_reg161, slv_reg162, slv_reg163, slv_reg164, slv_reg165, slv_reg166, slv_reg167, slv_reg168, slv_reg169, slv_reg170, slv_reg171, slv_reg172, slv_reg173, slv_reg174, slv_reg175, slv_reg176, slv_reg177, slv_reg178, slv_reg179, slv_reg180, slv_reg181, slv_reg182, slv_reg183, slv_reg184, slv_reg185, slv_reg186, slv_reg187, slv_reg188, slv_reg189, slv_reg190, slv_reg191, slv_reg192, slv_reg193, slv_reg194, slv_reg195, slv_reg196, slv_reg197, slv_reg198, slv_reg199, slv_reg200, slv_reg201, slv_reg202, slv_reg203, slv_reg204, slv_reg205, slv_reg206, slv_reg207, slv_reg208, slv_reg209, slv_reg210, slv_reg211, slv_reg212, slv_reg213, slv_reg214, slv_reg215, slv_reg216, slv_reg217, slv_reg218, slv_reg219, slv_reg220, slv_reg221, slv_reg222, slv_reg223, slv_reg224, slv_reg225, slv_reg226, slv_reg227, slv_reg228, slv_reg229, slv_reg230, slv_reg231, slv_reg232, slv_reg233, slv_reg234, slv_reg235, slv_reg236, slv_reg237, slv_reg238, slv_reg239, slv_reg240, slv_reg241, slv_reg242, slv_reg243, slv_reg244, slv_reg245, slv_reg246, slv_reg247, slv_reg248, slv_reg249, slv_reg250, slv_reg251, slv_reg252, slv_reg253, slv_reg254, slv_reg255, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"00000000" =>
	        reg_data_out <= slv_reg0_sequence_generator_en;
	      when b"00000001" =>
	        reg_data_out <= slv_reg1_set_nr_sections;
	      when b"00000010" =>
	        reg_data_out <= slv_reg2_write_sel_section;
	      when b"00000011" =>
	        reg_data_out <= slv_reg3_set_section_type;
	      when b"00000100" =>
	        reg_data_out <= slv_reg4_set_delay;
	      when b"00000101" =>
	        reg_data_out <= slv_reg5_set_mux;
	      when b"00000110" =>
	        reg_data_out <= slv_reg6_set_start_repeat_pointer;
	      when b"00000111" =>
	        reg_data_out <= slv_reg7_set_end_repeat_pointer;
	      when b"00001000" =>
	        reg_data_out <= slv_reg8_set_cycle_repetition_number;
	      when b"00001001" =>
	        reg_data_out <= slv_reg9_set_experiment_repetition_number;
	      when b"00001010" =>
	        reg_data_out <= slv_reg10_set_phase_ch0;
	      when b"00001011" =>
	        reg_data_out <= slv_reg11_set_frequency_ch0;
	      when b"00001100" =>
	        reg_data_out <= slv_reg12_set_phase_ch1;
	      when b"00001101" =>
	        reg_data_out <= slv_reg13_set_frequency_ch1;
	      when b"00001110" =>
	        reg_data_out <= slv_reg14_set_resetn_dds;
	      when b"00001111" =>
	        reg_data_out <= slv_reg15_busy;
	      when b"00010000" =>
	        reg_data_out <= slv_reg16_data_ready;
	      when b"00010001" =>
	        reg_data_out <= slv_reg17_nr_dds_ch;
	      when b"00010010" =>
	        reg_data_out <= slv_reg18_mem_depth;
	      when b"00010011" =>
	        reg_data_out <= slv_reg19_nr_activity;
	      when b"00010100" =>
	        reg_data_out <= slv_reg20_led;
	      when b"00010101" =>
	        reg_data_out <= slv_reg21_gradient_x;
	      when b"00010110" =>
	        reg_data_out <= slv_reg22_gradient_y;
	      when b"00010111" =>
	        reg_data_out <= slv_reg23_gradient_z;
	      when b"00011000" =>
	        reg_data_out <= slv_reg24_gradient_x_ref;
	      when b"00011001" =>
	        reg_data_out <= slv_reg25_gradient_y_ref;
	      when b"00011010" =>
	        reg_data_out <= slv_reg26_gradient_z_ref;
	      when b"00011011" =>
	        reg_data_out <= slv_reg27_gradient_sweep;
	      when b"00011100" =>
	        reg_data_out <= slv_reg28_gradient_x_sweep_step;
	      when b"00011101" =>
	        reg_data_out <= slv_reg29_gradient_y_sweep_step;
	      when b"00011110" =>
	        reg_data_out <= slv_reg30_gradient_z_sweep_step;
	      when b"00011111" =>
	        reg_data_out <= slv_reg31_gradient_x_sweep_offset;
	      when b"00100000" =>
	        reg_data_out <= slv_reg32_gradient_y_sweep_offset;
	      when b"00100001" =>
	        reg_data_out <= slv_reg33_gradient_z_sweep_offset;
	      -- when b"00100010" =>
	        -- reg_data_out <= slv_reg34;
	      -- when b"00100011" =>
	        -- reg_data_out <= slv_reg35;
	      -- when b"00100100" =>
	        -- reg_data_out <= slv_reg36;
	      -- when b"00100101" =>
	        -- reg_data_out <= slv_reg37;
	      -- when b"00100110" =>
	        -- reg_data_out <= slv_reg38;
	      -- when b"00100111" =>
	        -- reg_data_out <= slv_reg39;
	      -- when b"00101000" =>
	        -- reg_data_out <= slv_reg40;
	      -- when b"00101001" =>
	        -- reg_data_out <= slv_reg41;
	      -- when b"00101010" =>
	        -- reg_data_out <= slv_reg42;
	      -- when b"00101011" =>
	        -- reg_data_out <= slv_reg43;
	      -- when b"00101100" =>
	        -- reg_data_out <= slv_reg44;
	      -- when b"00101101" =>
	        -- reg_data_out <= slv_reg45;
	      -- when b"00101110" =>
	        -- reg_data_out <= slv_reg46;
	      -- when b"00101111" =>
	        -- reg_data_out <= slv_reg47;
	      -- when b"00110000" =>
	        -- reg_data_out <= slv_reg48;
	      -- when b"00110001" =>
	        -- reg_data_out <= slv_reg49;
	      -- when b"00110010" =>
	        -- reg_data_out <= slv_reg50;
	      -- when b"00110011" =>
	        -- reg_data_out <= slv_reg51;
	      -- when b"00110100" =>
	        -- reg_data_out <= slv_reg52;
	      -- when b"00110101" =>
	        -- reg_data_out <= slv_reg53;
	      -- when b"00110110" =>
	        -- reg_data_out <= slv_reg54;
	      -- when b"00110111" =>
	        -- reg_data_out <= slv_reg55;
	      -- when b"00111000" =>
	        -- reg_data_out <= slv_reg56;
	      -- when b"00111001" =>
	        -- reg_data_out <= slv_reg57;
	      -- when b"00111010" =>
	        -- reg_data_out <= slv_reg58;
	      -- when b"00111011" =>
	        -- reg_data_out <= slv_reg59;
	      -- when b"00111100" =>
	        -- reg_data_out <= slv_reg60;
	      -- when b"00111101" =>
	        -- reg_data_out <= slv_reg61;
	      -- when b"00111110" =>
	        -- reg_data_out <= slv_reg62;
	      -- when b"00111111" =>
	        -- reg_data_out <= slv_reg63;
	      -- when b"01000000" =>
	        -- reg_data_out <= slv_reg64;
	      -- when b"01000001" =>
	        -- reg_data_out <= slv_reg65;
	      -- when b"01000010" =>
	        -- reg_data_out <= slv_reg66;
	      -- when b"01000011" =>
	        -- reg_data_out <= slv_reg67;
	      -- when b"01000100" =>
	        -- reg_data_out <= slv_reg68;
	      -- when b"01000101" =>
	        -- reg_data_out <= slv_reg69;
	      -- when b"01000110" =>
	        -- reg_data_out <= slv_reg70;
	      -- when b"01000111" =>
	        -- reg_data_out <= slv_reg71;
	      -- when b"01001000" =>
	        -- reg_data_out <= slv_reg72;
	      -- when b"01001001" =>
	        -- reg_data_out <= slv_reg73;
	      -- when b"01001010" =>
	        -- reg_data_out <= slv_reg74;
	      -- when b"01001011" =>
	        -- reg_data_out <= slv_reg75;
	      -- when b"01001100" =>
	        -- reg_data_out <= slv_reg76;
	      -- when b"01001101" =>
	        -- reg_data_out <= slv_reg77;
	      -- when b"01001110" =>
	        -- reg_data_out <= slv_reg78;
	      -- when b"01001111" =>
	        -- reg_data_out <= slv_reg79;
	      -- when b"01010000" =>
	        -- reg_data_out <= slv_reg80;
	      -- when b"01010001" =>
	        -- reg_data_out <= slv_reg81;
	      -- when b"01010010" =>
	        -- reg_data_out <= slv_reg82;
	      -- when b"01010011" =>
	        -- reg_data_out <= slv_reg83;
	      -- when b"01010100" =>
	        -- reg_data_out <= slv_reg84;
	      -- when b"01010101" =>
	        -- reg_data_out <= slv_reg85;
	      -- when b"01010110" =>
	        -- reg_data_out <= slv_reg86;
	      -- when b"01010111" =>
	        -- reg_data_out <= slv_reg87;
	      -- when b"01011000" =>
	        -- reg_data_out <= slv_reg88;
	      -- when b"01011001" =>
	        -- reg_data_out <= slv_reg89;
	      -- when b"01011010" =>
	        -- reg_data_out <= slv_reg90;
	      -- when b"01011011" =>
	        -- reg_data_out <= slv_reg91;
	      -- when b"01011100" =>
	        -- reg_data_out <= slv_reg92;
	      -- when b"01011101" =>
	        -- reg_data_out <= slv_reg93;
	      -- when b"01011110" =>
	        -- reg_data_out <= slv_reg94;
	      -- when b"01011111" =>
	        -- reg_data_out <= slv_reg95;
	      -- when b"01100000" =>
	        -- reg_data_out <= slv_reg96;
	      -- when b"01100001" =>
	        -- reg_data_out <= slv_reg97;
	      -- when b"01100010" =>
	        -- reg_data_out <= slv_reg98;
	      -- when b"01100011" =>
	        -- reg_data_out <= slv_reg99;
	      -- when b"01100100" =>
	        -- reg_data_out <= slv_reg100;
	      -- when b"01100101" =>
	        -- reg_data_out <= slv_reg101;
	      -- when b"01100110" =>
	        -- reg_data_out <= slv_reg102;
	      -- when b"01100111" =>
	        -- reg_data_out <= slv_reg103;
	      -- when b"01101000" =>
	        -- reg_data_out <= slv_reg104;
	      -- when b"01101001" =>
	        -- reg_data_out <= slv_reg105;
	      -- when b"01101010" =>
	        -- reg_data_out <= slv_reg106;
	      -- when b"01101011" =>
	        -- reg_data_out <= slv_reg107;
	      -- when b"01101100" =>
	        -- reg_data_out <= slv_reg108;
	      -- when b"01101101" =>
	        -- reg_data_out <= slv_reg109;
	      -- when b"01101110" =>
	        -- reg_data_out <= slv_reg110;
	      -- when b"01101111" =>
	        -- reg_data_out <= slv_reg111;
	      -- when b"01110000" =>
	        -- reg_data_out <= slv_reg112;
	      -- when b"01110001" =>
	        -- reg_data_out <= slv_reg113;
	      -- when b"01110010" =>
	        -- reg_data_out <= slv_reg114;
	      -- when b"01110011" =>
	        -- reg_data_out <= slv_reg115;
	      -- when b"01110100" =>
	        -- reg_data_out <= slv_reg116;
	      -- when b"01110101" =>
	        -- reg_data_out <= slv_reg117;
	      -- when b"01110110" =>
	        -- reg_data_out <= slv_reg118;
	      -- when b"01110111" =>
	        -- reg_data_out <= slv_reg119;
	      -- when b"01111000" =>
	        -- reg_data_out <= slv_reg120;
	      -- when b"01111001" =>
	        -- reg_data_out <= slv_reg121;
	      -- when b"01111010" =>
	        -- reg_data_out <= slv_reg122;
	      -- when b"01111011" =>
	        -- reg_data_out <= slv_reg123;
	      -- when b"01111100" =>
	        -- reg_data_out <= slv_reg124;
	      -- when b"01111101" =>
	        -- reg_data_out <= slv_reg125;
	      -- when b"01111110" =>
	        -- reg_data_out <= slv_reg126;
	      -- when b"01111111" =>
	        -- reg_data_out <= slv_reg127;
	      -- when b"10000000" =>
	        -- reg_data_out <= slv_reg128;
	      -- when b"10000001" =>
	        -- reg_data_out <= slv_reg129;
	      -- when b"10000010" =>
	        -- reg_data_out <= slv_reg130;
	      -- when b"10000011" =>
	        -- reg_data_out <= slv_reg131;
	      -- when b"10000100" =>
	        -- reg_data_out <= slv_reg132;
	      -- when b"10000101" =>
	        -- reg_data_out <= slv_reg133;
	      -- when b"10000110" =>
	        -- reg_data_out <= slv_reg134;
	      -- when b"10000111" =>
	        -- reg_data_out <= slv_reg135;
	      -- when b"10001000" =>
	        -- reg_data_out <= slv_reg136;
	      -- when b"10001001" =>
	        -- reg_data_out <= slv_reg137;
	      -- when b"10001010" =>
	        -- reg_data_out <= slv_reg138;
	      -- when b"10001011" =>
	        -- reg_data_out <= slv_reg139;
	      -- when b"10001100" =>
	        -- reg_data_out <= slv_reg140;
	      -- when b"10001101" =>
	        -- reg_data_out <= slv_reg141;
	      -- when b"10001110" =>
	        -- reg_data_out <= slv_reg142;
	      -- when b"10001111" =>
	        -- reg_data_out <= slv_reg143;
	      -- when b"10010000" =>
	        -- reg_data_out <= slv_reg144;
	      -- when b"10010001" =>
	        -- reg_data_out <= slv_reg145;
	      -- when b"10010010" =>
	        -- reg_data_out <= slv_reg146;
	      -- when b"10010011" =>
	        -- reg_data_out <= slv_reg147;
	      -- when b"10010100" =>
	        -- reg_data_out <= slv_reg148;
	      -- when b"10010101" =>
	        -- reg_data_out <= slv_reg149;
	      -- when b"10010110" =>
	        -- reg_data_out <= slv_reg150;
	      -- when b"10010111" =>
	        -- reg_data_out <= slv_reg151;
	      -- when b"10011000" =>
	        -- reg_data_out <= slv_reg152;
	      -- when b"10011001" =>
	        -- reg_data_out <= slv_reg153;
	      -- when b"10011010" =>
	        -- reg_data_out <= slv_reg154;
	      -- when b"10011011" =>
	        -- reg_data_out <= slv_reg155;
	      -- when b"10011100" =>
	        -- reg_data_out <= slv_reg156;
	      -- when b"10011101" =>
	        -- reg_data_out <= slv_reg157;
	      -- when b"10011110" =>
	        -- reg_data_out <= slv_reg158;
	      -- when b"10011111" =>
	        -- reg_data_out <= slv_reg159;
	      -- when b"10100000" =>
	        -- reg_data_out <= slv_reg160;
	      -- when b"10100001" =>
	        -- reg_data_out <= slv_reg161;
	      -- when b"10100010" =>
	        -- reg_data_out <= slv_reg162;
	      -- when b"10100011" =>
	        -- reg_data_out <= slv_reg163;
	      -- when b"10100100" =>
	        -- reg_data_out <= slv_reg164;
	      -- when b"10100101" =>
	        -- reg_data_out <= slv_reg165;
	      -- when b"10100110" =>
	        -- reg_data_out <= slv_reg166;
	      -- when b"10100111" =>
	        -- reg_data_out <= slv_reg167;
	      -- when b"10101000" =>
	        -- reg_data_out <= slv_reg168;
	      -- when b"10101001" =>
	        -- reg_data_out <= slv_reg169;
	      -- when b"10101010" =>
	        -- reg_data_out <= slv_reg170;
	      -- when b"10101011" =>
	        -- reg_data_out <= slv_reg171;
	      -- when b"10101100" =>
	        -- reg_data_out <= slv_reg172;
	      -- when b"10101101" =>
	        -- reg_data_out <= slv_reg173;
	      -- when b"10101110" =>
	        -- reg_data_out <= slv_reg174;
	      -- when b"10101111" =>
	        -- reg_data_out <= slv_reg175;
	      -- when b"10110000" =>
	        -- reg_data_out <= slv_reg176;
	      -- when b"10110001" =>
	        -- reg_data_out <= slv_reg177;
	      -- when b"10110010" =>
	        -- reg_data_out <= slv_reg178;
	      -- when b"10110011" =>
	        -- reg_data_out <= slv_reg179;
	      -- when b"10110100" =>
	        -- reg_data_out <= slv_reg180;
	      -- when b"10110101" =>
	        -- reg_data_out <= slv_reg181;
	      -- when b"10110110" =>
	        -- reg_data_out <= slv_reg182;
	      -- when b"10110111" =>
	        -- reg_data_out <= slv_reg183;
	      -- when b"10111000" =>
	        -- reg_data_out <= slv_reg184;
	      -- when b"10111001" =>
	        -- reg_data_out <= slv_reg185;
	      -- when b"10111010" =>
	        -- reg_data_out <= slv_reg186;
	      -- when b"10111011" =>
	        -- reg_data_out <= slv_reg187;
	      -- when b"10111100" =>
	        -- reg_data_out <= slv_reg188;
	      -- when b"10111101" =>
	        -- reg_data_out <= slv_reg189;
	      -- when b"10111110" =>
	        -- reg_data_out <= slv_reg190;
	      -- when b"10111111" =>
	        -- reg_data_out <= slv_reg191;
	      -- when b"11000000" =>
	        -- reg_data_out <= slv_reg192;
	      -- when b"11000001" =>
	        -- reg_data_out <= slv_reg193;
	      -- when b"11000010" =>
	        -- reg_data_out <= slv_reg194;
	      -- when b"11000011" =>
	        -- reg_data_out <= slv_reg195;
	      -- when b"11000100" =>
	        -- reg_data_out <= slv_reg196;
	      -- when b"11000101" =>
	        -- reg_data_out <= slv_reg197;
	      -- when b"11000110" =>
	        -- reg_data_out <= slv_reg198;
	      -- when b"11000111" =>
	        -- reg_data_out <= slv_reg199;
	      -- when b"11001000" =>
	        -- reg_data_out <= slv_reg200;
	      -- when b"11001001" =>
	        -- reg_data_out <= slv_reg201;
	      -- when b"11001010" =>
	        -- reg_data_out <= slv_reg202;
	      -- when b"11001011" =>
	        -- reg_data_out <= slv_reg203;
	      -- when b"11001100" =>
	        -- reg_data_out <= slv_reg204;
	      -- when b"11001101" =>
	        -- reg_data_out <= slv_reg205;
	      -- when b"11001110" =>
	        -- reg_data_out <= slv_reg206;
	      -- when b"11001111" =>
	        -- reg_data_out <= slv_reg207;
	      -- when b"11010000" =>
	        -- reg_data_out <= slv_reg208;
	      -- when b"11010001" =>
	        -- reg_data_out <= slv_reg209;
	      -- when b"11010010" =>
	        -- reg_data_out <= slv_reg210;
	      -- when b"11010011" =>
	        -- reg_data_out <= slv_reg211;
	      -- when b"11010100" =>
	        -- reg_data_out <= slv_reg212;
	      -- when b"11010101" =>
	        -- reg_data_out <= slv_reg213;
	      -- when b"11010110" =>
	        -- reg_data_out <= slv_reg214;
	      -- when b"11010111" =>
	        -- reg_data_out <= slv_reg215;
	      -- when b"11011000" =>
	        -- reg_data_out <= slv_reg216;
	      -- when b"11011001" =>
	        -- reg_data_out <= slv_reg217;
	      -- when b"11011010" =>
	        -- reg_data_out <= slv_reg218;
	      -- when b"11011011" =>
	        -- reg_data_out <= slv_reg219;
	      -- when b"11011100" =>
	        -- reg_data_out <= slv_reg220;
	      -- when b"11011101" =>
	        -- reg_data_out <= slv_reg221;
	      -- when b"11011110" =>
	        -- reg_data_out <= slv_reg222;
	      -- when b"11011111" =>
	        -- reg_data_out <= slv_reg223;
	      -- when b"11100000" =>
	        -- reg_data_out <= slv_reg224;
	      -- when b"11100001" =>
	        -- reg_data_out <= slv_reg225;
	      -- when b"11100010" =>
	        -- reg_data_out <= slv_reg226;
	      -- when b"11100011" =>
	        -- reg_data_out <= slv_reg227;
	      -- when b"11100100" =>
	        -- reg_data_out <= slv_reg228;
	      -- when b"11100101" =>
	        -- reg_data_out <= slv_reg229;
	      -- when b"11100110" =>
	        -- reg_data_out <= slv_reg230;
	      -- when b"11100111" =>
	        -- reg_data_out <= slv_reg231;
	      -- when b"11101000" =>
	        -- reg_data_out <= slv_reg232;
	      -- when b"11101001" =>
	        -- reg_data_out <= slv_reg233;
	      -- when b"11101010" =>
	        -- reg_data_out <= slv_reg234;
	      -- when b"11101011" =>
	        -- reg_data_out <= slv_reg235;
	      -- when b"11101100" =>
	        -- reg_data_out <= slv_reg236;
	      -- when b"11101101" =>
	        -- reg_data_out <= slv_reg237;
	      -- when b"11101110" =>
	        -- reg_data_out <= slv_reg238;
	      -- when b"11101111" =>
	        -- reg_data_out <= slv_reg239;
	      -- when b"11110000" =>
	        -- reg_data_out <= slv_reg240;
	      -- when b"11110001" =>
	        -- reg_data_out <= slv_reg241;
	      -- when b"11110010" =>
	        -- reg_data_out <= slv_reg242;
	      -- when b"11110011" =>
	        -- reg_data_out <= slv_reg243;
	      -- when b"11110100" =>
	        -- reg_data_out <= slv_reg244;
	      -- when b"11110101" =>
	        -- reg_data_out <= slv_reg245;
	      -- when b"11110110" =>
	        -- reg_data_out <= slv_reg246;
	      -- when b"11110111" =>
	        -- reg_data_out <= slv_reg247;
	      -- when b"11111000" =>
	        -- reg_data_out <= slv_reg248;
	      -- when b"11111001" =>
	        -- reg_data_out <= slv_reg249;
	      -- when b"11111010" =>
	        -- reg_data_out <= slv_reg250;
	      -- when b"11111011" =>
	        -- reg_data_out <= slv_reg251;
	      -- when b"11111100" =>
	        -- reg_data_out <= slv_reg252;
	      -- when b"11111101" =>
	        -- reg_data_out <= slv_reg253;
	      -- when b"11111110" =>
	        -- reg_data_out <= slv_reg254;
	      -- when b"11111111" =>
	        -- reg_data_out <= slv_reg255;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	-- Add user logic here
	fpga_pulse_gen_top_inst: ENTITY work.fpga_pulse_gen_top(Behavioral)
	PORT MAP 
	(	
		clk							 		=> S_AXI_ACLK,				 			-- axi clock
		o_tx_pulse					 		=> o_tx_pulse,					-- transmitter activation pulse
		o_rx_pulse					 		=> o_rx_pulse,					-- receiver activation pulse
		ov_config_dds_data_ch0				=> ov_config_dds_data_ch0,
		o_config_tvalid_ch0					=> o_config_tvalid_ch0,
		ov_config_dds_data_ch1				=> ov_config_dds_data_ch1,
		o_config_tvalid_ch1					=> o_config_tvalid_ch1,
		o_dds_rstn							=> o_dds_rstn,		
		o_mux_ch							=> o_mux_ch,		
		i_en					 	 		=> slv_reg0_sequence_generator_en(0),
		iv_set_nr_sections  				=> unsigned(slv_reg1_set_nr_sections),
		iv_write_sel_section				=> unsigned(slv_reg2_write_sel_section),
		iv_set_section_type	 				=> unsigned(slv_reg3_set_section_type),
		iv_set_delay	 					=> unsigned(slv_reg4_set_delay),
		iv_set_mux		 					=> unsigned(slv_reg5_set_mux),
		iv_set_start_repeat_pointer  		=> unsigned(slv_reg6_set_start_repeat_pointer),
		iv_set_end_repeat_pointer			=> unsigned(slv_reg7_set_end_repeat_pointer),
		iv_set_cycle_repetition_number		=> unsigned(slv_reg8_set_cycle_repetition_number),
		iv_set_experiment_repetition_number => unsigned(slv_reg9_set_experiment_repetition_number),
		iv_set_phase_ch0					=> unsigned(slv_reg10_set_phase_ch0),
		iv_set_frequency_ch0 				=> unsigned(slv_reg11_set_frequency_ch0),
		iv_set_phase_ch1					=> unsigned(slv_reg12_set_phase_ch1),
		iv_set_frequency_ch1				=> unsigned(slv_reg13_set_frequency_ch1),
		iv_set_resetn_dds		 			=> unsigned(slv_reg14_set_resetn_dds), 		-- selects the dds channel to config	
		iv_set_gradient_x					=> unsigned(slv_reg21_gradient_x),
		iv_set_gradient_y					=> unsigned(slv_reg22_gradient_y),
		iv_set_gradient_z					=> unsigned(slv_reg23_gradient_z),
		iv_set_gradient_x_ref				=> unsigned(slv_reg24_gradient_x_ref),
		iv_set_gradient_y_ref				=> unsigned(slv_reg25_gradient_y_ref),
		iv_set_gradient_z_ref				=> unsigned(slv_reg26_gradient_z_ref),		
		o_busy			 					=> slv_reg15_busy(0), 						-- configuration the phase of dds
		o_data_ready		 				=> slv_reg16_data_ready(0),					-- configuraton the frequency of dds
		ov_nr_dds_ch						=> slv_reg17_nr_dds_ch,		
		ov_mem_depth				 		=> slv_reg18_mem_depth,				
		ov_nr_activity				 		=> slv_reg19_nr_activity,		-- get the number of the dds
		ov_set_gradient_x					=> gradient_x,
		ov_set_gradient_y					=> gradient_y,
		ov_set_gradient_z					=> gradient_z,
		ov_set_gradient_x_ref				=> gradient_x_ref,
		ov_set_gradient_y_ref				=> gradient_y_ref,
		ov_set_gradient_z_ref				=> gradient_z_ref,
		o_gradient_tvalid					=> o_gradient_tvalid,		
		iv_set_gradient_sweep		 		=> unsigned(slv_reg27_gradient_sweep),
		iv_set_gradient_x_sweep_step 		=> unsigned(slv_reg28_gradient_x_sweep_step),
		iv_set_gradient_y_sweep_step 		=> unsigned(slv_reg29_gradient_y_sweep_step),
		iv_set_gradient_z_sweep_step 		=> unsigned(slv_reg30_gradient_z_sweep_step),
		iv_set_gradient_x_sweep_offset 		=> unsigned(slv_reg31_gradient_x_sweep_offset),
		iv_set_gradient_y_sweep_offset 		=> unsigned(slv_reg32_gradient_y_sweep_offset),
		iv_set_gradient_z_sweep_offset 		=> unsigned(slv_reg33_gradient_z_sweep_offset)
		
	);
		o_pulse_gen_led		<= slv_reg20_led(0);
		ov_gradient_x		<= gradient_x(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);
		ov_gradient_y		<= gradient_y(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);
		ov_gradient_z		<= gradient_z(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);
		ov_gradient_x_ref	<= gradient_x_ref(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);
		ov_gradient_y_ref	<= gradient_y_ref(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);
		ov_gradient_z_ref	<= gradient_z_ref(C_GRADIENT_DAC_WIDTH - 1 DOWNTO 0);		
	-- User logic ends
end arch_imp;
