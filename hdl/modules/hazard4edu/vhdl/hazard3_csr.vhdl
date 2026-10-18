library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

entity hazard3_csr is 
    generic (
        -- Number of external IRQs. Note that if EXTENSION_XH3IRQ (IRQ Controller) is disabled, then
        -- multiple external interrupts are OR'd into mip.meip
        NUMBER_OF_IRQs      : integer range 1 to MAX_NUMBER_OF_IRQ_C  := 1;
        IRQ_PRIORITY_BITS   : integer range 0 to 4 := 0;
        IRQ_INPUTREG_BYPASS : boolean_vector(NUMBER_OF_IRQs - 1 downto 0) := (others => FALSE);
        MTVEC_INIT          : std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0) := x"0000_0000";
        CSR_M_MANDATORY     : boolean := FALSE;
        CSR_M_TRAP          : boolean := FALSE;
        EXTENSION_A         : boolean := FALSE;
        EXTENSION_C         : boolean := FALSE;
        EXTENSION_E         : boolean := FALSE;
        EXTENSION_M         : boolean := FALSE;
        MUL_FAST            : boolean := FALSE;
        MULH_FAST           : boolean := FALSE;
        EXTENSION_XH3PMPM   : boolean := FALSE;
        EXTENSION_XH3IRQ    : boolean := FALSE;
        U_MODE              : boolean := FALSE;
        DEBUG_SUPPORT       : boolean := FALSE
    );
    port (
        clk             : in std_logic;
        clk_always_on   : in std_logic;
        rst_n           : in std_logic;

        -- Debug Signalling
        debug_mode : out std_logic;

        dbg_req_halt                : in  std_logic;
        dbg_req_halt_on_reset       : in  std_logic;
        dbg_req_resume              : in  std_logic;
        dbg_instr_caught_exception  : out std_logic;
        dbg_instr_caught_ebreak     : out std_logic;

        dbg_data0_rdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_data0_wdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        dbg_data0_wen   : out std_logic;

        debug_dpc_wdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        debug_dpc_wen   : out std_logic;
        debug_dpc_rdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

	    -- Read port is combinatorial.
	    -- Write port is synchronous, and write effects will be observed on the next clock cycle.
	    -- The *_soon strobes are versions which the core does not gate with its stall signal.
	    -- These are needed because:
	    -- - Core stall is a function of bus stall
	    -- - Illegal CSR accesses produce trap entry
	    -- - Trap entry (not necessarily caused by CSR access) gates outgoing bus accesses
	    -- - Through-paths from e.g. hready to htrans are problematic for timing/implementation
        addr                    : in  std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        wdata                   : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        wen                     : in  std_logic;
        wen_soon                : in  std_logic; -- wen will be asserted once some stall condition clears
        wen_raw                 : in  std_logic; -- raw, ungated instruction decode signal, for D-mode regs
        wtype                   : in  std_logic_vector(1 downto 0);
        rdata                   : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        ren                     : in  std_logic;
        ren_soon                : in  std_logic; -- ren will be asserted once some stall condition clears
        illegal                 : out std_logic;
        write_is_fetch_ordered  : out std_logic;

	    -- Trap signalling
	    -- *We* tell the core that we are taking a trap, and where to, based on:
	    -- - Synchronous exception inputs from the core
	    -- - External IRQ signals
	    -- - Masking etc based on the state of CSRs like mie
	    --
	    -- We do this by raising trap_enter_vld, and keeping it raised until trap_enter_rdy
	    -- goes high. trap_addr has the absolute value of trap target address.
	    -- Once trap_enter_vld && _rdy, mepc_in is copied to mepc, and other trap state is set.
	    --
	    -- Note that an exception input can go away, e.g. if the pipe gets flushed. In this
	    -- case we lower trap_enter_vld.
        trap_addr       : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        trap_is_irq     : out std_logic;
        trap_enter_vld  : out std_logic;
        trap_enter_rdy  : in  std_logic;
	    -- True when we are about to trap, but are waiting for an excepting or
	    -- potentially-excepting instruction to clear M first. The instruction in X
	    -- is suppressed, X PC does not increment but still tracks exception
	    -- addresses.
        trap_enter_soon : out std_logic;
	    -- We need to know about load/stores in data phase because their exception
	    -- status is still unknown, so fence them off before entering debug mode.
        loadstore_dphase_pending : in std_logic;
	    -- Asserted when the instruction in stage 2 can't be squashed (e.g. to
	    -- keep an AHB address phase stable), or instruction fetch request can't
	    -- be issued (e.g. waiting for wake from wfi state).
        delay_irq_entry : in std_logic;
        mepc_in         : in std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Power Control Signalling
        pwr_allow_clkgate           : out std_logic;
        pwr_allow_power_down        : out std_logic;
        pwr_allow_sleep_on_block    : out std_logic;
        pwr_wfi_wakeup_req          : out std_logic;

        -- Each of these may be performed at a different privilege level from the others:
        m_mode_execution  : out std_logic;
        m_mode_trap_entry : out std_logic;
        m_mode_loadstore  : out std_logic;

        -- Exceptions must *not* be a function of bus stall
        except           : in std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        except_to_d_mode : in std_logic;

        -- Level-sensitive interrupt sources
        irq             : in std_logic_vector(NUMBER_OF_IRQs - 1 downto 0);
        irq_software    : in std_logic;
        irq_timer       : in std_logic;

        -- PMP config interface
        pmp_cfg_addr  : out std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        pmp_cfg_wen   : out std_logic;
        pmp_cfg_wdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        pmp_cfg_rdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Trigger config interface 
        trig_cfg_addr  : out std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        trig_cfg_wen   : out std_logic;
        trig_cfg_wdata : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        trig_cfg_rdata : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        trig_m_en      : out std_logic;

        -- Interrupt / exception trigger events 
        trig_event_interrupt  : out std_logic;
        trig_event_exception  : out std_logic;
        trig_event_trap_cause : out std_logic_vector(3 downto 0);

        -- Other CSR-specific signalling
        clear_excl_on_trap_exit : out std_logic;
        trap_wfi                : out std_logic;
        instr_ret               : in  std_logic;
        mhartid_val             : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        eco_version             : in  std_logic_vector(3 downto 0)
    );
