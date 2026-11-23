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

    -- Here the signals for the master "cpuData" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    cpuData_CLK_I : out std_logic;
    cpuData_RST_I : out std_logic;
    cpuData_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    cpuData_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    cpuData_ACK_I : out std_logic;
    cpuData_ADDR_O : in  std_logic_vector((AddrBits - 1) downto 0);
    cpuData_CYC_O : in  std_logic;
    cpuData_ERR_I : out std_logic;
    cpuData_LOCK_O : in  std_logic;
    cpuData_SEL_O : in  std_logic_vector(((DataBits / 8) - 1) downto 0);
    cpuData_STB_O : in  std_logic;
    cpuData_WE_O : in  std_logic;
    cpuData_CTI_O : in  std_logic_vector(2 downto 0);
    cpuData_BTE_O : in  std_logic_vector(1 downto 0);

    -- Here the signals for the master "cpuInstr" are defined
    -- Note that although the signals are noted with _O/_I their direction is oposite defined
    -- as they connect directly with the same signals on the master.
    cpuInstr_CLK_I : out std_logic;
    cpuInstr_RST_I : out std_logic;
    cpuInstr_DAT_I : out std_logic_vector((DataBits - 1) downto 0);
    cpuInstr_DAT_O : in  std_logic_vector((DataBits - 1) downto 0);
    cpuInstr_ACK_I : out std_logic;
    cpuInstr_ADDR_O : in  std_logic_vector((AddrBits - 1) downto 0);
    cpuInstr_CYC_O : in  std_logic;
    cpuInstr_ERR_I : out std_logic;
    cpuInstr_LOCK_O : in  std_logic;
    cpuInstr_SEL_O : in  std_logic_vector(((DataBits / 8) - 1) downto 0);
    cpuInstr_STB_O : in  std_logic;
    cpuInstr_WE_O : in  std_logic;
    cpuInstr_CTI_O : in  std_logic_vector(2 downto 0);
    cpuInstr_BTE_O : in  std_logic_vector(1 downto 0);

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
  signal s_masked_cpuData_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_cpuData_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_masked_cpuData_CYC_O : std_logic;
  signal s_masked_cpuData_LOCK_O : std_logic;
  signal s_masked_cpuData_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_masked_cpuData_STB_O : std_logic;
  signal s_masked_cpuData_WE_O : std_logic;
  signal s_masked_cpuData_CTI_O : std_logic_vector(2 downto 0);
  signal s_masked_cpuData_BTE_O : std_logic_vector(1 downto 0);
  signal s_masked_cpuInstr_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_masked_cpuInstr_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_masked_cpuInstr_CYC_O : std_logic;
  signal s_masked_cpuInstr_LOCK_O : std_logic;
  signal s_masked_cpuInstr_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_masked_cpuInstr_STB_O : std_logic;
  signal s_masked_cpuInstr_WE_O : std_logic;
  signal s_masked_cpuInstr_CTI_O : std_logic_vector(2 downto 0);
  signal s_masked_cpuInstr_BTE_O : std_logic_vector(1 downto 0);
  signal s_masked_sramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
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
  signal s_arbiterMasterCycs : std_logic_vector(2 downto 0);
  signal s_arbiterMasterLocks : std_logic_vector(2 downto 0);
  signal s_arbiterBusEnables : std_logic_vector(2 downto 0);
  signal s_arbiterErrorOut : std_logic;
  signal s_arbiterMaskReg : std_logic_vector(2 downto 0);
  signal s_arbiterEnablesReg : std_logic_vector(2 downto 0);
  signal s_arbiterTimeOutReg : std_logic_vector(15 downto 0);
  signal s_arbiterBusIsUsedReg : std_logic;
  signal s_arbiterBeforeMeCarries : std_logic_vector(2 downto 0);
  signal s_arbiterAferMeCarries : std_logic_vector(2 downto 0);
  signal s_arbiterBeforeMeMask : std_logic_vector(2 downto 0);
  signal s_arbiterAfterMeMask : std_logic_vector(2 downto 0);
  signal s_arbiterNewMask : std_logic_vector(2 downto 0);
  signal s_arbiterServeRequest : std_logic;
  signal s_arbiterIsTimeOut : std_logic;
  signal s_arbiterIsBusRelease : std_logic;

