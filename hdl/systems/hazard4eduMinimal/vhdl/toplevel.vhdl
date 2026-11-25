library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Minimal Hazard3 system for the GECKO5Education (ECP5 LFE5U-85):
-- Hazard3 (Wishbone ports) + JTAG debug + 64 KiB SRAM + 16550 UART on a shared Wishbone bus.
-- VHDL counterpart of verilog/toplevel.v (same configuration and connections).
--
-- Memory map (see wishBone.xml):
--   0x0000_0000 - 0x0000_ffff  sramSlave, 64 KiB block RAM (reset vector and mtvec at 0x0)
--   0x0001_0000 - 0x0001_0007  uartBus, 16550 compatible, byte registers
--
-- Bus masters in arbiter index order (priorityScheme = 0: round robin): debugIf (debug module system bus access),
-- cpuData (load/store port), cpuInstr (instruction fetch port).
--
-- The RAM is not initialised: software is loaded through the JTAG debug port
-- (OpenOCD, see openocd/gecko5-hazard3.cfg).
entity hazard4eduMinimal is
  generic ( USE_CROSSBAR : boolean := false );
  port ( clock   : in  std_logic;  -- 50 MHz
         n_reset : in  std_logic;
         RxD     : in  std_logic;
         TxD     : out std_logic );
end entity hazard4eduMinimal;

