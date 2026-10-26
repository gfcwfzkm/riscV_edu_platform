library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

-- Single-ported top level file for Hazard3 CPU. This file instantiates the
-- Hazard3 core, and arbitrates its instruction fetch and load/store signals
-- down to a single AHB5 master port.
entity hazard3_cpu_1port is
    generic(
        -- Address of first instruction executed
        RESET_VECTOR        : unsigned(31 downto 0)                                    := x"0000_0000";
        -- Initial value of trap vector base. Bits clear in MTVEC_WRITE_MASK_C will never change
        -- from this initial value. Bit 0 selects the vectoring mode (0: unvectored, 1: vectored).
        MTVEC_INIT          : std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0)           := x"0000_0000";

        -- Standard RISC-V ISA support
        EXTENSION_A         : boolean                                                  := TRUE;  -- Atomic read/modify/write instructions
        EXTENSION_C         : boolean                                                  := TRUE;  -- Compressed (variable-width) instructions
        EXTENSION_E         : boolean                                                  := TRUE;  -- RV32E base: 15 instead of 31 integer registers
        EXTENSION_M         : boolean                                                  := TRUE;  -- Hardware multiply/divide/modulo instructions

        -- Custom RISC-V extensions
        -- Preemptive, prioritised interrupt support. Can be disabled if an external interrupt
        -- controller (e.g. PLIC) is used. If disabled, the external interrupts are OR'd into mip.meip.
        EXTENSION_XH3IRQ    : boolean                                                  := TRUE;
        -- PMPCFGMx CSRs to enforce PMP regions in M-mode without locking
        EXTENSION_XH3PMPM   : boolean                                                  := TRUE;

        -- Standard CSR support
        CSR_M_MANDATORY     : boolean                                                  := TRUE;  -- Bare minimum CSR support e.g. misa
        CSR_M_TRAP          : boolean                                                  := TRUE;  -- M-mode trap-handling CSRs and trap support
        CSR_COUNTER         : boolean                                                  := FALSE; -- Performance counters and Zicntr CSRs
        -- Support the U (user) execution mode. Requires: CSR_M_TRAP
        U_MODE              : boolean                                                  := FALSE;

        -- Number of physical memory protection regions, or 0 for no PMP.
        PMP_REGIONS         : natural                                                  := 0;
        -- "G" parameter in the privileged spec. Minimum PMP region size is 1 << (G + 2) bytes.
        PMP_GRAIN           : natural                                                  := 0;
        -- Enable PMP support for the NAPOT and NA4 matching modes
        PMP_MATCH_NAPOT     : boolean                                                  := TRUE;
        -- Enable PMP support for the TOR (top-of-range) matching mode
        PMP_MATCH_TOR       : boolean                                                  := FALSE;
        -- If a bit is 1, the corresponding region's pmpaddr and pmpcfg registers are read-only
        PMP_HARDWIRED       : std_logic_vector(maximum(PMP_REGIONS, 1) - 1 downto 0)      := (others => '0');
        -- Values of pmpaddr registers whose PMP_HARDWIRED bits are set to 1 (32 bits per region)
        PMP_HARDWIRED_ADDR  : std_logic_vector(32 * maximum(PMP_REGIONS, 1) - 1 downto 0) := (others => '0');
        -- Values of pmpcfg registers whose PMP_HARDWIRED bits are set to 1 (8 bits per region)
        PMP_HARDWIRED_CFG   : std_logic_vector(8 * maximum(PMP_REGIONS, 1) - 1 downto 0)  := (others => '0');

        -- Support for run/halt and instruction injection from an external Debug Module, support
        -- for Debug Mode, and Debug Mode CSRs. Requires: CSR_M_MANDATORY, CSR_M_TRAP
        DEBUG_SUPPORT       : boolean                                                  := FALSE;
        -- Number of triggers which support type=2 execute=1. Requires: DEBUG_SUPPORT
        BREAKPOINT_TRIGGERS : natural                                                  := 0;

        -- Number of external IRQs. Note that if EXTENSION_XH3IRQ (IRQ Controller) is disabled, then
        -- multiple external interrupts are OR'd into mip.meip
        NUMBER_OF_IRQs      : integer range 1 to MAX_NUMBER_OF_IRQ_C                   := 1;
        -- Number of priority bits implemented for each interrupt in meipra
        IRQ_PRIORITY_BITS   : integer range 0 to 4                                     := 0;
        -- Disable the input registers on the external interrupts, IRQ-by-IRQ
        IRQ_INPUTREG_BYPASS : boolean_vector(NUMBER_OF_IRQs - 1 downto 0)              := (others => FALSE);

        -- Performance/size options
        -- Remove all forwarding paths except X->X, to save area
        REDUCED_BYPASS      : boolean                                                  := FALSE;
        -- Bits per clock for multiply/divide circuit, if present. Must be a power of 2.
        MULDIV_UNROLL       : positive                                                 := 1;
        -- Single-cycle multiply circuit for MUL instructions, retiring to stage 3
        MUL_FAST            : boolean                                                  := FALSE;
        -- Retire fast multiply results to stage 2 instead of stage 3. Requires: MUL_FAST
        MUL_FASTER          : boolean                                                  := FALSE;
        -- Extend the fast multiply circuit to also cover MULH*. Requires: MUL_FAST
        MULH_FAST           : boolean                                                  := FALSE;
        -- Separate comparator for branch comparisons, rather than using the ALU
        FAST_BRANCHCMP      : boolean                                                  := TRUE;
        -- Support reset of the general purpose registers (disable for block-RAM inference)
        RESET_REGFILE       : boolean                                                  := FALSE;
        -- Single-entry BTB, allocated on a taken backward branch
        BRANCH_PREDICTOR    : boolean                                                  := FALSE
    );
    port(
        -- Global signals
        clk           : in std_logic;
        clk_always_on : in std_logic;
        rst_n         : in std_logic;

        -- Power control signals
        pwrup_req   : out std_logic;
        pwrup_ack   : in  std_logic;
        clk_en      : out std_logic;
        unblock_out : out std_logic;
        unblock_in  : in  std_logic;

        -- AHB5 Master port
        haddr     : out std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
        hwrite    : out std_logic;
        htrans    : out std_logic_vector(1 downto 0);
        hsize     : out std_logic_vector(2 downto 0);
        hburst    : out std_logic_vector(2 downto 0);
        hprot     : out std_logic_vector(3 downto 0);
        hmastlock : out std_logic;
        hmaster   : out std_logic_vector(7 downto 0);
        hexcl     : out std_logic;
        hready    : in  std_logic;
        hresp     : in  std_logic;
        hexokay   : in  std_logic;
        hwdata    : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        hrdata    : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Memory ordering signals
        fence_i_vld : out std_logic;
        fence_d_vld : out std_logic;
        fence_rdy   : in  std_logic;

        -- Debugger run/halt control
        dbg_req_halt          : in  std_logic;
        dbg_req_halt_on_reset : in  std_logic;
        dbg_req_resume        : in  std_logic;
        dbg_halted            : out std_logic;
        dbg_running           : out std_logic;

        -- Debugger access to data0 CSR
        dbg_data0_rdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_data0_wdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_data0_wen   : out std_logic;

        -- Debugger instruction injection
        dbg_instr_data             : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_instr_data_vld         : in  std_logic;
        dbg_instr_data_rdy         : out std_logic;
        dbg_instr_caught_exception : out std_logic;
        dbg_instr_caught_ebreak    : out std_logic;

        -- Optional debug system bus access patch-through
        dbg_sbus_addr  : in  std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
        dbg_sbus_write : in  std_logic;
        dbg_sbus_size  : in  std_logic_vector(1 downto 0);
        dbg_sbus_vld   : in  std_logic;
        dbg_sbus_rdy   : out std_logic;
        dbg_sbus_err   : out std_logic;
        dbg_sbus_wdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_sbus_rdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Identification CSR values
        mhartid_val : in std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        eco_version : in std_logic_vector(3 downto 0);

        -- Level-sensitive interrupt sources
        irq       : in std_logic_vector(NUMBER_OF_IRQs - 1 downto 0); --> mip.meip
        soft_irq  : in std_logic;                                     --> mip.msip
        timer_irq : in std_logic                                      --> mip.mtip
    );
