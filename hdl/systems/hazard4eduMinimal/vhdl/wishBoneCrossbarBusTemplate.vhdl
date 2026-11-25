  constant AddrBits : integer := 32;
  constant DataBits : integer := 32;
  constant priorityScheme : integer := 1;

-- Here all signals are defined that are used to connect the
-- master and slaves to the shared bus component.
-- You can copy-paste them in your toplevel file.

  signal s_debugIf_CLK_I : std_logic;
  signal s_debugIf_RST_I : std_logic;
  signal s_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_debugIf_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_debugIf_ACK_I : std_logic;
  signal s_debugIf_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_debugIf_CYC_O : std_logic;
  signal s_debugIf_ERR_I : std_logic;
  signal s_debugIf_LOCK_O : std_logic;
  signal s_debugIf_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_debugIf_STB_O : std_logic;
  signal s_debugIf_WE_O : std_logic;
  signal s_debugIf_CTI_O : std_logic_vector(2 downto 0);
  signal s_debugIf_BTE_O : std_logic_vector(1 downto 0);
  signal s_cpuData_CLK_I : std_logic;
  signal s_cpuData_RST_I : std_logic;
  signal s_cpuData_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuData_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuData_ACK_I : std_logic;
  signal s_cpuData_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_cpuData_CYC_O : std_logic;
  signal s_cpuData_ERR_I : std_logic;
  signal s_cpuData_LOCK_O : std_logic;
  signal s_cpuData_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_cpuData_STB_O : std_logic;
  signal s_cpuData_WE_O : std_logic;
  signal s_cpuData_CTI_O : std_logic_vector(2 downto 0);
  signal s_cpuData_BTE_O : std_logic_vector(1 downto 0);
  signal s_cpuInstr_CLK_I : std_logic;
  signal s_cpuInstr_RST_I : std_logic;
  signal s_cpuInstr_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuInstr_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuInstr_ACK_I : std_logic;
  signal s_cpuInstr_ADDR_O : std_logic_vector((AddrBits - 1) downto 0);
  signal s_cpuInstr_CYC_O : std_logic;
  signal s_cpuInstr_ERR_I : std_logic;
  signal s_cpuInstr_LOCK_O : std_logic;
  signal s_cpuInstr_SEL_O : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_cpuInstr_STB_O : std_logic;
  signal s_cpuInstr_WE_O : std_logic;
  signal s_cpuInstr_CTI_O : std_logic_vector(2 downto 0);
  signal s_cpuInstr_BTE_O : std_logic_vector(1 downto 0);
  signal s_sramSlave_CLK_I : std_logic;
  signal s_sramSlave_RST_I : std_logic;
  signal s_sramSlave_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_sramSlave_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_sramSlave_ACK_O : std_logic;
  signal s_sramSlave_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_sramSlave_CYC_I : std_logic;
  signal s_sramSlave_ERR_O : std_logic;
  signal s_sramSlave_LOCK_I : std_logic;
  signal s_sramSlave_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_sramSlave_STB_I : std_logic;
  signal s_sramSlave_WE_I : std_logic;
  signal s_sramSlave_CTI_I : std_logic_vector(2 downto 0);
  signal s_sramSlave_BTE_I : std_logic_vector(1 downto 0);
  signal s_uartBus_CLK_I : std_logic;
  signal s_uartBus_RST_I : std_logic;
  signal s_uartBus_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_DAT_O : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_ACK_O : std_logic;
  signal s_uartBus_ADDR_I : std_logic_vector((AddrBits - 1) downto 0);
  signal s_uartBus_CYC_I : std_logic;
  signal s_uartBus_ERR_O : std_logic;
  signal s_uartBus_LOCK_I : std_logic;
  signal s_uartBus_SEL_I : std_logic_vector(((DataBits / 8) - 1) downto 0);
  signal s_uartBus_STB_I : std_logic;
  signal s_uartBus_WE_I : std_logic;
  signal s_uartBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_uartBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_SYSCON_CLK_O : std_logic;
  signal s_SYSCON_RST_O : std_logic;

