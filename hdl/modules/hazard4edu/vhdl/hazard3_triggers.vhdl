library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

use work.hazard3_constants.all;

entity hazard3_triggers is
    generic(
        -- Support for run/halt and instruction injection from any external
        -- Debug Module, support for Debug Mode, and Debug Mode CSR.
        -- Requires: CSR_M_MANDATORY, CSR_M_TRAP
        DEBUG_SUPPORT       : boolean := FALSE;
        -- Number of triggers which support type=2 execute=1 (but not store/load=1,
        -- i.e. not a watchpoint).
        -- Requires: DEBUG_SUPPORT
        BREAKPOINT_TRIGGERS : natural := 0;
        U_MODE              : boolean := FALSE;
        EXTENSION_C         : boolean := FALSE;
    );
    port(
        clk              : in  std_logic;
        rst_n            : in  std_logic;
        -- Config interface passed through CSR block
        cfg_addr         : in  std_logic_vector(11 downto 0);
        cfg_wen          : in  std_logic;
        cfg_wdata        : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        cfg_rdata        : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        -- Global trigger-to-M-mode enabled from tcontrol
        trig_m_en        : in  std_logic;
        -- Fetch address query from stage F
        fetch_addr       : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        fetch_m_mode     : in  std_logic;
        fetch_d_mode     : in  std_logic;
        -- Trap trigger events from stage X
        event_instr_ret  : in  std_logic;
        -- Trap trigger events from stage M
        event_interrupt  : in  std_logic;
        event_exception  : in  std_logic;
        event_trap_cause : in  std_logic_vector(3 downto 0);
        event_trap_enter : in  std_logic;
        -- F-aligned break request (for each halfword of word-sized word-aligned fetch)
        break_any        : out std_logic_vector(1 downto 0);
        break_d_mode     : out std_logic_vector(1 downto 0);
        -- X-aligned step break request (to M-mode only)
        break_m_step     : out std_logic;
        -- Stage-X debug mode flag, for CSR protection (may or may not be the same as the query debug mode flag)
        x_d_mode         : in  std_logic;
        -- Stage-X M-mode flag, for enables on interrupt / exception triggers
        x_m_mode         : in  std_logic;
    );
end entity hazard3_triggers;

architecture rtl of hazard3_triggers is
    function bool_to_std_logic(value : boolean) return std_logic is
    begin
        if value then
            return '1';
        else
            return '0';
        end if;
    end function bool_to_std_logic;

    constant TRIGGER_INDEX_COUNT       : natural  := BREAKPOINT_TRIGGERS;
    constant TRIGGER_INDEX_INTERRUPT   : natural  := BREAKPOINT_TRIGGERS + 1;
    constant TRIGGER_INDEX_EXCEPTION   : natural  := BREAKPOINT_TRIGGERS + 2;
    constant NUMBER_OF_TRIGGERS        : natural  := BREAKPOINT_TRIGGERS + 3;
    constant NUMBER_OF_BREAKPOINT_REGS : positive := maximum(1, BREAKPOINT_TRIGGERS);

    -- Configuration State
    constant W_TRIGGER_SELECT : positive := integer(ceil(log2(real(NUMBER_OF_TRIGGERS))));


    -- Note tdata1 and mcontrol are the same CSR. tdata1 refers to the universal
    -- fields (type/dmode) and mcontrol refers to those fields specific to
    -- type=2 (address/data match), the only trigger type we implement.

    -- State for instruction address match triggers (breakpoints).
    signal bp_tdata1_dmode_reg  : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal mcontrol_action_reg  : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal mcontrol_m_reg       : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal mcontrol_u_reg       : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal mcontrol_execute_reg : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    type bp_tdata2_t is array (NUMBER_OF_BREAKPOINT_REGS-1 downto 0) of std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal bp_tdata2_reg : bp_tdata2_t;

    -- State for instruction count trigger
    -- (hardwired: count=1 dmode=0 action=0; Debug mode single step is already available via dcsr)
    signal icount_m_reg : std_logic;
    signal icount_u_reg : std_logic;

    -- State for interrupt trigger
    -- (hardwired: action=1; M-mode trap-on-trap is useless as you lose the original trap state)
    signal trigger_irq_m_reg : std_logic;
    signal trigger_irq_u_reg : std_logic;
    signal trigger_irq_dmode_reg : std_logic;
    signal trigger_irq_cause_reg : std_logic_vector(15 downto 0);

    constant IMPLEMENTED_IRQ_CAUSES : std_logic_vector(15 downto 0) := (
        "0000" &    -- reserved
        '1' &       -- meip
        "000" &     -- reserved / unimplemented
        '1' &       -- mtip
        "000" &     -- reserved / unimplemented
        '1' &       -- msip
        "000"       -- reserved / unimplemented
    );

    -- State for exception trigger
    -- (hardwired: action=1; M-mode trap-on-trap is useless as you loose the original trap state)
    signal trigger_exception_m_reg : std_logic;
    signal trigger_exception_u_reg : std_logic;
    signal trigger_exception_dmode_reg : std_logic;
    signal trigger_exception_cause_reg : std_logic_vector(15 downto 0);

    constant IMPLEMENTED_EXCEPTION_CAUSES : std_logic_vector(15 downto 0) := (
        "0000" &
        '1' &
        "00" &
        bool_to_std_logic(U_MODE) &
        '1' &
        '1' &
        '1' &
        '1' &
        '0' &
        '1' &
        '1' &
        bool_to_std_logic(not EXTENSION_C)
    );

    constant NUMBER_OF_TRIGGERS_PADDED : natural := 2 ** integer(ceil(log2(real(NUMBER_OF_TRIGGERS))));
    signal tselect_match : std_logic_vector(NUMBER_OF_TRIGGERS_PADDED-1 downto 0);

    type tdata_rdata_t is array (NUMBER_OF_TRIGGERS_PADDED-1 downto 0) of std_logic_vector(DATA_WIDTH_C-1 downto 0);
    signal tdata1_rdata, tdata2_rdata, tinfo_rdata : tdata_rdata_t;
    signal exception_trigger_match : std_logic;
    signal interrupt_trigger_match : std_logic;
    signal break_ie_reg : std_logic;
    signal step_break_enabled : std_logic;
    signal break_on_step_reg : std_logic;

    signal breakpoint_enabled : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal breakpoint_match : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_m_mode_break : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_m_mode_break_hw0 : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_m_mode_break_hw1 : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_d_mode_break : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_d_mode_break_hw0 : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);
    signal want_d_mode_break_hw1 : std_logic_vector(NUMBER_OF_BREAKPOINT_REGS-1 downto 0);

