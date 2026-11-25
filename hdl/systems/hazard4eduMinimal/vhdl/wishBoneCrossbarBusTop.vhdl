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
end entity wishBoneCrossbarBusTop;

architecture autogenerated of wishBoneCrossbarBusTop is

  signal s_sramSlave_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_debugIf_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_debugIf_ACK_I : std_logic;
  signal s_sramSlave_debugIf_ACK_I : std_logic;
  signal s_uartBus_debugIf_ACK_I : std_logic;
  signal s_sramSlave_debugIf_ERR_I : std_logic;
  signal s_uartBus_debugIf_ERR_I : std_logic;
  signal s_debugIf_arbiterTimeOut : std_logic;
  signal s_debugIf_arbiterTimeOutCounter : unsigned(15 downto 0);
  signal s_sramSlave_cpuData_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_cpuData_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuData_ACK_I : std_logic;
  signal s_sramSlave_cpuData_ACK_I : std_logic;
  signal s_uartBus_cpuData_ACK_I : std_logic;
  signal s_sramSlave_cpuData_ERR_I : std_logic;
  signal s_uartBus_cpuData_ERR_I : std_logic;
  signal s_cpuData_arbiterTimeOut : std_logic;
  signal s_cpuData_arbiterTimeOutCounter : unsigned(15 downto 0);
  signal s_sramSlave_cpuInstr_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_uartBus_cpuInstr_DAT_I : std_logic_vector((DataBits - 1) downto 0);
  signal s_cpuInstr_ACK_I : std_logic;
  signal s_sramSlave_cpuInstr_ACK_I : std_logic;
  signal s_uartBus_cpuInstr_ACK_I : std_logic;
  signal s_sramSlave_cpuInstr_ERR_I : std_logic;
  signal s_uartBus_cpuInstr_ERR_I : std_logic;
  signal s_cpuInstr_arbiterTimeOut : std_logic;
  signal s_cpuInstr_arbiterTimeOutCounter : unsigned(15 downto 0);