architecture rtl of hazard4eduMinimal is

  constant AddrBits       : integer := 32;
  constant DataBits       : integer := 32;
  constant priorityScheme : integer := 0;

  signal s_debugIf_CLK_I : std_logic;
  signal s_debugIf_RST_I : std_logic;
  signal s_debugIf_DAT_I : std_logic_vector(DataBits - 1 downto 0);
  signal s_debugIf_DAT_O : std_logic_vector(DataBits - 1 downto 0);
  signal s_debugIf_ACK_I : std_logic;
  signal s_debugIf_ADDR_O : std_logic_vector(AddrBits - 1 downto 0);
  signal s_debugIf_CYC_O : std_logic;
  signal s_debugIf_ERR_I : std_logic;
  signal s_debugIf_LOCK_O : std_logic;
  signal s_debugIf_SEL_O : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_debugIf_STB_O : std_logic;
  signal s_debugIf_WE_O : std_logic;
  signal s_debugIf_CTI_O : std_logic_vector(2 downto 0);
  signal s_debugIf_BTE_O : std_logic_vector(1 downto 0);
  signal s_cpuData_CLK_I : std_logic;
  signal s_cpuData_RST_I : std_logic;
  signal s_cpuData_DAT_I : std_logic_vector(DataBits - 1 downto 0);
  signal s_cpuData_DAT_O : std_logic_vector(DataBits - 1 downto 0);
  signal s_cpuData_ACK_I : std_logic;
  signal s_cpuData_ADDR_O : std_logic_vector(AddrBits - 1 downto 0);
  signal s_cpuData_CYC_O : std_logic;
  signal s_cpuData_ERR_I : std_logic;
  signal s_cpuData_LOCK_O : std_logic;
  signal s_cpuData_SEL_O : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_cpuData_STB_O : std_logic;
  signal s_cpuData_WE_O : std_logic;
  signal s_cpuData_CTI_O : std_logic_vector(2 downto 0);
  signal s_cpuData_BTE_O : std_logic_vector(1 downto 0);
  signal s_cpuInstr_CLK_I : std_logic;
  signal s_cpuInstr_RST_I : std_logic;
  signal s_cpuInstr_DAT_I : std_logic_vector(DataBits - 1 downto 0);
  signal s_cpuInstr_DAT_O : std_logic_vector(DataBits - 1 downto 0);
  signal s_cpuInstr_ACK_I : std_logic;
  signal s_cpuInstr_ADDR_O : std_logic_vector(AddrBits - 1 downto 0);
  signal s_cpuInstr_CYC_O : std_logic;
  signal s_cpuInstr_ERR_I : std_logic;
  signal s_cpuInstr_LOCK_O : std_logic;
  signal s_cpuInstr_SEL_O : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_cpuInstr_STB_O : std_logic;
  signal s_cpuInstr_WE_O : std_logic;
  signal s_cpuInstr_CTI_O : std_logic_vector(2 downto 0);
  signal s_cpuInstr_BTE_O : std_logic_vector(1 downto 0);
  signal s_sramSlave_CLK_I : std_logic;
  signal s_sramSlave_RST_I : std_logic;
  signal s_sramSlave_DAT_I : std_logic_vector(DataBits - 1 downto 0);
  signal s_sramSlave_DAT_O : std_logic_vector(DataBits - 1 downto 0);
  signal s_sramSlave_ACK_O : std_logic;
  signal s_sramSlave_ADDR_I : std_logic_vector(AddrBits - 1 downto 0);
  signal s_sramSlave_CYC_I : std_logic;
  signal s_sramSlave_ERR_O : std_logic;
  signal s_sramSlave_LOCK_I : std_logic;
  signal s_sramSlave_SEL_I : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_sramSlave_STB_I : std_logic;
  signal s_sramSlave_WE_I : std_logic;
  signal s_sramSlave_CTI_I : std_logic_vector(2 downto 0);
  signal s_sramSlave_BTE_I : std_logic_vector(1 downto 0);
  signal s_uartBus_CLK_I : std_logic;
  signal s_uartBus_RST_I : std_logic;
  signal s_uartBus_DAT_I : std_logic_vector(DataBits - 1 downto 0);
  signal s_uartBus_DAT_O : std_logic_vector(DataBits - 1 downto 0);
  signal s_uartBus_ACK_O : std_logic;
  signal s_uartBus_ADDR_I : std_logic_vector(AddrBits - 1 downto 0);
  signal s_uartBus_CYC_I : std_logic;
  signal s_uartBus_ERR_O : std_logic;
  signal s_uartBus_LOCK_I : std_logic;
  signal s_uartBus_SEL_I : std_logic_vector((DataBits / 8) - 1 downto 0);
  signal s_uartBus_STB_I : std_logic;
  signal s_uartBus_WE_I : std_logic;
  signal s_uartBus_CTI_I : std_logic_vector(2 downto 0);
  signal s_uartBus_BTE_I : std_logic_vector(1 downto 0);
  signal s_SYSCON_CLK_O : std_logic;
  signal s_SYSCON_RST_O : std_logic;

  signal s_resetReg    : unsigned(3 downto 0);
  signal s_cpuResetReg : std_logic;
  signal s_cpuResetDone : std_logic_vector(0 downto 0);

  -- Debug module <-> hart (N_HARTS = 1, hence the one-bit vectors)
  signal s_sys_reset_req               : std_logic;
  signal s_hart_reset_req              : std_logic_vector(0 downto 0);
  signal s_hart_req_halt               : std_logic_vector(0 downto 0);
  signal s_hart_req_halt_on_reset      : std_logic_vector(0 downto 0);
  signal s_hart_req_resume             : std_logic_vector(0 downto 0);
  signal s_hart_halted                 : std_logic_vector(0 downto 0);
  signal s_hart_running                : std_logic_vector(0 downto 0);
  signal s_hart_data0_rdata            : std_logic_vector(31 downto 0);
  signal s_hart_data0_wdata            : std_logic_vector(31 downto 0);
  signal s_hart_data0_wen              : std_logic_vector(0 downto 0);
  signal s_hart_instr_data             : std_logic_vector(31 downto 0);
  signal s_hart_instr_data_vld         : std_logic_vector(0 downto 0);
  signal s_hart_instr_data_rdy         : std_logic_vector(0 downto 0);
  signal s_hart_instr_caught_exception : std_logic_vector(0 downto 0);
  signal s_hart_instr_caught_ebreak    : std_logic_vector(0 downto 0);
  signal s_pwrup_req                   : std_logic;
  signal s_unblock_out                 : std_logic;

