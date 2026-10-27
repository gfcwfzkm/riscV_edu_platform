library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wishBoneCrossbarBusTop is
  generic( DataBits : integer := 32;
           AddrBits : integer := 32;
           priorityScheme : integer := 1);  port (
    -- Here the signals for the master "debugIf" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    debugIf_CLK_I : out std_logic;
    debugIf_RST_I : out std_logic;
    debugIf_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    debugIf_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    debugIf_ACK_I : out std_logic;
    debugIf_ADDR_O : in  std_logic_vector((AddrBits - 1) downto 0);
    debugIf_CYC_O : in  std_logic;
    debugIf_ERR_I : out std_logic;
    debugIf_LOCK_O : in  std_logic;
    debugIf_SEL_O : in  std_logic_vector(((DataBits / 8) - 1) downto 0);
    debugIf_STB_O : in  std_logic;
    debugIf_WE_O : in  std_logic;
    debugIf_CTI_O : in  std_logic_vector(2 downto 0);
    debugIf_BTE_O : in  std_logic_vector(1 downto 0);

    -- Here the signals for the slave "sramSlave" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    sramSlave_CLK_I : out std_logic;
    sramSlave_RST_I : out std_logic;
    sramSlave_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    sramSlave_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    sramSlave_ACK_O : in  std_logic;
    sramSlave_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    sramSlave_CYC_I : out std_logic;
    sramSlave_ERR_O : in  std_logic;
    sramSlave_LOCK_I : out std_logic;
    sramSlave_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    sramSlave_STB_I : out std_logic;
    sramSlave_WE_I : out std_logic;
    sramSlave_CTI_I : out std_logic_vector(2 downto 0);
    sramSlave_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "leds" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    leds_CLK_I : out std_logic;
    leds_RST_I : out std_logic;
    leds_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    leds_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    leds_ACK_O : in  std_logic;
    leds_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    leds_CYC_I : out std_logic;
    leds_ERR_O : in  std_logic;
    leds_LOCK_I : out std_logic;
    leds_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    leds_STB_I : out std_logic;
    leds_WE_I : out std_logic;
    leds_CTI_I : out std_logic_vector(2 downto 0);
    leds_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "sevenSegments" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    sevenSegments_CLK_I : out std_logic;
    sevenSegments_RST_I : out std_logic;
    sevenSegments_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    sevenSegments_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    sevenSegments_ACK_O : in  std_logic;
    sevenSegments_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    sevenSegments_CYC_I : out std_logic;
    sevenSegments_ERR_O : in  std_logic;
    sevenSegments_LOCK_I : out std_logic;
    sevenSegments_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    sevenSegments_STB_I : out std_logic;
    sevenSegments_WE_I : out std_logic;
    sevenSegments_CTI_I : out std_logic_vector(2 downto 0);
    sevenSegments_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the signals for the slave "uartBus" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    uartBus_CLK_I : out std_logic;
    uartBus_RST_I : out std_logic;
    uartBus_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    uartBus_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    uartBus_ACK_O : in  std_logic;
    uartBus_ADDR_I : out std_logic_vector((AddrBits - 1) downto 0);
    uartBus_CYC_I : out std_logic;
    uartBus_ERR_O : in  std_logic;
    uartBus_LOCK_I : out std_logic;
    uartBus_SEL_I : out std_logic_vector(((DataBits / 8) - 1) downto 0);
    uartBus_STB_I : out std_logic;
    uartBus_WE_I : out std_logic;
    uartBus_CTI_I : out std_logic_vector(2 downto 0);
    uartBus_BTE_I : out std_logic_vector(1 downto 0);

    -- Here the Syscon connections are defined
    -- Connect the signals with the same name together
    -- Note that although we have the _O suffix these are inputs as
    -- they are outputs on the syscon component
    CLK_O : in  std_logic;
    RST_O : in  std_logic);
end entity wishBoneCrossbarBusTop;

architecture autogenerated of wishBoneCrossbarBusTop is

  signal s_sramSlave_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_leds_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_sevenSegments_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_debugIf_ACK_I : std_logic;
  signal s_sramSlave_debugIf_ACK_I : std_logic;
  signal s_leds_debugIf_ACK_I : std_logic;
  signal s_sevenSegments_debugIf_ACK_I : std_logic;
  signal s_uartBus_debugIf_ACK_I : std_logic;
  signal s_sramSlave_debugIf_ERR_I : std_logic;
  signal s_leds_debugIf_ERR_I : std_logic;
  signal s_sevenSegments_debugIf_ERR_I : std_logic;
  signal s_uartBus_debugIf_ERR_I : std_logic;
  signal s_debugIf_arbiterTimeOut : std_logic;
  signal s_debugIf_arbiterTimeOutCounter : unsigned(15 downto 0);