end entity hazard3_csr;

architecture rtl of hazard3_csr is

    constant H3MISA_STANDARD_LENGTH : std_logic_vector(DATA_WIDTH_C - 1 downto 0) := 32d"77";
    constant H3MISA_CUSTOM_LENGTH   : std_logic_vector(DATA_WIDTH_C - 1 downto 0) := 32d"5";

    constant MISA_VAL : std_logic_vector(DATA_WIDTH_C - 1 downto 0) := (
        2d"1"   & -- MXL: 32bit
        4d"0"   & -- WLRL
        2d"0"   & -- Z, Y, no
        '1'     & -- X is always due to (at least) Xh3misa
        2d"0"   & -- V, W, no
        to_std_logic(U_MODE) &
        7d"0"   & -- T..N, no
        to_std_logic(EXTENSION_M) &
        3d"0"   & -- L..J, no
        to_std_logic(not EXTENSION_E) &
        3d"0"   & -- H, G, F, no
        to_std_logic(EXTENSION_E) &
        1d"0"   & -- D, no
        to_std_logic(EXTENSION_C) &
        1d"0"   & -- B, no
        to_std_logic(EXTENSION_A)
    );

    constant EXTENSION_ZMMUL : boolean :=  EXTENSION_M;
    constant EXTENSION_ZKT   : boolean := not (EXTENSION_M and not MUL_FAST and not MULH_FAST);
    constant EXTENSION_I     : boolean := not EXTENSION_E;

    constant H3MISA_STANDARD_EXTENSION : std_logic_vector(127 downto 0) := (
        76 => to_std_logic(EXTENSION_ZMMUL),
        66 => to_std_logic(EXTENSION_C),
        46 => to_std_logic(EXTENSION_ZKT),
        12 => to_std_logic(EXTENSION_M),
        8 => to_std_logic(EXTENSION_I),
        4 => to_std_logic(EXTENSION_E),
        2 => to_std_logic(EXTENSION_C),
        0 => to_std_logic(EXTENSION_A),
        others => '0'
    );

    constant H3MISA_CUSTOM_EXTENSIONS : std_logic_array_t(0 to 7)(DATA_WIDTH_C - 1 downto 0) := (
        5 => (24 => to_std_logic(EXTENSION_XH3PMPM), others => '0'),
        6 => (24 => to_std_logic(EXTENSION_XH3IRQ), others => '0'),
        7 => (24 => to_std_logic(CSR_M_MANDATORY), others => '0'),
        others => (others => '0')
    );

    signal wdata_update     : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal enter_debug_mode : std_logic;
    signal exit_debug_mode  : std_logic;
    signal debug_mode_reg   : std_logic;
    signal m_mode_reg       : std_logic;
    signal wen_m_mode       : std_logic;
    signal ren_m_mode       : std_logic;
    
    signal debug_suppresses_trap_update : std_logic;
    signal trapreg_update : std_logic;
    signal trapreg_update_enter : std_logic;
    signal trapreg_update_exit : std_logic;

    signal mstatus_mpie_reg : std_logic;
    signal mstatus_mie_reg  : std_logic;
    signal mstatus_mpp_reg  : std_logic;
    signal mstatus_mprv_reg : std_logic;
    signal mstatus_tw_reg   : std_logic;

    signal mscratch_reg     : std_logic_vector(DATA_WIDTH_C - 1 downto 0);

    signal mtvec_reg         : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal mtvec             : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal irq_vector_enable : std_logic;

    signal mepc_reg           : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal mie_reg            : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal meicontext_clearts : std_logic;

    signal mip : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal mcause_irq_reg   : std_logic;
    signal mcause_code_reg  : std_logic_vector(3 downto 0);
    signal mcause_irq_next  : std_logic;
    signal mcause_code_next : std_logic_vector(3 downto 0);

    signal mimpid_rdata : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    
    signal irq_ctrl_rdata : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal external_irq_pending : std_logic;
    signal trap_entry_is_eirq : std_logic;
    signal external_irq_pending_reg : std_logic;

    signal h3misa_info : std_logic_array_t(0 to 1)(DATA_WIDTH_C - 1 downto 0);
    signal h3misa_rdata : std_logic_vector(DATA_WIDTH_C - 1 downto 0);