begin

  -- SYSCON: clock and a short power-on / button reset
  s_SYSCON_CLK_O <= clock;

  resetCounter : process (clock, n_reset) is
  begin
    if n_reset = '0' then
      s_resetReg <= "1111";
    elsif rising_edge(clock) then
      if s_resetReg(3) = '1' then
        s_resetReg <= s_resetReg - 1;
      end if;
    end if;
  end process resetCounter;

  s_SYSCON_RST_O <= s_resetReg(3);

  -- CPU reset: bus reset, or a system/hart reset requested by the debugger
  cpuReset : process (clock) is
  begin
    if rising_edge(clock) then
      s_cpuResetReg <= s_SYSCON_RST_O or s_sys_reset_req or s_hart_reset_req(0);
    end if;
  end process cpuReset;

  s_cpuResetDone(0) <= not s_cpuResetReg;

  busMaster_debugIf : entity work.debugTop(rtl)
    generic map (
      N_HARTS         => 1,
      NEXT_DM_ADDR    => x"0000_0000",
      DTMCS_IDLE_HINT => "100",
      W_PADDR         => 9 )
    port map (
      sys_reset_req               => s_sys_reset_req,
      sys_reset_done              => s_cpuResetDone(0),
      hart_reset_req              => s_hart_reset_req,
      hart_reset_done             => s_cpuResetDone,
      hart_req_halt               => s_hart_req_halt,
      hart_req_halt_on_reset      => s_hart_req_halt_on_reset,
      hart_req_resume             => s_hart_req_resume,
      hart_halted                 => s_hart_halted,
      hart_running                => s_hart_running,
      hart_data0_rdata            => s_hart_data0_rdata,
      hart_data0_wdata            => s_hart_data0_wdata,
      hart_data0_wen              => s_hart_data0_wen,
      hart_instr_data             => s_hart_instr_data,
      hart_instr_data_vld         => s_hart_instr_data_vld,
      hart_instr_data_rdy         => s_hart_instr_data_rdy,
      hart_instr_caught_exception => s_hart_instr_caught_exception,
      hart_instr_caught_ebreak    => s_hart_instr_caught_ebreak,
      CLK_I => s_debugIf_CLK_I,
      RST_I => s_debugIf_RST_I,
      DAT_I => s_debugIf_DAT_I,
      DAT_O => s_debugIf_DAT_O,
      ACK_I => s_debugIf_ACK_I,
      ADDR_O => s_debugIf_ADDR_O,
      CYC_O => s_debugIf_CYC_O,
      ERR_I => s_debugIf_ERR_I,
      SEL_O => s_debugIf_SEL_O,
      STB_O => s_debugIf_STB_O,
      WE_O => s_debugIf_WE_O,
      CTI_O => s_debugIf_CTI_O );
  s_debugIf_LOCK_O <= '0';
  s_debugIf_BTE_O  <= "00";

  cpu : entity work.hazard3_cpu_2port_wb(rtl)
    generic map (
      -- EXTENSION_C is off for timing: with C the core only reaches about 41-45 MHz on a
      -- speed grade 6 ECP5. Turn it on only with a lower clock.
      -- EXTENSION_A and EXTENSION_XH3IRQ are off for timing: with them the core only just
      -- reaches 50 MHz on a speed grade 6 ECP5 (49.7-50.3 MHz depending on the placement
      -- seed); without them it reaches about 53-54 MHz. Software targets rv32im.
      EXTENSION_A         => FALSE,
      EXTENSION_C         => FALSE,
      EXTENSION_M         => TRUE,
      EXTENSION_XH3IRQ    => FALSE,
      CSR_COUNTER         => TRUE,
      DEBUG_SUPPORT       => TRUE,
      BREAKPOINT_TRIGGERS => 2,
      NUMBER_OF_IRQs      => 1,
      IRQ_INPUTREG_BYPASS => (others => FALSE),
      MUL_FAST            => TRUE,
      MUL_FASTER          => FALSE,
      MULH_FAST           => FALSE,
      MULDIV_UNROLL       => 1,
      BRANCH_PREDICTOR    => FALSE )
    port map (
      clk                        => clock,
      clk_always_on              => clock,
      rst                        => s_cpuResetReg,
      reset_vector               => x"0000_0000",
      mtvec_init                 => x"0000_0000",
      pwrup_req                  => s_pwrup_req,
      pwrup_ack                  => s_pwrup_req,
      clk_en                     => open,
      unblock_out                => s_unblock_out,
      unblock_in                 => s_unblock_out,
      i_CYC_O => s_cpuInstr_CYC_O,
      i_STB_O => s_cpuInstr_STB_O,
      i_ADDR_O => s_cpuInstr_ADDR_O,
      i_SEL_O => s_cpuInstr_SEL_O,
      i_WE_O => s_cpuInstr_WE_O,
      i_DAT_O => s_cpuInstr_DAT_O,
      i_CTI_O => s_cpuInstr_CTI_O,
      i_BTE_O => s_cpuInstr_BTE_O,
      i_LOCK_O => s_cpuInstr_LOCK_O,
      i_ACK_I => s_cpuInstr_ACK_I,
      i_ERR_I => s_cpuInstr_ERR_I,
      i_DAT_I => s_cpuInstr_DAT_I,
      d_CYC_O => s_cpuData_CYC_O,
      d_STB_O => s_cpuData_STB_O,
      d_ADDR_O => s_cpuData_ADDR_O,
      d_SEL_O => s_cpuData_SEL_O,
      d_WE_O => s_cpuData_WE_O,
      d_DAT_O => s_cpuData_DAT_O,
      d_CTI_O => s_cpuData_CTI_O,
      d_BTE_O => s_cpuData_BTE_O,
      d_LOCK_O => s_cpuData_LOCK_O,
      d_ACK_I => s_cpuData_ACK_I,
      d_ERR_I => s_cpuData_ERR_I,
      d_DAT_I => s_cpuData_DAT_I,
      fence_i_vld                => open,
      fence_d_vld                => open,
      fence_rdy                  => '1',
      dbg_req_halt               => s_hart_req_halt(0),
      dbg_req_halt_on_reset      => s_hart_req_halt_on_reset(0),
      dbg_req_resume             => s_hart_req_resume(0),
      dbg_halted                 => s_hart_halted(0),
      dbg_running                => s_hart_running(0),
      dbg_data0_rdata            => s_hart_data0_rdata,
      dbg_data0_wdata            => s_hart_data0_wdata,
      dbg_data0_wen              => s_hart_data0_wen(0),
      dbg_instr_data             => s_hart_instr_data,
      dbg_instr_data_vld         => s_hart_instr_data_vld(0),
      dbg_instr_data_rdy         => s_hart_instr_data_rdy(0),
      dbg_instr_caught_exception => s_hart_instr_caught_exception(0),
      dbg_instr_caught_ebreak    => s_hart_instr_caught_ebreak(0),
      mhartid_val                => (others => '0'),
      eco_version                => (others => '0'),
      irq                        => (others => '0'),
      soft_irq                   => '0',
      timer_irq                  => '0',
      ci_id                      => open,
      ci_start                   => open,
      ci_dataa                   => open,
      ci_datab                   => open,
      ci_done                    => '0',
      ci_result                  => (others => '0') );

  busSlave_sramSlave : entity work.sramSlave(platformindependent)
    generic map (
      BaseAddress        => std_logic_vector(to_unsigned(16#0000_0000#, AddrBits)),  -- descending range, as the module slices it
      AddrBits           => AddrBits,
      DataBits           => DataBits,
      nrOfEntriesInBytes => 64*1024 )
    port map (
      CLK_I => s_sramSlave_CLK_I,
      RST_I => s_sramSlave_RST_I,
      DAT_I => s_sramSlave_DAT_I,
      DAT_O => s_sramSlave_DAT_O,
      ACK_O => s_sramSlave_ACK_O,
      ADDR_I => s_sramSlave_ADDR_I,
      CYC_I => s_sramSlave_CYC_I,
      ERR_O => s_sramSlave_ERR_O,
      SEL_I => s_sramSlave_SEL_I,
      STB_I => s_sramSlave_STB_I,
      WE_I => s_sramSlave_WE_I,
      CTI_I => s_sramSlave_CTI_I,
      BTE_I => s_sramSlave_BTE_I );

  busSlave_uartBus : entity work.uartBus(platformIndependent)
    generic map (
      BaseAddress => std_logic_vector(to_unsigned(16#0001_0000#, AddrBits)),  -- descending range, as the module slices it
      AddrBits    => AddrBits,
      DataBits    => DataBits )
    port map (
      CLK_I => s_uartBus_CLK_I,
      RST_I => s_uartBus_RST_I,
      DAT_I => s_uartBus_DAT_I,
      DAT_O => s_uartBus_DAT_O,
      ACK_O => s_uartBus_ACK_O,
      ADDR_I => s_uartBus_ADDR_I,
      CYC_I => s_uartBus_CYC_I,
      ERR_O => s_uartBus_ERR_O,
      SEL_I => s_uartBus_SEL_I,
      STB_I => s_uartBus_STB_I,
      WE_I => s_uartBus_WE_I,
      CTI_I => s_uartBus_CTI_I,
      clock50MHz => s_uartBus_CLK_I,
      irq        => open,
      RxD        => RxD,
      TxD        => TxD );

  SHARED_BUS : if not USE_CROSSBAR generate

  wishboneBus : entity work.wishBoneSharedBusTop(autogenerated)
    generic map (
      AddrBits       => AddrBits,
      DataBits       => DataBits,
      priorityScheme => priorityScheme )
    port map (
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
      RST_O => s_SYSCON_RST_O );

  end generate SHARED_BUS;

  CROSSBAR_BUS : if USE_CROSSBAR generate

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

  end generate CROSSBAR_BUS;

end architecture rtl;