begin

  -- Here all master clock connections are defined
  debugIf_CLK_I <= CLK_O;
  debugIf_RST_I <= RST_O;

  arbiter0 : entity work.wishBoneSlaveArbiter(autogenerated)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits,
    BaseAddress => std_logic_vector(to_unsigned(16#0#, AddrBits)),
    EndAddress => std_logic_vector(to_unsigned(16#ffff#, AddrBits)),
    priorityScheme => priorityScheme)
  port map (
    debugIf_DAT_I => s_sramSlave_debugIf_DAT_I,
    debugIf_DAT_O => debugIf_DAT_O,
    debugIf_ACK_I => s_sramSlave_debugIf_ACK_I,
    debugIf_ADDR_O => debugIf_ADDR_O,
    debugIf_CYC_O => debugIf_CYC_O,
    debugIf_ERR_I => s_sramSlave_debugIf_ERR_I,
    debugIf_LOCK_O => debugIf_LOCK_O,
    debugIf_SEL_O => debugIf_SEL_O,
    debugIf_STB_O => debugIf_STB_O,
    debugIf_WE_O => debugIf_WE_O,
    debugIf_CTI_O => debugIf_CTI_O,
    debugIf_BTE_O => debugIf_BTE_O,
    slave_port_CLK_I => sramSlave_CLK_I,
    slave_port_RST_I => sramSlave_RST_I,
    slave_port_DAT_I => sramSlave_DAT_I,
    slave_port_DAT_O => sramSlave_DAT_O,
    slave_port_ACK_O => sramSlave_ACK_O,
    slave_port_ADDR_I => sramSlave_ADDR_I,
    slave_port_CYC_I => sramSlave_CYC_I,
    slave_port_ERR_O => sramSlave_ERR_O,
    slave_port_LOCK_I => sramSlave_LOCK_I,
    slave_port_SEL_I => sramSlave_SEL_I,
    slave_port_STB_I => sramSlave_STB_I,
    slave_port_WE_I => sramSlave_WE_I,
    slave_port_CTI_I => sramSlave_CTI_I,
    slave_port_BTE_I => sramSlave_BTE_I,
    CLK_O => CLK_O,
    RST_O => RST_O);

  arbiter1 : entity work.wishBoneSlaveArbiter(autogenerated)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits,
    BaseAddress => std_logic_vector(to_unsigned(16#10000#, AddrBits)),
    EndAddress => std_logic_vector(to_unsigned(16#107ff#, AddrBits)),
    priorityScheme => priorityScheme)
  port map (
    debugIf_DAT_I => s_leds_debugIf_DAT_I,
    debugIf_DAT_O => debugIf_DAT_O,
    debugIf_ACK_I => s_leds_debugIf_ACK_I,
    debugIf_ADDR_O => debugIf_ADDR_O,
    debugIf_CYC_O => debugIf_CYC_O,
    debugIf_ERR_I => s_leds_debugIf_ERR_I,
    debugIf_LOCK_O => debugIf_LOCK_O,
    debugIf_SEL_O => debugIf_SEL_O,
    debugIf_STB_O => debugIf_STB_O,
    debugIf_WE_O => debugIf_WE_O,
    debugIf_CTI_O => debugIf_CTI_O,
    debugIf_BTE_O => debugIf_BTE_O,
    slave_port_CLK_I => leds_CLK_I,
    slave_port_RST_I => leds_RST_I,
    slave_port_DAT_I => leds_DAT_I,
    slave_port_DAT_O => leds_DAT_O,
    slave_port_ACK_O => leds_ACK_O,
    slave_port_ADDR_I => leds_ADDR_I,
    slave_port_CYC_I => leds_CYC_I,
    slave_port_ERR_O => leds_ERR_O,
    slave_port_LOCK_I => leds_LOCK_I,
    slave_port_SEL_I => leds_SEL_I,
    slave_port_STB_I => leds_STB_I,
    slave_port_WE_I => leds_WE_I,
    slave_port_CTI_I => leds_CTI_I,
    slave_port_BTE_I => leds_BTE_I,
    CLK_O => CLK_O,
    RST_O => RST_O);

  arbiter2 : entity work.wishBoneSlaveArbiter(autogenerated)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits,
    BaseAddress => std_logic_vector(to_unsigned(16#10800#, AddrBits)),
    EndAddress => std_logic_vector(to_unsigned(16#1081f#, AddrBits)),
    priorityScheme => priorityScheme)
  port map (
    debugIf_DAT_I => s_sevenSegments_debugIf_DAT_I,
    debugIf_DAT_O => debugIf_DAT_O,
    debugIf_ACK_I => s_sevenSegments_debugIf_ACK_I,
    debugIf_ADDR_O => debugIf_ADDR_O,
    debugIf_CYC_O => debugIf_CYC_O,
    debugIf_ERR_I => s_sevenSegments_debugIf_ERR_I,
    debugIf_LOCK_O => debugIf_LOCK_O,
    debugIf_SEL_O => debugIf_SEL_O,
    debugIf_STB_O => debugIf_STB_O,
    debugIf_WE_O => debugIf_WE_O,
    debugIf_CTI_O => debugIf_CTI_O,
    debugIf_BTE_O => debugIf_BTE_O,
    slave_port_CLK_I => sevenSegments_CLK_I,
    slave_port_RST_I => sevenSegments_RST_I,
    slave_port_DAT_I => sevenSegments_DAT_I,
    slave_port_DAT_O => sevenSegments_DAT_O,
    slave_port_ACK_O => sevenSegments_ACK_O,
    slave_port_ADDR_I => sevenSegments_ADDR_I,
    slave_port_CYC_I => sevenSegments_CYC_I,
    slave_port_ERR_O => sevenSegments_ERR_O,
    slave_port_LOCK_I => sevenSegments_LOCK_I,
    slave_port_SEL_I => sevenSegments_SEL_I,
    slave_port_STB_I => sevenSegments_STB_I,
    slave_port_WE_I => sevenSegments_WE_I,
    slave_port_CTI_I => sevenSegments_CTI_I,
    slave_port_BTE_I => sevenSegments_BTE_I,
    CLK_O => CLK_O,
    RST_O => RST_O);

  arbiter3 : entity work.wishBoneSlaveArbiter(autogenerated)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits,
    BaseAddress => std_logic_vector(to_unsigned(16#10820#, AddrBits)),
    EndAddress => std_logic_vector(to_unsigned(16#10827#, AddrBits)),
    priorityScheme => priorityScheme)
  port map (
    debugIf_DAT_I => s_uartBus_debugIf_DAT_I,
    debugIf_DAT_O => debugIf_DAT_O,
    debugIf_ACK_I => s_uartBus_debugIf_ACK_I,
    debugIf_ADDR_O => debugIf_ADDR_O,
    debugIf_CYC_O => debugIf_CYC_O,
    debugIf_ERR_I => s_uartBus_debugIf_ERR_I,
    debugIf_LOCK_O => debugIf_LOCK_O,
    debugIf_SEL_O => debugIf_SEL_O,
    debugIf_STB_O => debugIf_STB_O,
    debugIf_WE_O => debugIf_WE_O,
    debugIf_CTI_O => debugIf_CTI_O,
    debugIf_BTE_O => debugIf_BTE_O,
    slave_port_CLK_I => uartBus_CLK_I,
    slave_port_RST_I => uartBus_RST_I,
    slave_port_DAT_I => uartBus_DAT_I,
    slave_port_DAT_O => uartBus_DAT_O,
    slave_port_ACK_O => uartBus_ACK_O,
    slave_port_ADDR_I => uartBus_ADDR_I,
    slave_port_CYC_I => uartBus_CYC_I,
    slave_port_ERR_O => uartBus_ERR_O,
    slave_port_LOCK_I => uartBus_LOCK_I,
    slave_port_SEL_I => uartBus_SEL_I,
    slave_port_STB_I => uartBus_STB_I,
    slave_port_WE_I => uartBus_WE_I,
    slave_port_CTI_I => uartBus_CTI_I,
    slave_port_BTE_I => uartBus_BTE_I,
    CLK_O => CLK_O,
    RST_O => RST_O);

  -- Here the master output signals are defined
  debugIf_DAT_I <=
    s_sramSlave_debugIf_DAT_I or
    s_leds_debugIf_DAT_I or
    s_sevenSegments_debugIf_DAT_I or
    s_uartBus_debugIf_DAT_I;

  debugIf_ACK_I <= s_debugIf_ACK_I;
  s_debugIf_ACK_I <=
    s_sramSlave_debugIf_ACK_I or
    s_leds_debugIf_ACK_I or
    s_sevenSegments_debugIf_ACK_I or
    s_uartBus_debugIf_ACK_I;

  debugIf_ERR_I <=
    s_sramSlave_debugIf_ERR_I or
    s_leds_debugIf_ERR_I or
    s_sevenSegments_debugIf_ERR_I or
    s_uartBus_debugIf_ERR_I or
    s_debugIf_arbiterTimeOut;

  s_debugIf_arbiterTimeOut <= '1' when s_debugIf_arbiterTimeOutCounter = to_unsigned(0, 16) else '0';

  proc_0 : process( CLK_O ) is
    begin
      if (rising_edge(CLK_O)) then
        if (RST_O = '1' or
            debugIf_CYC_O = '0' or
            s_debugIf_ACK_I = '1') then
          s_debugIf_arbiterTimeOutCounter <= (others => '1');
        elsif (s_debugIf_arbiterTimeOut = '0') then
          s_debugIf_arbiterTimeOutCounter <= s_debugIf_arbiterTimeOutCounter - to_unsigned(1, 16);
        end if;
      end if;
    end process proc_0;

end architecture autogenerated;
