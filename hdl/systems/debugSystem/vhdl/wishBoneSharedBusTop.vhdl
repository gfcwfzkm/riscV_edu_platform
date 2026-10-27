library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wishBoneSharedBusTop is
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
end entity wishBoneSharedBusTop;

architecture autogenerated of wishBoneSharedBusTop is

  signal s_masked_debugIf_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_debugIf_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_masked_debugIf_CYC_O : std_logic;
  signal s_masked_debugIf_LOCK_O : std_logic;
  signal s_masked_debugIf_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_masked_debugIf_STB_O : std_logic;
  signal s_masked_debugIf_WE_O : std_logic;
  signal s_masked_debugIf_CTI_O : std_logic_vector(2 downto 0);
  signal s_masked_debugIf_BTE_O : std_logic_vector(1 downto 0);
  signal s_masked_sramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_leds_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_sevenSegments_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_uartBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_sharedBusMaster_DAT : std_logic_vector(DataBits - 1 downto 0);
  signal s_sharedBusMaster_ACK : std_logic;
  signal s_sharedBusMaster_ERR : std_logic;
  signal s_sharedBusSlave_DAT : std_logic_vector(DataBits - 1 downto 0);
  signal s_sharedBusSlave_ADDR : std_logic_vector(AddrBits - 1 downto 0);
  signal s_sharedBusSlave_CYC : std_logic;
  signal s_sharedBusSlave_LOCK : std_logic;
  signal s_sharedBusSlave_SEL : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_sharedBusSlave_STB : std_logic;
  signal s_sharedBusSlave_WE : std_logic;
  signal s_sharedBusSlave_CTI : std_logic_vector(2 downto 0);
  signal s_sharedBusSlave_BTE : std_logic_vector(1 downto 0);
  signal s_arbiterMasterCycs : std_logic;
  signal s_arbiterMasterLocks : std_logic;
  signal s_arbiterBusEnables : std_logic;
  signal s_arbiterErrorOut : std_logic;
  signal s_arbiterMaskReg : std_logic;
  signal s_arbiterEnablesReg : std_logic;
  signal s_arbiterTimeOutReg : std_logic_vector(15 downto 0);
  signal s_arbiterBusIsUsedReg : std_logic;
  signal s_arbiterBeforeMeCarries : std_logic;
  signal s_arbiterAferMeCarries : std_logic;
  signal s_arbiterBeforeMeMask : std_logic;
  signal s_arbiterAfterMeMask : std_logic;
  signal s_arbiterNewMask : std_logic;
  signal s_arbiterServeRequest : std_logic;
  signal s_arbiterIsTimeOut : std_logic;
  signal s_arbiterIsBusRelease : std_logic;

