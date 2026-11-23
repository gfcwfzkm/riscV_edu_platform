library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

-- Dual-ported top level file for Hazard3 CPU. This file instantiates the
-- Hazard3 core, and interfaces its instruction fetch and load/store signals
-- to a pair of Wishbone B4 classic master ports (Wishbone variant of
-- hazard3_cpu_2port):
--  - AHB5 ports replaced by Wishbone B4 classic masters (hazard3_wb_master,
--    registered address/control)
--  - Debug system bus patch-through removed (the debug module has its own
--    Wishbone master)
--  - No global exclusive monitor: hexokay tied high
entity hazard3_cpu_2port_wb is
    generic(
        -- Standard RISC-V ISA support
        EXTENSION_A         : boolean                                                  := TRUE;  -- Atomic read/modify/write instructions
        EXTENSION_C         : boolean                                                  := TRUE;  -- Compressed (variable-width) instructions
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
        CSR_COUNTER         : boolean                                                  := TRUE;  -- Performance counters and Zicntr CSRs
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
        DEBUG_SUPPORT       : boolean                                                  := TRUE;
        -- Number of triggers which support type=2 execute=1. Requires: DEBUG_SUPPORT
        BREAKPOINT_TRIGGERS : natural                                                  := 8;

        -- Number of external IRQs. Note that if EXTENSION_XH3IRQ (IRQ Controller) is disabled, then
        -- multiple external interrupts are OR'd into mip.meip
        NUMBER_OF_IRQs      : integer range 1 to MAX_NUMBER_OF_IRQ_C                   := 8;
        -- Number of priority bits implemented for each interrupt in meipra
        IRQ_PRIORITY_BITS   : integer range 0 to 4                                     := 0;
        -- Disable the input registers on the external interrupts, IRQ-by-IRQ
        IRQ_INPUTREG_BYPASS : boolean_vector(NUMBER_OF_IRQs - 1 downto 0)              := (others => FALSE);

        -- Performance/size options
        -- Remove all forwarding paths except X->X, to save area
        REDUCED_BYPASS      : boolean                                                  := FALSE;
        -- Bits per clock for multiply/divide circuit, if present. Must be a power of 2.
        MULDIV_UNROLL       : positive                                                 := 2;
        -- Single-cycle multiply circuit for MUL instructions, retiring to stage 3
        MUL_FAST            : boolean                                                  := TRUE;
        -- Retire fast multiply results to stage 2 instead of stage 3. Requires: MUL_FAST
        MUL_FASTER          : boolean                                                  := TRUE;
        -- Extend the fast multiply circuit to also cover MULH*. Requires: MUL_FAST
        MULH_FAST           : boolean                                                  := TRUE;
        -- Separate comparator for branch comparisons, rather than using the ALU
        FAST_BRANCHCMP      : boolean                                                  := TRUE;
        -- Single-entry BTB, allocated on a taken backward branch
        BRANCH_PREDICTOR    : boolean                                                  := TRUE
    );
    port(
        -- Global signals
        clk           : in std_logic;
        clk_always_on : in std_logic;
        rst           : in std_logic;

        -- Address of first instruction executed
        reset_vector  : in std_logic_vector(31 downto 0);
        -- Initial value of trap vector base. Bits clear in MTVEC_WRITE_MASK_C will never change
        -- from this initial value. Bit 0 selects the vectoring mode (0: unvectored, 1: vectored).
        mtvec_init    : in std_logic_vector(31 downto 0);

        -- Power control signals
        pwrup_req   : out std_logic;
        pwrup_ack   : in  std_logic;
        clk_en      : out std_logic;
        unblock_out : out std_logic;
        unblock_in  : in  std_logic;

        -- Instruction fetch port: Wishbone B4 classic master (read-only)
        i_CYC_O  : out std_logic;
        i_STB_O  : out std_logic;
        i_ADDR_O : out std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
        i_SEL_O  : out std_logic_vector(3 downto 0);
        i_WE_O   : out std_logic;
        i_DAT_O  : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        i_CTI_O  : out std_logic_vector(2 downto 0);
        i_BTE_O  : out std_logic_vector(1 downto 0);
        i_LOCK_O : out std_logic;
        i_ACK_I  : in  std_logic;
        i_ERR_I  : in  std_logic;
        i_DAT_I  : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Load/store port: Wishbone B4 classic master
        d_CYC_O  : out std_logic;
        d_STB_O  : out std_logic;
        d_ADDR_O : out std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0);
        d_SEL_O  : out std_logic_vector(3 downto 0);
        d_WE_O   : out std_logic;
        d_DAT_O  : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        d_CTI_O  : out std_logic_vector(2 downto 0);
        d_BTE_O  : out std_logic_vector(1 downto 0);
        d_LOCK_O : out std_logic;
        d_ACK_I  : in  std_logic;
        d_ERR_I  : in  std_logic;
        d_DAT_I  : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

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

        -- Identification CSR values
        mhartid_val : in std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        eco_version : in std_logic_vector(3 downto 0);

        -- Level-sensitive interrupt sources
        irq       : in std_logic_vector(NUMBER_OF_IRQs - 1 downto 0); --> mip.meip
        soft_irq  : in std_logic;                                     --> mip.msip
        timer_irq : in std_logic;                                     --> mip.mtip

        -- Custom Instruction Interface (NIOS II compatible)
        ci_id     : out std_logic_vector(6 downto 0);
        ci_start  : out std_logic;
        ci_dataa  : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        ci_datab  : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        ci_done   : in  std_logic;
        ci_result : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0)
    );