end entity hazard3_cpu_1port;

architecture rtl of hazard3_cpu_1port is

    constant HTRANS_IDLE : std_logic_vector(1 downto 0) := "00";
    constant HTRANS_NSEQ : std_logic_vector(1 downto 0) := "10";

    -- ============================================================================
    -- Processor core signals
    -- ============================================================================
    -- Instruction fetch signals
    signal core_aph_req_i   : std_logic;
    signal core_aph_panic_i : std_logic;
    signal core_aph_ready_i : std_logic;
    signal core_dph_ready_i : std_logic;
    signal core_dph_err_i   : std_logic;

    signal core_haddr_i : std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
    signal core_hsize_i : std_logic_vector(2 downto 0);
    signal core_priv_i  : std_logic;
    signal core_rdata_i : std_logic_vector(DATA_WIDTH_C - 1 downto 0);

    -- Load/store signals
    signal core_aph_req_d    : std_logic;
    signal core_aph_excl_d   : std_logic;
    signal core_aph_ready_d  : std_logic;
    signal core_dph_ready_d  : std_logic;
    signal core_dph_err_d    : std_logic;
    signal core_dph_exokay_d : std_logic;

    signal core_haddr_d  : std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
    signal core_hsize_d  : std_logic_vector(2 downto 0);
    signal core_priv_d   : std_logic;
    signal core_hwrite_d : std_logic;
    signal core_wdata_d  : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal core_rdata_d  : std_logic_vector(DATA_WIDTH_C - 1 downto 0);

    -- ============================================================================
    -- Arbitration state machine signals
    -- ============================================================================
    signal bus_gnt_i : std_logic;
    signal bus_gnt_d : std_logic;
    signal bus_gnt_s : std_logic;

    signal bus_hold_aph_reg     : std_logic;
    -- Grants of the previous cycle: (2) instruction fetch, (1) load/store, (0) system bus
    signal bus_gnt_ids_prev_reg : std_logic_vector(2 downto 0);

    signal bus_active_dph_i_reg : std_logic;
    signal bus_active_dph_d_reg : std_logic;
    signal bus_active_dph_s_reg : std_logic;

    -- ============================================================================
    -- Address phase request muxing signals
    -- ============================================================================
    signal hprot_data  : std_logic_vector(3 downto 0);
    signal hprot_instr : std_logic_vector(3 downto 0);
    signal hprot_sbus  : std_logic_vector(3 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Processor core

    core : entity work.hazard3_core
        generic map(
            RESET_VECTOR        => RESET_VECTOR,
            MTVEC_INIT          => MTVEC_INIT,
            EXTENSION_A         => EXTENSION_A,
            EXTENSION_C         => EXTENSION_C,
            EXTENSION_E         => EXTENSION_E,
            EXTENSION_M         => EXTENSION_M,
            EXTENSION_XH3IRQ    => EXTENSION_XH3IRQ,
            EXTENSION_XH3PMPM   => EXTENSION_XH3PMPM,
            CSR_M_MANDATORY     => CSR_M_MANDATORY,
            CSR_M_TRAP          => CSR_M_TRAP,
            CSR_COUNTER         => CSR_COUNTER,
            U_MODE              => U_MODE,
            PMP_REGIONS         => PMP_REGIONS,
            PMP_GRAIN           => PMP_GRAIN,
            PMP_MATCH_NAPOT     => PMP_MATCH_NAPOT,
            PMP_MATCH_TOR       => PMP_MATCH_TOR,
            PMP_HARDWIRED       => PMP_HARDWIRED,
            PMP_HARDWIRED_ADDR  => PMP_HARDWIRED_ADDR,
            PMP_HARDWIRED_CFG   => PMP_HARDWIRED_CFG,
            DEBUG_SUPPORT       => DEBUG_SUPPORT,
            BREAKPOINT_TRIGGERS => BREAKPOINT_TRIGGERS,
            NUMBER_OF_IRQs      => NUMBER_OF_IRQs,
            IRQ_PRIORITY_BITS   => IRQ_PRIORITY_BITS,
            IRQ_INPUTREG_BYPASS => IRQ_INPUTREG_BYPASS,
            REDUCED_BYPASS      => REDUCED_BYPASS,
            MULDIV_UNROLL       => MULDIV_UNROLL,
            MUL_FAST            => MUL_FAST,
            MUL_FASTER          => MUL_FASTER,
            MULH_FAST           => MULH_FAST,
            FAST_BRANCHCMP      => FAST_BRANCHCMP,
            RESET_REGFILE       => RESET_REGFILE,
            BRANCH_PREDICTOR    => BRANCH_PREDICTOR
        )
        port map(
            clk                        => clk,
            clk_always_on              => clk_always_on,
            rst_n                      => rst_n,

            pwrup_req                  => pwrup_req,
            pwrup_ack                  => pwrup_ack,
            clk_en                     => clk_en,
            unblock_out                => unblock_out,
            unblock_in                 => unblock_in,

            bus_aph_req_i              => core_aph_req_i,
            bus_aph_panic_i            => core_aph_panic_i,
            bus_aph_ready_i            => core_aph_ready_i,
            bus_dph_ready_i            => core_dph_ready_i,
            bus_dph_err_i              => core_dph_err_i,
            bus_haddr_i                => core_haddr_i,
            bus_hsize_i                => core_hsize_i,
            bus_priv_i                 => core_priv_i,
            bus_rdata_i                => core_rdata_i,

            bus_aph_req_d              => core_aph_req_d,
            bus_aph_excl_d             => core_aph_excl_d,
            bus_aph_ready_d            => core_aph_ready_d,
            bus_dph_ready_d            => core_dph_ready_d,
            bus_dph_err_d              => core_dph_err_d,
            bus_dph_exokay_d           => core_dph_exokay_d,
            bus_haddr_d                => core_haddr_d,
            bus_hsize_d                => core_hsize_d,
            bus_priv_d                 => core_priv_d,
            bus_hwrite_d               => core_hwrite_d,
            bus_wdata_d                => core_wdata_d,
            bus_rdata_d                => core_rdata_d,

            fence_i_vld                => fence_i_vld,
            fence_d_vld                => fence_d_vld,
            fence_rdy                  => fence_rdy,

            dbg_req_halt               => dbg_req_halt,
            dbg_req_halt_on_reset      => dbg_req_halt_on_reset,
            dbg_req_resume             => dbg_req_resume,
            dbg_halted                 => dbg_halted,
            dbg_running                => dbg_running,
            dbg_data0_rdata            => dbg_data0_rdata,
            dbg_data0_wdata            => dbg_data0_wdata,
            dbg_data0_wen              => dbg_data0_wen,
            dbg_instr_data             => dbg_instr_data,
            dbg_instr_data_vld         => dbg_instr_data_vld,
            dbg_instr_data_rdy         => dbg_instr_data_rdy,
            dbg_instr_caught_exception => dbg_instr_caught_exception,
            dbg_instr_caught_ebreak    => dbg_instr_caught_ebreak,

            mhartid_val                => mhartid_val,
            eco_version                => eco_version,

            irq                        => irq,
            soft_irq                   => soft_irq,
            timer_irq                  => timer_irq
        );

    ---------------------------------------------------------------------------
    -- Arbitration state machine

    -- Note use of clk_always_on: SBA may use this arbiter to access the bus
    -- whilst the core is asleep.
    BUS_HOLD : process(clk_always_on, rst_n) is
    begin
        if ?? (not rst_n) then
            bus_hold_aph_reg     <= '0';
            bus_gnt_ids_prev_reg <= "000";
        elsif rising_edge(clk_always_on) then
            bus_hold_aph_reg     <= htrans(1) and not hready and not hresp;
            bus_gnt_ids_prev_reg <= bus_gnt_i & bus_gnt_d & bus_gnt_s;
        end if;
    end process BUS_HOLD;

    -- Debug SBA access is lower priority than load/store, but higher than
    -- instruction fetch. This isn't ideal, but in a tight loop the core may be
    -- performing an instruction fetch or load/store on every single cycle, and
    -- this is a simple way to guarantee eventual success of debugger accesses. A
    -- more complex way would be to add a "panic timer" to boost a stalled sbus
    -- access over an instruction fetch.

    -- Note that, often, the sbus will be disconnected: it doesn't provide any
    -- increase in debugger bus throughput compared with the program buffer and
    -- autoexec. It's useful for "minimally intrusive" debug bus access(i.e. less
    -- intrusive than halting the core and resuming it) e.g. for Segger RTT.
    BUS_GRANT : process(all) is
        variable gnt : std_logic_vector(2 downto 0);
    begin
        if ?? bus_hold_aph_reg then
            gnt := bus_gnt_ids_prev_reg;
        elsif ?? core_aph_panic_i then
            gnt := "100";
        elsif ?? core_aph_req_d then
            gnt := "010";
        elsif ?? (dbg_sbus_vld and not bus_active_dph_s_reg) then
            gnt := "001";
        elsif ?? core_aph_req_i then
            gnt := "100";
        else
            gnt := "000";
        end if;
        bus_gnt_i <= gnt(2);
        bus_gnt_d <= gnt(1);
        bus_gnt_s <= gnt(0);
    end process BUS_GRANT;

    BUS_ACTIVE_DPH : process(clk_always_on, rst_n) is
    begin
        if ?? (not rst_n) then
            bus_active_dph_i_reg <= '0';
            bus_active_dph_d_reg <= '0';
            bus_active_dph_s_reg <= '0';
        elsif rising_edge(clk_always_on) then
            if ?? hready then
                bus_active_dph_i_reg <= bus_gnt_i;
                bus_active_dph_d_reg <= bus_gnt_d;
                bus_active_dph_s_reg <= bus_gnt_s;
            end if;
        end if;
    end process BUS_ACTIVE_DPH;

    ---------------------------------------------------------------------------
    -- Address phase request muxing

    hprot_data  <= "00" &  -- Noncacheable/nonbufferable
                   core_priv_d & -- Privileged or Normal as per core state
                   '1';    -- Data access

    hprot_instr <= "00" &  -- Noncacheable/nonbufferable
                   core_priv_i & -- Privileged or Normal as per core state
                   '0';    -- Instruction access

    hprot_sbus  <= "00" &  -- Noncacheable/nonbufferable
                   '1' &   -- Always privileged
                   '1';    -- Data access

    hburst    <= "000"; -- HBURST_SINGLE
    hmastlock <= '0';

    AHB_REQUEST : process(all) is
    begin
        if ?? bus_gnt_s then
            htrans  <= HTRANS_NSEQ;
            hexcl   <= '0';
            haddr   <= dbg_sbus_addr;
            hsize   <= '0' & dbg_sbus_size;
            hwrite  <= dbg_sbus_write;
            hprot   <= hprot_sbus;
            hmaster <= x"01";
        elsif ?? bus_gnt_d then
            htrans  <= HTRANS_NSEQ;
            hexcl   <= core_aph_excl_d;
            haddr   <= core_haddr_d;
            hsize   <= core_hsize_d;
            hwrite  <= core_hwrite_d;
            hprot   <= hprot_data;
            hmaster <= x"00";
        elsif ?? bus_gnt_i then
            htrans  <= HTRANS_NSEQ;
            hexcl   <= '0';
            haddr   <= core_haddr_i;
            hsize   <= core_hsize_i;
            hwrite  <= '0';
            hprot   <= hprot_instr;
            hmaster <= x"00";
        else
            htrans  <= HTRANS_IDLE;
            hexcl   <= '0';
            haddr   <= (others => '0');
            hsize   <= "000";
            hwrite  <= '0';
            hprot   <= "0000";
            hmaster <= x"00";
        end if;
    end process AHB_REQUEST;

    hwdata <= dbg_sbus_wdata when ?? bus_active_dph_s_reg else core_wdata_d;

    ---------------------------------------------------------------------------
    -- Response routing

    -- Data buses directly connected
    core_rdata_d   <= hrdata;
    core_rdata_i   <= hrdata;
    dbg_sbus_rdata <= hrdata;

    -- Handhshake based on grant and bus stall
    core_aph_ready_i <= hready and bus_gnt_i;
    core_dph_ready_i <= bus_active_dph_i_reg and hready;
    core_dph_err_i   <= bus_active_dph_i_reg and hresp;

    -- D-side errors are reported even when not ready, so that the core can make
    -- use of the two-phase error response to cleanly squash a second load/store
    -- chasing the faulting one down the pipeline.
    core_aph_ready_d  <= hready and bus_gnt_d;
    core_dph_ready_d  <= bus_active_dph_d_reg and hready;
    core_dph_err_d    <= bus_active_dph_d_reg and hresp;
    core_dph_exokay_d <= bus_active_dph_d_reg and hexokay;

    dbg_sbus_err <= bus_active_dph_s_reg and hresp;
    dbg_sbus_rdy <= bus_active_dph_s_reg and hready;

end architecture rtl;