begin

    debug_mode <= debug_mode_reg;

    ----------------------------------------------------------------------------
    -- CSR state + update logic
    ----------------------------------------------------------------------------
    
    -- Generic update logic for write/set/clear of an entire CSR:
    wdata_update <= rdata and not wdata when wtype = CSR_WTYPE.C else
                    rdata or      wdata when wtype = CSR_WTYPE.S else
                    wdata;
    
    process(clk, rst_n) is
    begin
        if ?? (not rst_n) then
            debug_mode_reg <= '0';
        elsif rising_edge(clk) then
            debug_mode_reg <= (debug_mode_reg and not exit_debug_mode) or enter_debug_mode;
        end if;
    end process;

    -- Core execution state, 1 -> M-mode, 0 -> U-mode (if implemented)
    wen_m_mode <= wen and (m_mode_reg or debug_mode_reg);
    ren_m_mode <= ren and (m_mode_reg or debug_mode_reg);

    ---------------------------------------------------------------------------
    -- Standard trap handling CSRs
    debug_suppresses_trap_update <= to_std_logic(DEBUG_SUPPORT) and (debug_mode_reg or enter_debug_mode);
    trapreg_update <= trap_enter_vld and trap_enter_rdy and not debug_suppresses_trap_update;
    trapreg_update_enter <= trapreg_update and to_std_logic(except /= EXCEPT_C.RETURN_FROM_M_MODE) and to_std_logic(except /= EXCEPT_C.EXCEPTION_REFETCH);
    trapreg_update_exit <= trapreg_update and to_std_logic(except /= EXCEPT_C.RETURN_FROM_M_MODE);

    -- Local monitor flag cleared on trap exit (but not on debug-mode exit, to
    -- permit stepping through LR/SC sequences):
    clear_excl_on_trap_exit <= trapreg_update_exit;

    -- Spec text from priv-1.12:
    -- "An MRET or SRET instruction is used to return from a trap in M-mode or
    --  S-mode respectively. When executing an xRET instruction, supposing xPP
    --  holds the value y, xIE is set to xPIE; the privilege mode is changed to
    --  y; xPIE is set to 1; and xPP is set to the least-privileged supported
    --  mode (U if U-mode is implemented, else M). If xPP=M, xRET also sets
    --  MPRV=0."
    process(clk, rst_n) begin
        if ?? (not rst_n) then
            m_mode_reg <= '1';
            mstatus_mpie_reg <= '0';
            mstatus_mie_reg <= '0';
            mstatus_mpp_reg <= '1';
            mstatus_mprv_reg <= '0';
            mstatus_tw_reg <= '0';
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                m_mode_reg <= '1';
                mstatus_mpie_reg <= '0';
                mstatus_mie_reg <= '0';
                mstatus_mpp_reg <= '1';
                mstatus_mprv_reg <= '0';
                mstatus_tw_reg <= '0';
            else
                if ?? trapreg_update_exit then
                    mstatus_mpie_reg <= '1';
                    mstatus_mie_reg <= mstatus_mpie_reg;
                    if U_MODE then
                        m_mode_reg <= mstatus_mpp_reg;
                        mstatus_mpp_reg <= '0';
                        if ?? (not mstatus_mpp_reg) then
                            mstatus_mprv_reg <= '0';
                        end if;
                    end if;
                elsif ?? trapreg_update_enter then
                    mstatus_mpie_reg <= mstatus_mie_reg;
                    mstatus_mie_reg <= '0';
                    if U_MODE then
                        m_mode_reg <= '1';
                        mstatus_mpp_reg <= m_mode_reg;
                    end if;
                elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_SETUP.MSTATUS then
                    mstatus_mpie_reg <= wdata_update(7);
                    mstatus_mie_reg <= wdata_update(3);
                    mstatus_mprv_reg <= wdata_update(17);
                    -- Not only the MSB of MPP is implemented. It reads back as 11 or 00.
                    mstatus_mpp_reg <= wdata_update(12) or not to_std_logic(U_MODE);
                    mstatus_tw_reg <= wdata_update(21) and to_std_logic(U_MODE);
                elsif wen_raw = '1' and debug_mode_reg = '1' and addr = CSR_ADDRESSES.D_MODE.DCSR and U_MODE and DEBUG_SUPPORT then
                    -- Debugger can change/observe core state directly through
                    -- DCSR.PRV (this does not affect debugger operation, as all
                    -- operations have effective level of M-mode while the core
                    -- is halted for debug.)
                    m_mode_reg <= wdata_update(1);
                end if;
                if not U_MODE then
                    -- Explicitly tie-off to constant
                    m_mode_reg <= '1';
                    mstatus_mpp_reg <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Trap all U-mode WFIs if timeout bit is set. Note that the debug spec
    -- says "The `wfi` instruction acts as a `nop`" during program buffer
    -- execution, and nops do not trap, so in debug mode we allow WFIs but
    -- immediately wake them.
    trap_wfi <= mstatus_tw_reg and not (debug_mode_reg or m_mode_reg);

    process(clk, rst_n) begin
        if ?? (not rst_n) then
            mscratch_reg <= (others => '0');
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                mscratch_reg <= (others => '0');
            else
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_HANDLING.MSCRATCH then
                    mscratch_reg <= wdata_update;
                end if;
            end if;
        end if;
    end process;

    -- Trap vector base
    mtvec <= mtvec_reg and std_logic_vector(shift_left(to_unsigned(1, DATA_WIDTH_C), 2));
    irq_vector_enable <= mtvec_reg(0);

    process(clk, rst_n) begin
        if ?? (not rst_n) then
            mtvec_reg <= MTVEC_INIT;
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                mtvec_reg <= MTVEC_INIT;
            else
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_SETUP.MTVEC then
                    mtvec_reg <= (wdata_update and MTVEC_WRITE_MASK_C) or (mtvec_reg and not MTVEC_WRITE_MASK_C);
                end if;
            end if;
        end if;
    end process;

    process(clk, rst_n) is
        constant MEPC_MASK : std_logic_vector(mepc_reg'range) := (ADDRESS_WIDTH_C - 1 downto 2 => '0') & to_std_logic(EXTENSION_C) & '0';
    begin
        if ?? (not rst_n) then
            mepc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                mepc_reg <= (others => '0');
            else
                if ?? trapreg_update_enter then
                    mepc_reg <= mepc_in and MEPC_MASK;
                elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_HANDLING.MEPC then
                    mepc_reg <= wdata_update and MEPC_MASK;
                end if;
            end if;
        end if;
    end process;

    process(clk, rst_n) is
        constant MIE_WMASK : std_logic_vector(mie_reg'range) := x"0000_0888"; -- meie, mtie, msie
    begin
        if ?? (not rst_n) then
            mie_reg <= (others => '0');
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                mie_reg <= (others => '0');
            else
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_SETUP.MIE then
                    mie_reg <= (wdata_update and MIE_WMASK) or (mie_reg and not MIE_WMASK);
                elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEICONTEXT then
                    -- meicontext.clearts/mtiesave/msiesave can be used to clear and
			        -- save standard timer and soft IRQ enables, simultaneously with
			        -- saving external interrupt context.
                    mie_reg(7) <= (mie_reg(7) or wdata_update(3)) and not meicontext_clearts;
                    mie_reg(3) <= (mie_reg(3) or wdata_update(2)) and not meicontext_clearts;
                end if;
            end if;
        end if;
    end process;

    -- Trap cause registers. The non-constant bits can be written by software, and
    -- update automatically on trap entry. The `code` field need only be large
    -- enough to support causes that will be set by hardware, in our case 4 bits.
    -- (Note this is different to scause which always has a hard minimum of 5
    -- bits.)
    process(clk, rst_n) begin
        if ?? (not rst_n) then
            mcause_irq_reg <= '0';
            mcause_code_reg <= (others => '0');
        elsif rising_edge(clk) then
            if not CSR_M_TRAP then
                mcause_irq_reg <= '0';
                mcause_code_reg <= (others => '0');
            else
                if ?? trapreg_update_enter then
                    mcause_irq_reg <= mcause_irq_next;
                    mcause_code_reg <= mcause_code_next;
                elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.MACHINE_TRAP_HANDLING.MCAUSE then
                    mcause_irq_reg <= wdata_update(31);
                    mcause_code_reg <= wdata_update(3 downto 0);
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Standard identification CSRs
    -- MIMPID Records the RTL release version. Change it with each release manually.

    -- Note the eco_version field is connected externally -- on ASIC this may be
    -- connected to tie cells so it can be incremented following a metal ECO.
    mimpid_rdata <= RTL_MIMPID.PRERELEASE &
                    "000" &
                    RTL_MIMPID.MAJOR &
                    RTL_MIMPID.MINOR &
                    RTL_MIMPID.PATCH &
                    eco_version &
                    x"0";

    ---------------------------------------------------------------------------
    -- Custom external IRQ controller

    trap_entry_is_eirq <= '1' when mcause_irq_next = '1' and mcause_code_next = x"b" else '0';

    HAVE_IRQ_CONTROLLER : if EXTENSION_XH3IRQ generate
        irq_ctrl : entity work.hazard3_irq_ctrl
            generic map(
                NUMBER_OF_IRQs      => NUMBER_OF_IRQs,
                IRQ_PRIORITY_BITS   => IRQ_PRIORITY_BITS,
                IRQ_INPUTREG_BYPASS => IRQ_INPUTREG_BYPASS
            )
            port map(
                clk                  => clk,
                clk_always_on        => clk_always_on,
                rst_n                => rst_n,
                addr                 => addr,
                wtype                => wtype,
                wen_m_mode           => wen_m_mode,
                ren_m_mode           => ren_m_mode,
                wdata_raw            => wdata,
                wdata                => wdata,
                rdata                => rdata,
                trapreg_update_enter => trapreg_update_enter,
                trapreg_update_exit  => trapreg_update_exit,
                trap_entry_is_eirq   => trap_entry_is_eirq,
                meicontext_clearts   => meicontext_clearts,
                mie_mtie             => mie_reg(7),
                mie_msie             => mie_reg(3),
                irq                  => irq,
                external_irq_pending => external_irq_pending
            );
    else generate

        process(clk_always_on, rst_n) begin
            if ?? (not rst_n) then
                external_irq_pending_reg <= '0';
            elsif rising_edge(clk_always_on) then
                external_irq_pending_reg <= or irq
            end if;
        end process;

        irq_ctrl_rdata <= (others => '0');
        meicontext_clearts <= '0';
        external_irq_pending <= external_irq_pending_reg;

    end generate HAVE_IRQ_CONTROLLER;
    
    ---------------------------------------------------------------------------
    -- Custom identification CSRs
    h3misa_info <= H3MISA_CUSTOM_LENGTH & H3MISA_STANDARD_LENGTH;
    h3misa_rdata <= H3MISA_STANDARD_EXTENSION() when ?? (not wdata(10)) else
                    h3misa_info(to_integer(unsigned(wdata(0))))               when ?? (not wdata(8))  else
                    H3MISA_CUSTOM_EXTENSIONS(to_integer(unsigned(wdata(2 downto 0))));

end architecture;