library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library UNISIM;
use UNISIM.Vcomponents.all;
entity AD7960 is
  port
  (
    CLK250               : in    std_logic;
    data_ready           : out   std_logic;
    data                 : out   std_logic_vector(17 downto 0);
    EN                   : out   std_logic_vector(3 downto 0);
    CLKp                 : out   std_logic;
    CLKn                 : out   std_logic;
    CNVp                 : out   std_logic;
    CNVn                 : out   std_logic;
    DCOp                 : in    std_logic;
    DCOn                 : in    std_logic;
    Dp                   : in    std_logic;
    Dn                   : in    std_logic
  );
end AD7960;
architecture rtl of AD7960 is
signal DCO                   : std_logic := '0';
signal D                     : std_logic := '0';
signal CLK                   : std_logic := '0';
signal CNV                   : std_logic := '0';
signal data_buffer           : std_logic_vector(17 downto 0) := (others => '0');
signal counter_250           : integer range 0 to 49 := 0;
signal CNV_data              : std_logic_vector(0 to 49) := "11100000000000000000000000000000000000000000000000";
signal CLK_data              : std_logic_vector(0 to 49) := "10101010101010101010101010101010101000000000000000";
signal io_reset              : std_logic := '0';
signal initcounter           : integer range 0 to 63 := 0;
begin
EN                           <= "1010"; -- Normal: 0010, TEST: 1100
IBUFDS_DCO: IBUFDS
  generic map
  (
    DIFF_TERM            => TRUE,
    IBUF_LOW_PWR         => FALSE,
    IOSTANDARD           => "LVDS_25"
  )
  port map
  (
    O                    => DCO,
    I                    => DCOp,
    IB                   => DCOn
  );
IBUFDS_D: IBUFDS
  generic map
  (
    DIFF_TERM            => TRUE,
    IBUF_LOW_PWR         => FALSE,
    IOSTANDARD           => "LVDS_25"
  )
  port map
  (
    O                    => D,
    I                    => Dp,
    IB                   => Dn
  );
OBUFDS_CLK: OBUFDS
  generic map
  (
    IOSTANDARD           => "LVDS_25",
    SLEW                 => "FAST"
  )
  port map
  (
    O                    => CLKp, 
    OB                   => CLKn,
    I                    => CLK
  );
OBUFDS_CNV: OBUFDS
  generic map
  (
    IOSTANDARD           => "LVDS_25",
    SLEW                 => "FAST"
  )
  port map
  (
    O                    => CNVp, 
    OB                   => CNVn,
    I                    => CNV
  );
process begin
  wait until rising_edge(CLK250);
  if initcounter < 63 then
    initcounter          <= initcounter + 1;
  end if;
  io_reset                 <= '0';
  if initcounter > 19 and initcounter < 60 then
    io_reset             <= '1';
  end if;
  counter_250              <= counter_250 + 1;
  if counter_250 = 49 then
    counter_250          <= 0;
  end if;
  CLK                      <= CLK_data(counter_250);
  CNV                      <= CNV_data(counter_250);
  data_ready               <= '0';
  if counter_250 = 43 then
    data_ready           <= '1';
    data                 <= data_buffer;
  end if;
end process;
process begin
  wait until rising_edge(DCO);
  data_buffer              <= data_buffer(16 downto 0) & D;
end process;
end;