begin

  -- Here all master clock connections are defined
  debugIf_CLK_I <= CLK_O;
  debugIf_RST_I <= RST_O;
  cpuData_CLK_I <= CLK_O;
  cpuData_RST_I <= RST_O;
  cpuInstr_CLK_I <= CLK_O;
  cpuInstr_RST_I <= RST_O;

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
    cpuData_DAT_I => s_sramSlave_cpuData_DAT_I,
    cpuData_DAT_O => cpuData_DAT_O,
    cpuData_ACK_I => s_sramSlave_cpuData_ACK_I,
    cpuData_ADDR_O => cpuData_ADDR_O,
    cpuData_CYC_O => cpuData_CYC_O,
    cpuData_ERR_I => s_sramSlave_cpuData_ERR_I,
    cpuData_LOCK_O => cpuData_LOCK_O,
    cpuData_SEL_O => cpuData_SEL_O,
    cpuData_STB_O => cpuData_STB_O,
    cpuData_WE_O => cpuData_WE_O,
    cpuData_CTI_O => cpuData_CTI_O,
    cpuData_BTE_O => cpuData_BTE_O,
    cpuInstr_DAT_I => s_sramSlave_cpuInstr_DAT_I,
    cpuInstr_DAT_O => cpuInstr_DAT_O,
    cpuInstr_ACK_I => s_sramSlave_cpuInstr_ACK_I,
    cpuInstr_ADDR_O => cpuInstr_ADDR_O,
    cpuInstr_CYC_O => cpuInstr_CYC_O,
    cpuInstr_ERR_I => s_sramSlave_cpuInstr_ERR_I,
    cpuInstr_LOCK_O => cpuInstr_LOCK_O,
    cpuInstr_SEL_O => cpuInstr_SEL_O,
    cpuInstr_STB_O => cpuInstr_STB_O,
    cpuInstr_WE_O => cpuInstr_WE_O,
    cpuInstr_CTI_O => cpuInstr_CTI_O,
    cpuInstr_BTE_O => cpuInstr_BTE_O,
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
    EndAddress => std_logic_vector(to_unsigned(16#10007#, AddrBits)),
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
    cpuData_DAT_I => s_uartBus_cpuData_DAT_I,
    cpuData_DAT_O => cpuData_DAT_O,
    cpuData_ACK_I => s_uartBus_cpuData_ACK_I,
    cpuData_ADDR_O => cpuData_ADDR_O,
    cpuData_CYC_O => cpuData_CYC_O,
    cpuData_ERR_I => s_uartBus_cpuData_ERR_I,
    cpuData_LOCK_O => cpuData_LOCK_O,
    cpuData_SEL_O => cpuData_SEL_O,
    cpuData_STB_O => cpuData_STB_O,
    cpuData_WE_O => cpuData_WE_O,
    cpuData_CTI_O => cpuData_CTI_O,
    cpuData_BTE_O => cpuData_BTE_O,
    cpuInstr_DAT_I => s_uartBus_cpuInstr_DAT_I,
    cpuInstr_DAT_O => cpuInstr_DAT_O,
    cpuInstr_ACK_I => s_uartBus_cpuInstr_ACK_I,
    cpuInstr_ADDR_O => cpuInstr_ADDR_O,
    cpuInstr_CYC_O => cpuInstr_CYC_O,
    cpuInstr_ERR_I => s_uartBus_cpuInstr_ERR_I,
    cpuInstr_LOCK_O => cpuInstr_LOCK_O,
    cpuInstr_SEL_O => cpuInstr_SEL_O,
    cpuInstr_STB_O => cpuInstr_STB_O,
    cpuInstr_WE_O => cpuInstr_WE_O,
    cpuInstr_CTI_O => cpuInstr_CTI_O,
    cpuInstr_BTE_O => cpuInstr_BTE_O,
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
    s_uartBus_debugIf_DAT_I;

  debugIf_ACK_I <= s_debugIf_ACK_I;
  s_debugIf_ACK_I <=
    s_sramSlave_debugIf_ACK_I or
    s_uartBus_debugIf_ACK_I;

  debugIf_ERR_I <=
    s_sramSlave_debugIf_ERR_I or
    s_uartBus_debugIf_ERR_I or
    s_debugIf_arbiterTimeOut;

  cpuData_DAT_I <=
    s_sramSlave_cpuData_DAT_I or
    s_uartBus_cpuData_DAT_I;

  cpuData_ACK_I <= s_cpuData_ACK_I;
  s_cpuData_ACK_I <=
    s_sramSlave_cpuData_ACK_I or
    s_uartBus_cpuData_ACK_I;

  cpuData_ERR_I <=
    s_sramSlave_cpuData_ERR_I or
    s_uartBus_cpuData_ERR_I or
    s_cpuData_arbiterTimeOut;

  cpuInstr_DAT_I <=
    s_sramSlave_cpuInstr_DAT_I or
    s_uartBus_cpuInstr_DAT_I;

  cpuInstr_ACK_I <= s_cpuInstr_ACK_I;
  s_cpuInstr_ACK_I <=
    s_sramSlave_cpuInstr_ACK_I or
    s_uartBus_cpuInstr_ACK_I;

  cpuInstr_ERR_I <=
    s_sramSlave_cpuInstr_ERR_I or
    s_uartBus_cpuInstr_ERR_I or
    s_cpuInstr_arbiterTimeOut;

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

  s_cpuData_arbiterTimeOut <= '1' when s_cpuData_arbiterTimeOutCounter = to_unsigned(0, 16) else '0';

  proc_1 : process( CLK_O ) is
    begin
      if (rising_edge(CLK_O)) then
        if (RST_O = '1' or
            cpuData_CYC_O = '0' or
            s_cpuData_ACK_I = '1') then
          s_cpuData_arbiterTimeOutCounter <= (others => '1');
        elsif (s_cpuData_arbiterTimeOut = '0') then
          s_cpuData_arbiterTimeOutCounter <= s_cpuData_arbiterTimeOutCounter - to_unsigned(1, 16);
        end if;
      end if;
    end process proc_1;

  s_cpuInstr_arbiterTimeOut <= '1' when s_cpuInstr_arbiterTimeOutCounter = to_unsigned(0, 16) else '0';

  proc_2 : process( CLK_O ) is
    begin
      if (rising_edge(CLK_O)) then
        if (RST_O = '1' or
            cpuInstr_CYC_O = '0' or
            s_cpuInstr_ACK_I = '1') then
          s_cpuInstr_arbiterTimeOutCounter <= (others => '1');
        elsif (s_cpuInstr_arbiterTimeOut = '0') then
          s_cpuInstr_arbiterTimeOutCounter <= s_cpuInstr_arbiterTimeOutCounter - to_unsigned(1, 16);
        end if;
      end if;
    end process proc_2;

end architecture autogenerated;