begin

  -- Here we connect all clocks and resets to the syscon
  debugIf_CLK_I <= CLK_O;
  debugIf_RST_I <= RST_O;
  cpuData_CLK_I <= CLK_O;
  cpuData_RST_I <= RST_O;
  cpuInstr_CLK_I <= CLK_O;
  cpuInstr_RST_I <= RST_O;
  sramSlave_CLK_I <= CLK_O;
  sramSlave_RST_I <= RST_O;
  uartBus_CLK_I <= CLK_O;
  uartBus_RST_I <= RST_O;

  -- Here the arbiter signals are mapped
  s_arbiterMasterLocks(0) <= debugIf_LOCK_O;
  s_arbiterMasterLocks(1) <= cpuData_LOCK_O;
  s_arbiterMasterLocks(2) <= cpuInstr_LOCK_O;
  s_arbiterMasterCycs(0) <= debugIf_CYC_O;
  s_arbiterMasterCycs(1) <= cpuData_CYC_O;
  s_arbiterMasterCycs(2) <= cpuInstr_CYC_O;

  -- Here the masked slave signals are defined
  s_masked_sramSlave_DAT_O <= sramSlave_DAT_O when sramSlave_ACK_O = '1' else (others => '0');
  s_masked_uartBus_DAT_O <= uartBus_DAT_O when uartBus_ACK_O = '1' else (others => '0');

  -- Here the masked master signals are defined
  s_masked_debugIf_DAT_O <= debugIf_DAT_O when s_arbiterBusEnables(0) = '1' else (others => '0');
  s_masked_debugIf_ADDR_O <= debugIf_ADDR_O when s_arbiterBusEnables(0) = '1' else (others => '0');
  s_masked_debugIf_CYC_O <= debugIf_CYC_O when s_arbiterBusEnables(0) = '1' else '0';
  s_masked_debugIf_LOCK_O <= debugIf_LOCK_O when s_arbiterBusEnables(0) = '1' else '0';
  s_masked_debugIf_SEL_O <= debugIf_SEL_O when s_arbiterBusEnables(0) = '1' else (others => '0');
  s_masked_debugIf_STB_O <= debugIf_STB_O when s_arbiterBusEnables(0) = '1' else '0';
  s_masked_debugIf_WE_O <= debugIf_WE_O when s_arbiterBusEnables(0) = '1' else '0';
  s_masked_debugIf_CTI_O <= debugIf_CTI_O when s_arbiterBusEnables(0) = '1' else (others => '0');
  s_masked_debugIf_BTE_O <= debugIf_BTE_O when s_arbiterBusEnables(0) = '1' else (others => '0');
  s_masked_cpuData_DAT_O <= cpuData_DAT_O when s_arbiterBusEnables(1) = '1' else (others => '0');
  s_masked_cpuData_ADDR_O <= cpuData_ADDR_O when s_arbiterBusEnables(1) = '1' else (others => '0');
  s_masked_cpuData_CYC_O <= cpuData_CYC_O when s_arbiterBusEnables(1) = '1' else '0';
  s_masked_cpuData_LOCK_O <= cpuData_LOCK_O when s_arbiterBusEnables(1) = '1' else '0';
  s_masked_cpuData_SEL_O <= cpuData_SEL_O when s_arbiterBusEnables(1) = '1' else (others => '0');
  s_masked_cpuData_STB_O <= cpuData_STB_O when s_arbiterBusEnables(1) = '1' else '0';
  s_masked_cpuData_WE_O <= cpuData_WE_O when s_arbiterBusEnables(1) = '1' else '0';
  s_masked_cpuData_CTI_O <= cpuData_CTI_O when s_arbiterBusEnables(1) = '1' else (others => '0');
  s_masked_cpuData_BTE_O <= cpuData_BTE_O when s_arbiterBusEnables(1) = '1' else (others => '0');
  s_masked_cpuInstr_DAT_O <= cpuInstr_DAT_O when s_arbiterBusEnables(2) = '1' else (others => '0');
  s_masked_cpuInstr_ADDR_O <= cpuInstr_ADDR_O when s_arbiterBusEnables(2) = '1' else (others => '0');
  s_masked_cpuInstr_CYC_O <= cpuInstr_CYC_O when s_arbiterBusEnables(2) = '1' else '0';
  s_masked_cpuInstr_LOCK_O <= cpuInstr_LOCK_O when s_arbiterBusEnables(2) = '1' else '0';
  s_masked_cpuInstr_SEL_O <= cpuInstr_SEL_O when s_arbiterBusEnables(2) = '1' else (others => '0');
  s_masked_cpuInstr_STB_O <= cpuInstr_STB_O when s_arbiterBusEnables(2) = '1' else '0';
  s_masked_cpuInstr_WE_O <= cpuInstr_WE_O when s_arbiterBusEnables(2) = '1' else '0';
  s_masked_cpuInstr_CTI_O <= cpuInstr_CTI_O when s_arbiterBusEnables(2) = '1' else (others => '0');
  s_masked_cpuInstr_BTE_O <= cpuInstr_BTE_O when s_arbiterBusEnables(2) = '1' else (others => '0');

  -- Here the slave -> master databus is defined
  debugIf_DAT_I <= s_sharedBusMaster_DAT;
  cpuData_DAT_I <= s_sharedBusMaster_DAT;
  cpuInstr_DAT_I <= s_sharedBusMaster_DAT;
  s_sharedBusMaster_DAT <=
      s_masked_sramSlave_DAT_O or
      s_masked_uartBus_DAT_O;

  -- Here the master -> slave databus is defined
  sramSlave_DAT_I <= s_sharedBusSlave_DAT;
  uartBus_DAT_I <= s_sharedBusSlave_DAT;
  s_sharedBusSlave_DAT <=
      s_masked_debugIf_DAT_O or
      s_masked_cpuData_DAT_O or
      s_masked_cpuInstr_DAT_O;

  -- Here all master inputs are mapped
  debugIf_ACK_I <= s_sharedBusMaster_ACK and s_arbiterBusEnables(0);
  debugIf_ERR_I <= s_sharedBusMaster_ERR and s_arbiterBusEnables(0);
  cpuData_ACK_I <= s_sharedBusMaster_ACK and s_arbiterBusEnables(1);
  cpuData_ERR_I <= s_sharedBusMaster_ERR and s_arbiterBusEnables(1);
  cpuInstr_ACK_I <= s_sharedBusMaster_ACK and s_arbiterBusEnables(2);
  cpuInstr_ERR_I <= s_sharedBusMaster_ERR and s_arbiterBusEnables(2);
  s_sharedBusMaster_ACK <=
      sramSlave_ACK_O or
      uartBus_ACK_O;
  s_sharedBusMaster_ERR <=
      s_arbiterErrorOut or
      sramSlave_ERR_O or
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
  uartBus_ADDR_I <= s_sharedBusSlave_ADDR;
  uartBus_CYC_I <= s_sharedBusSlave_CYC;
  uartBus_LOCK_I <= s_sharedBusSlave_LOCK;
  uartBus_SEL_I <= s_sharedBusSlave_SEL;
  uartBus_STB_I <= s_sharedBusSlave_STB;
  uartBus_WE_I <= s_sharedBusSlave_WE;
  uartBus_CTI_I <= s_sharedBusSlave_CTI;
  uartBus_BTE_I <= s_sharedBusSlave_BTE;
  s_sharedBusSlave_ADDR <=
      s_masked_debugIf_ADDR_O or
      s_masked_cpuData_ADDR_O or
      s_masked_cpuInstr_ADDR_O;
  s_sharedBusSlave_CYC <=
      s_masked_debugIf_CYC_O or
      s_masked_cpuData_CYC_O or
      s_masked_cpuInstr_CYC_O;
  s_sharedBusSlave_LOCK <=
      s_masked_debugIf_LOCK_O or
      s_masked_cpuData_LOCK_O or
      s_masked_cpuInstr_LOCK_O;
  s_sharedBusSlave_SEL <=
      s_masked_debugIf_SEL_O or
      s_masked_cpuData_SEL_O or
      s_masked_cpuInstr_SEL_O;
  s_sharedBusSlave_STB <=
      s_masked_debugIf_STB_O or
      s_masked_cpuData_STB_O or
      s_masked_cpuInstr_STB_O;
  s_sharedBusSlave_WE <=
      s_masked_debugIf_WE_O or
      s_masked_cpuData_WE_O or
      s_masked_cpuInstr_WE_O;
  s_sharedBusSlave_CTI <=
      s_masked_debugIf_CTI_O or
      s_masked_cpuData_CTI_O or
      s_masked_cpuInstr_CTI_O;
  s_sharedBusSlave_BTE <=
      s_masked_debugIf_BTE_O or
      s_masked_cpuData_BTE_O or
      s_masked_cpuInstr_BTE_O;

  -- Here the arbiter is defined
  s_arbiterBusEnables <= s_arbiterEnablesReg;
  s_arbiterErrorOut <= s_arbiterBusIsUsedReg and s_arbiterIsTimeOut;
  s_arbiterIsTimeOut <= '1' when s_arbiterTimeOutReg = x"0000" else '0';
  s_arbiterBeforeMeCarries(0) <= not s_arbiterMasterCycs(0);
  s_arbiterAferMeCarries(0) <= '0';
  s_arbiterBeforeMeMask(0) <= s_arbiterMasterCycs(0);
  s_arbiterAfterMeMask(0) <= '0';
  s_arbiterIsBusRelease <= s_arbiterBusIsUsedReg when ((s_arbiterMasterCycs and s_arbiterEnablesReg) = "000") and ((s_arbiterMasterLocks and s_arbiterEnablesReg) = "000") else '0';
  s_arbiterNewMask <= s_arbiterBeforeMeMask when priorityScheme = 1 or s_arbiterAfterMeMask = "000" else s_arbiterAfterMeMask;
  s_arbiterServeRequest <= '1' when s_arbiterMasterCycs /= "000" and s_arbiterBusIsUsedReg = '0' else '0';

  genMasks : for i in 1 to 2 generate
    s_arbiterBeforeMeCarries(i) <= s_arbiterBeforeMeCarries(i-1) and not(s_arbiterMasterCycs(i));
    s_arbiterBeforeMeMask(i) <= s_arbiterMasterCycs(i) and s_arbiterBeforeMeCarries(i-1);
    s_arbiterAferMeCarries(i) <= s_arbiterMaskReg(i) or (s_arbiterAferMeCarries(i-1) and not(s_arbiterMasterCycs(i)));
    s_arbiterAfterMeMask(i) <= s_arbiterAferMeCarries(i-1) and s_arbiterMasterCycs(i);
  end generate genMasks;

  arb_1 : process( CLK_O ) is
  begin
    if (rising_edge(CLK_O)) then
      if (RST_O = '1' or s_arbiterIsBusRelease = '1') then
        s_arbiterBusIsUsedReg <= '0';
        s_arbiterEnablesReg <= (others => '0');
      elsif (s_arbiterServeRequest = '1') then
        s_arbiterBusIsUsedReg <= '1';
        s_arbiterEnablesReg <= s_arbiterNewMask;
      end if;
    end if;
  end process arb_1;

  arb_2 : process( CLK_O ) is
  begin
    if (rising_edge(CLK_O)) then
      if (s_arbiterServeRequest = '1') then
        s_arbiterMaskReg <= s_arbiterNewMask;
      elsif (s_arbiterBusIsUsedReg = '0') then
        s_arbiterMaskReg <= (others => '0');
      end if;
    end if;
  end process arb_2;

  arb_3 : process( CLK_O ) is
  begin
    if (rising_edge(CLK_O)) then
      if (s_arbiterBusIsUsedReg = '0' or s_sharedBusMaster_ACK = '1') then
        s_arbiterTimeOutReg <= (others => '1');
      elsif (s_arbiterIsTimeOut = '0') then
        s_arbiterTimeOutReg <= std_logic_vector(unsigned(s_arbiterTimeOutReg) - to_unsigned(1,16));
      end if;
    end if;
  end process arb_3;

end architecture autogenerated;