-- Here all your master and slave connections are mapped
-- Probably you have to change it slightly to adapt to your
-- masters/slaves

  busMaster_debugIf : entity work.debugIf(yourImplementation)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_debugIf_CLK_I,
    RST_I => s_debugIf_RST_I,
    DAT_I => s_debugIf_DAT_I,
    DAT_O => s_debugIf_DAT_O,
    ACK_I => s_debugIf_ACK_I,
    ADDR_O => s_debugIf_ADDR_O,
    CYC_O => s_debugIf_CYC_O,
    ERR_I => s_debugIf_ERR_I,
    LOCK_O => s_debugIf_LOCK_O,
    SEL_O => s_debugIf_SEL_O,
    STB_O => s_debugIf_STB_O,
    WE_O => s_debugIf_WE_O,
    CTI_O => s_debugIf_CTI_O,
    BTE_O => s_debugIf_BTE_O);

  busMaster_cpuData : entity work.cpuData(yourImplementation)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_cpuData_CLK_I,
    RST_I => s_cpuData_RST_I,
    DAT_I => s_cpuData_DAT_I,
    DAT_O => s_cpuData_DAT_O,
    ACK_I => s_cpuData_ACK_I,
    ADDR_O => s_cpuData_ADDR_O,
    CYC_O => s_cpuData_CYC_O,
    ERR_I => s_cpuData_ERR_I,
    LOCK_O => s_cpuData_LOCK_O,
    SEL_O => s_cpuData_SEL_O,
    STB_O => s_cpuData_STB_O,
    WE_O => s_cpuData_WE_O,
    CTI_O => s_cpuData_CTI_O,
    BTE_O => s_cpuData_BTE_O);

  busMaster_cpuInstr : entity work.cpuInstr(yourImplementation)
  generic map (
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_cpuInstr_CLK_I,
    RST_I => s_cpuInstr_RST_I,
    DAT_I => s_cpuInstr_DAT_I,
    DAT_O => s_cpuInstr_DAT_O,
    ACK_I => s_cpuInstr_ACK_I,
    ADDR_O => s_cpuInstr_ADDR_O,
    CYC_O => s_cpuInstr_CYC_O,
    ERR_I => s_cpuInstr_ERR_I,
    LOCK_O => s_cpuInstr_LOCK_O,
    SEL_O => s_cpuInstr_SEL_O,
    STB_O => s_cpuInstr_STB_O,
    WE_O => s_cpuInstr_WE_O,
    CTI_O => s_cpuInstr_CTI_O,
    BTE_O => s_cpuInstr_BTE_O);

  busSlave_sramSlave : entity work.sramSlave(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#0#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_sramSlave_CLK_I,
    RST_I => s_sramSlave_RST_I,
    DAT_I => s_sramSlave_DAT_I,
    DAT_O => s_sramSlave_DAT_O,
    ACK_O => s_sramSlave_ACK_O,
    ADDR_I => s_sramSlave_ADDR_I,
    CYC_I => s_sramSlave_CYC_I,
    ERR_O => s_sramSlave_ERR_O,
    LOCK_I => s_sramSlave_LOCK_I,
    SEL_I => s_sramSlave_SEL_I,
    STB_I => s_sramSlave_STB_I,
    WE_I => s_sramSlave_WE_I,
    CTI_I => s_sramSlave_CTI_I,
    BTE_I => s_sramSlave_BTE_I);

  busSlave_uartBus : entity work.uartBus(yourImplementation)
  generic map (
    BaseAddress => std_logic_vector(to_unsigned(16#10000#, AddrBits)),
    AddrBits => AddrBits,
    DataBits => DataBits)
  port map (
    CLK_I => s_uartBus_CLK_I,
    RST_I => s_uartBus_RST_I,
    DAT_I => s_uartBus_DAT_I,
    DAT_O => s_uartBus_DAT_O,
    ACK_O => s_uartBus_ACK_O,
    ADDR_I => s_uartBus_ADDR_I,
    CYC_I => s_uartBus_CYC_I,
    ERR_O => s_uartBus_ERR_O,
    LOCK_I => s_uartBus_LOCK_I,
    SEL_I => s_uartBus_SEL_I,
    STB_I => s_uartBus_STB_I,
    WE_I => s_uartBus_WE_I,
    CTI_I => s_uartBus_CTI_I,
    BTE_I => s_uartBus_BTE_I);

--Finally here the wishboneBus is mapped
  wishboneBus : entity work.wishBoneCrossbarBusTop(autogenerated)
  generic map (
      AddrBits => AddrBits,
      DataBits => DataBits,
      priorityScheme => priorityScheme
  ) port map (
    debugIf_CLK_I => s_debugIf_CLK_I,
    debugIf_RST_I => s_debugIf_RST_I,
    debugIf_DAT_I => s_debugIf_DAT_I,
    debugIf_DAT_O => s_debugIf_DAT_O,
    debugIf_ACK_I => s_debugIf_ACK_I,
    debugIf_ADDR_O => s_debugIf_ADDR_O,
    debugIf_CYC_O => s_debugIf_CYC_O,
    debugIf_ERR_I => s_debugIf_ERR_I,
    debugIf_LOCK_O => s_debugIf_LOCK_O,
    debugIf_SEL_O => s_debugIf_SEL_O,
    debugIf_STB_O => s_debugIf_STB_O,
    debugIf_WE_O => s_debugIf_WE_O,
    debugIf_CTI_O => s_debugIf_CTI_O,
    debugIf_BTE_O => s_debugIf_BTE_O,
    cpuData_CLK_I => s_cpuData_CLK_I,
    cpuData_RST_I => s_cpuData_RST_I,
    cpuData_DAT_I => s_cpuData_DAT_I,
    cpuData_DAT_O => s_cpuData_DAT_O,
    cpuData_ACK_I => s_cpuData_ACK_I,
    cpuData_ADDR_O => s_cpuData_ADDR_O,
    cpuData_CYC_O => s_cpuData_CYC_O,
    cpuData_ERR_I => s_cpuData_ERR_I,
    cpuData_LOCK_O => s_cpuData_LOCK_O,
    cpuData_SEL_O => s_cpuData_SEL_O,
    cpuData_STB_O => s_cpuData_STB_O,
    cpuData_WE_O => s_cpuData_WE_O,
    cpuData_CTI_O => s_cpuData_CTI_O,
    cpuData_BTE_O => s_cpuData_BTE_O,
    cpuInstr_CLK_I => s_cpuInstr_CLK_I,
    cpuInstr_RST_I => s_cpuInstr_RST_I,
    cpuInstr_DAT_I => s_cpuInstr_DAT_I,
    cpuInstr_DAT_O => s_cpuInstr_DAT_O,
    cpuInstr_ACK_I => s_cpuInstr_ACK_I,
    cpuInstr_ADDR_O => s_cpuInstr_ADDR_O,
    cpuInstr_CYC_O => s_cpuInstr_CYC_O,
    cpuInstr_ERR_I => s_cpuInstr_ERR_I,
    cpuInstr_LOCK_O => s_cpuInstr_LOCK_O,
    cpuInstr_SEL_O => s_cpuInstr_SEL_O,
    cpuInstr_STB_O => s_cpuInstr_STB_O,
    cpuInstr_WE_O => s_cpuInstr_WE_O,
    cpuInstr_CTI_O => s_cpuInstr_CTI_O,
    cpuInstr_BTE_O => s_cpuInstr_BTE_O,
    sramSlave_CLK_I => s_sramSlave_CLK_I,
    sramSlave_RST_I => s_sramSlave_RST_I,
    sramSlave_DAT_I => s_sramSlave_DAT_I,
    sramSlave_DAT_O => s_sramSlave_DAT_O,
    sramSlave_ACK_O => s_sramSlave_ACK_O,
    sramSlave_ADDR_I => s_sramSlave_ADDR_I,
    sramSlave_CYC_I => s_sramSlave_CYC_I,
    sramSlave_ERR_O => s_sramSlave_ERR_O,
    sramSlave_LOCK_I => s_sramSlave_LOCK_I,
    sramSlave_SEL_I => s_sramSlave_SEL_I,
    sramSlave_STB_I => s_sramSlave_STB_I,
    sramSlave_WE_I => s_sramSlave_WE_I,
    sramSlave_CTI_I => s_sramSlave_CTI_I,
    sramSlave_BTE_I => s_sramSlave_BTE_I,
    uartBus_CLK_I => s_uartBus_CLK_I,
    uartBus_RST_I => s_uartBus_RST_I,
    uartBus_DAT_I => s_uartBus_DAT_I,
    uartBus_DAT_O => s_uartBus_DAT_O,
    uartBus_ACK_O => s_uartBus_ACK_O,
    uartBus_ADDR_I => s_uartBus_ADDR_I,
    uartBus_CYC_I => s_uartBus_CYC_I,
    uartBus_ERR_O => s_uartBus_ERR_O,
    uartBus_LOCK_I => s_uartBus_LOCK_I,
    uartBus_SEL_I => s_uartBus_SEL_I,
    uartBus_STB_I => s_uartBus_STB_I,
    uartBus_WE_I => s_uartBus_WE_I,
    uartBus_CTI_I => s_uartBus_CTI_I,
    uartBus_BTE_I => s_uartBus_BTE_I,
    CLK_O => s_SYSCON_CLK_O,
    RST_O => s_SYSCON_RST_O);