end entity hazard3_cpu_2port_wb;

architecture rtl of hazard3_cpu_2port_wb is

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

begin

    ---------------------------------------------------------------------------
    -- Processor core

    core : entity work.hazard3_core
        generic map(
            EXTENSION_A         => EXTENSION_A,
            EXTENSION_C         => EXTENSION_C,
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
            BRANCH_PREDICTOR    => BRANCH_PREDICTOR
        )
        port map(
            clk                        => clk,
            clk_always_on              => clk_always_on,
            rst                        => rst,
            reset_vector               => reset_vector,
            mtvec_init                 => mtvec_init,

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
            timer_irq                  => timer_irq,

            ci_id                      => ci_id,
            ci_start                   => ci_start,
            ci_dataa                   => ci_dataa,
            ci_datab                   => ci_datab,
            ci_done                    => ci_done,
            ci_result                  => ci_result
        );

    ---------------------------------------------------------------------------
    -- Instruction port

    i_master : entity work.hazard3_wb_master
        generic map(
            W_ADDR => ADDRESS_WIDTH_C,
            W_DATA => DATA_WIDTH_C
        )
        port map(
            clk       => clk,
            rst       => rst,
            aph_req   => core_aph_req_i,
            aph_ready => core_aph_ready_i,
            dph_ready => core_dph_ready_i,
            dph_err   => core_dph_err_i,
            haddr     => core_haddr_i,
            hsize     => core_hsize_i,
            hwrite    => '0',
            wdata     => (others => '0'),
            rdata     => core_rdata_i,
            CYC_O     => i_CYC_O,
            STB_O     => i_STB_O,
            ADDR_O    => i_ADDR_O,
            SEL_O     => i_SEL_O,
            WE_O      => i_WE_O,
            DAT_O     => i_DAT_O,
            CTI_O     => i_CTI_O,
            BTE_O     => i_BTE_O,
            LOCK_O    => i_LOCK_O,
            ACK_I     => i_ACK_I,
            ERR_I     => i_ERR_I,
            DAT_I     => i_DAT_I
        );

    ---------------------------------------------------------------------------
    -- Load/store port

    d_master : entity work.hazard3_wb_master
        generic map(
            W_ADDR => ADDRESS_WIDTH_C,
            W_DATA => DATA_WIDTH_C
        )
        port map(
            clk       => clk,
            rst       => rst,
            aph_req   => core_aph_req_d,
            aph_ready => core_aph_ready_d,
            dph_ready => core_dph_ready_d,
            dph_err   => core_dph_err_d,
            haddr     => core_haddr_d,
            hsize     => core_hsize_d,
            hwrite    => core_hwrite_d,
            wdata     => core_wdata_d,
            rdata     => core_rdata_d,
            CYC_O     => d_CYC_O,
            STB_O     => d_STB_O,
            ADDR_O    => d_ADDR_O,
            SEL_O     => d_SEL_O,
            WE_O      => d_WE_O,
            DAT_O     => d_DAT_O,
            CTI_O     => d_CTI_O,
            BTE_O     => d_BTE_O,
            LOCK_O    => d_LOCK_O,
            ACK_I     => d_ACK_I,
            ERR_I     => d_ERR_I,
            DAT_I     => d_DAT_I
        );

    -- No global exclusive monitor on the shared Wishbone bus: per the Hazard3
    -- documentation hexokay is tied high, so only the core's local monitor
    -- decides LR/SC success (sufficient for a single hart).
    core_dph_exokay_d <= '1';

end architecture rtl;