begin
    assert DEBUG_SUPPORT or BREAKPOINT_TRIGGERS = 0
    report "BREAKPOINT_TRIGGERS /= 0 requires DEBUG_SUPPORT"
    severity failure;

    NO_TRIGGERS : if not DEBUG_SUPPORT generate
        cfg_rdata    <= (others => '0');
        break_any    <= "00";
        break_d_mode <= "00";
    end generate NO_TRIGGERS;

    HAVE_TRIGGERS : if DEBUG_SUPPORT generate
        --
        -- Break flags to front end (tag the current fetch dphase as containing a breakpoint)
        break_any       <= ( (or want_m_mode_break_hw1) or (or want_d_mode_break_hw1) or break_ie_reg &
                             (or want_m_mode_break_hw0) or (or want_d_mode_break_hw0) or break_ie_reg )
                            when BREAKPOINT_TRIGGERS > 0 else "00";
        break_d_mode    <= ( (or want_d_mode_break_hw1) or break_ie_reg &
                             (or want_d_mode_break_hw0) or break_ie_reg )
                            when BREAKPOINT_TRIGGERS > 0 else "00";

        MATCH_PC : for i in 0 to NUMBER_OF_BREAKPOINT_REGS-1 generate
            -- Detect breakpoints
            breakpoint_enabled(i) <= mcontrol_execute_reg(i) and (not fetch_d_mode) and mcontrol_m_reg(i) when fetch_m_mode = '1' else
                                     mcontrol_execute_reg(i) and (not fetch_d_mode) and mcontrol_u_reg(i);
            breakpoint_match(i) <= '1' when fetch_addr = (bp_tdata2_reg(i)(DATA_WIDTH_C-1 downto 2) & "00") else '0';
            -- Decide the type of break implied by the trip
            want_d_mode_break(i) <= breakpoint_match(i) and mcontrol_action_reg(i) and bp_tdata1_dmode_reg(i);
            want_m_mode_break(i) <= breakpoint_match(i) and (not mcontrol_action_reg(i)) and trig_m_en;
            -- Report seperately for each halfword, so the frontend can pass this through the prefetch buffer.
            -- A breakpoint exception is taken when the first halfword of an instruction (of any size) is flagged
            -- with a breakpoint, implying an exact match.
            want_d_mode_break_hw0(i) <= want_d_mode_break(i) and (not bp_tdata2_reg(i)(1));
            want_d_mode_break_hw1(i) <= want_d_mode_break(i) and bp_tdata2_reg(i)(1);
            want_m_mode_break_hw0(i) <= want_m_mode_break(i) and (not bp_tdata2_reg(i)(1));
            want_m_mode_break_hw1(i) <= want_m_mode_break(i) and bp_tdata2_reg(i)(1);
        end generate MATCH_PC;
        

        
    end generate HAVE_TRIGGERS;
end architecture rtl;