begin

  -- Here we connect all clocks and resets to the syscon
  debugIf_CLK_I <= CLK_O;
  debugIf_RST_I <= RST_O;
  sramSlave_CLK_I <= CLK_O;
  sramSlave_RST_I <= RST_O;
  leds_CLK_I <= CLK_O;
  leds_RST_I <= RST_O;
  sevenSegments_CLK_I <= CLK_O;
  sevenSegments_RST_I <= RST_O;
  uartBus_CLK_I <= CLK_O;
  uartBus_RST_I <= RST_O;

  -- Here the arbiter signals are mapped
  s_arbiterMasterLocks <= debugIf_LOCK_O;
  s_arbiterMasterCycs <= debugIf_CYC_O;

  -- Here the masked slave signals are defined
  s_masked_sramSlave_DAT_O <= sramSlave_DAT_O when sramSlave_ACK_O = '1' else (others => '0');
  s_masked_leds_DAT_O <= leds_DAT_O when leds_ACK_O = '1' else (others => '0');
  s_masked_sevenSegments_DAT_O <= sevenSegments_DAT_O when sevenSegments_ACK_O = '1' else (others => '0');
  s_masked_uartBus_DAT_O <= uartBus_DAT_O when uartBus_ACK_O = '1' else (others => '0');

  -- Here the masked master signals are defined
  s_masked_debugIf_DAT_O <= debugIf_DAT_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_debugIf_ADDR_O <= debugIf_ADDR_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_debugIf_CYC_O <= debugIf_CYC_O when s_arbiterBusEnables = '1' else '0';
  s_masked_debugIf_LOCK_O <= debugIf_LOCK_O when s_arbiterBusEnables = '1' else '0';
  s_masked_debugIf_SEL_O <= debugIf_SEL_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_debugIf_STB_O <= debugIf_STB_O when s_arbiterBusEnables = '1' else '0';
  s_masked_debugIf_WE_O <= debugIf_WE_O when s_arbiterBusEnables = '1' else '0';
  s_masked_debugIf_CTI_O <= debugIf_CTI_O when s_arbiterBusEnables = '1' else (others => '0');
  s_masked_debugIf_BTE_O <= debugIf_BTE_O when s_arbiterBusEnables = '1' else (others => '0');

  -- Here the slave -> master databus is defined
  debugIf_DAT_I <= s_sharedBusMaster_DAT;
  s_sharedBusMaster_DAT <=
      s_masked_sramSlave_DAT_O or
      s_masked_leds_DAT_O or
      s_masked_sevenSegments_DAT_O or
      s_masked_uartBus_DAT_O;

  -- Here the master -> slave databus is defined
  sramSlave_DAT_I <= s_sharedBusSlave_DAT;
  leds_DAT_I <= s_sharedBusSlave_DAT;
  sevenSegments_DAT_I <= s_sharedBusSlave_DAT;
  uartBus_DAT_I <= s_sharedBusSlave_DAT;
  s_sharedBusSlave_DAT <=
      s_masked_debugIf_DAT_O;

  -- Here all master inputs are mapped
  debugIf_ACK_I <= s_sharedBusMaster_ACK and s_arbiterBusEnables;
  debugIf_ERR_I <= s_sharedBusMaster_ERR and s_arbiterBusEnables;
  s_sharedBusMaster_ACK <=
      sramSlave_ACK_O or
      leds_ACK_O or
      sevenSegments_ACK_O or
      uartBus_ACK_O;
  s_sharedBusMaster_ERR <=
      s_arbiterErrorOut or
      sramSlave_ERR_O or
      leds_ERR_O or
      sevenSegments_ERR_O or
      uartBus_ERR_O;

  -- Here all slave inputs are mapped
  sramSlave_ADDR_I <= s_sharedBusSlave_ADDR;
  sramSlave_CYC_I <= s_sharedBusSlave_CYC;
  sramSlave_LOCK_I <= s_sharedBusSlave_LOCK;
  sramSlave_SEL_I <= s_sharedBusSlave_SEL;
  sramSlave_STB_I <= s_sharedBusSlave_STB;
  sramSlave_WE_I <= s_sharedBusSlave_WE;
  sramSlave_CTI_I <= s_sharedBusSlave_CTI;
  sramSlave_BTE_I <= s_sharedBusSlave_BTE;
  leds_ADDR_I <= s_sharedBusSlave_ADDR;
  leds_CYC_I <= s_sharedBusSlave_CYC;
  leds_LOCK_I <= s_sharedBusSlave_LOCK;
  leds_SEL_I <= s_sharedBusSlave_SEL;
  leds_STB_I <= s_sharedBusSlave_STB;
  leds_WE_I <= s_sharedBusSlave_WE;
  leds_CTI_I <= s_sharedBusSlave_CTI;
  leds_BTE_I <= s_sharedBusSlave_BTE;
  sevenSegments_ADDR_I <= s_sharedBusSlave_ADDR;
  sevenSegments_CYC_I <= s_sharedBusSlave_CYC;
  sevenSegments_LOCK_I <= s_sharedBusSlave_LOCK;
  sevenSegments_SEL_I <= s_sharedBusSlave_SEL;
  sevenSegments_STB_I <= s_sharedBusSlave_STB;
  sevenSegments_WE_I <= s_sharedBusSlave_WE;
  sevenSegments_CTI_I <= s_sharedBusSlave_CTI;
  sevenSegments_BTE_I <= s_sharedBusSlave_BTE;
  uartBus_ADDR_I <= s_sharedBusSlave_ADDR;
  uartBus_CYC_I <= s_sharedBusSlave_CYC;
  uartBus_LOCK_I <= s_sharedBusSlave_LOCK;
  uartBus_SEL_I <= s_sharedBusSlave_SEL;
  uartBus_STB_I <= s_sharedBusSlave_STB;
  uartBus_WE_I <= s_sharedBusSlave_WE;
  uartBus_CTI_I <= s_sharedBusSlave_CTI;
  uartBus_BTE_I <= s_sharedBusSlave_BTE;
  s_sharedBusSlave_ADDR <=
      s_masked_debugIf_ADDR_O;
  s_sharedBusSlave_CYC <=
      s_masked_debugIf_CYC_O;
  s_sharedBusSlave_LOCK <=
      s_masked_debugIf_LOCK_O;
  s_sharedBusSlave_SEL <=
      s_masked_debugIf_SEL_O;
  s_sharedBusSlave_STB <=
      s_masked_debugIf_STB_O;
  s_sharedBusSlave_WE <=
      s_masked_debugIf_WE_O;
  s_sharedBusSlave_CTI <=
      s_masked_debugIf_CTI_O;
  s_sharedBusSlave_BTE <=
      s_masked_debugIf_BTE_O;

  -- Here the arbiter is defined
  s_arbiterBusEnables <= '1';
  s_arbiterErrorOut <= s_arbiterIsTimeOut;
  s_arbiterIsTimeOut <= '1' when s_arbiterTimeOutReg = x"0000" else '0';
  arb_3 : process( CLK_O ) is
  begin
    if (rising_edge(CLK_O)) then
      if (debugIf_CYC_O = '0' or s_sharedBusMaster_ACK = '1') then
        s_arbiterTimeOutReg <= (others => '1');
      elsif (s_arbiterIsTimeOut = '0') then
        s_arbiterTimeOutReg <= std_logic_vector(unsigned(s_arbiterTimeOutReg) - to_unsigned(1,16));
      end if;
    end if;
  end process arb_3;
end architecture autogenerated;
