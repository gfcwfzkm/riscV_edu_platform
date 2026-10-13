library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

use work.hazard3_constants.all;

entity hazard3_irq_ctrl is
    generic(
        -- Number of external IRQs. Note that if EXTENSION_XH3IRQ (IRQ Controller) is disabled, then
        -- multiple external interrupts are OR'd into mip.meip
        NUMBER_OF_IRQs      : integer range 1 to MAX_NUMBER_OF_IRQ_C  := 1;
        -- Number of priority bits implemented for each interrupt in meipra, if EXTENSION_XH3IRQ is enabled.
        -- The number of distinct levels is (1 << IRQ_PRIORITY_BITS), min. 0, max. 4. Note that multiple
        -- priority levels with a large number of IRQs will have a severe effect on timing.
        IRQ_PRIORITY_BITS   : integer range 0 to 4                  := 0;
        -- Disable the input registers on the external interrupts, to reduce latency by one cycle. Can
        -- be applied on an IRQ-by-IRQ basis. Ignored if EXTENSION_HX3IRQ is disabled.
        IRQ_INPUTREG_BYPASS : boolean_vector(NUMBER_OF_IRQs - 1 downto 0) := (others => FALSE)
    );
    port(
        clk           : in std_logic;
        clk_always_on : in std_logic;
        rst_n         : in std_logic;

        -- CSR interface
        addr        : in  std_logic_vector(11 downto 0);
        wtype       : in  std_logic_vector(1 downto 0);
        wen_m_mode  : in  std_logic;
        ren_m_mode  : in  std_logic;
        wdata_raw   : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        wdata       : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        rdata       : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        -- Trap entry/exit signals for context update
        trapreq_update_enter : in std_logic;
        trapreq_update_exit  : in std_logic;
        trap_entry_is_eirq   : in std_logic;

        -- Interface for clearing and saving mie.mtie/msie via meicontext
        meicontext_clearts   : out std_logic;
        mie_mtie             : in  std_logic;
        mie_msie             : in  std_logic;

        -- External IRQ inputs
        irq                  : in std_logic_vector(NUMBER_OF_IRQs - 1 downto 0);

        -- mip.meip
        external_irq_pending : out std_logic
    );
end entity hazard3_irq_ctrl;

architecture rtl of hazard3_irq_ctrl is
    
    constant IRQ_PRIORITY_MASK      : std_logic_vector(3 downto 0)  := not (x"F" srl IRQ_PRIORITY_BITS);
    constant IRQ_INDEX_BITS         : integer                       := integer(ceil(log2(real(MAX_NUMBER_OF_IRQ_C))));

    -- IRQ register (potentially bypassed)
    signal irq_reg                  : std_logic_vector(NUMBER_OF_IRQs - 1 downto 0);

    -- CSR Write stuff
    signal meinext_irq              : std_logic_vector(IRQ_INDEX_BITS - 1 downto 0);
    signal meinext_noirq            : std_logic;
    signal eirq_highest_priority    : std_logic_vector(3 downto 0);

    -- IRQ array register
    signal meiea_reg                : std_logic_vector(NUMBER_OF_IRQs - 1 downto 0);
    signal meifa_reg                : std_logic_vector(NUMBER_OF_IRQs - 1 downto 0);
    signal meipra_reg               : std_logic_vector(NUMBER_OF_IRQs * 4 - 1 downto 0);

    -- Padded Vectors for CSR readout
    signal meiea_rdata              : std_logic_vector(MAX_NUMBER_OF_IRQ_C - 1 downto 0);
    signal meifa_rdata              : std_logic_vector(MAX_NUMBER_OF_IRQ_C - 1 downto 0);
    signal meipra_rdata             : std_logic_vector(MAX_NUMBER_OF_IRQ_C * 4 - 1 downto 0);

    signal meicontext_pppreempt_reg : std_logic_vector(3 downto 0);
    signal meicontext_ppreempt_reg  : std_logic_vector(3 downto 0);
    signal meicontext_preempt_reg   : std_logic_vector(4 downto 0);
    signal meicontext_noirq_reg     : std_logic;
    signal meicontext_irq_reg       : std_logic_vector(IRQ_INDEX_BITS - 1 downto 0);
    signal meicontext_mreteirq_reg  : std_logic;
    signal preempt_level_next       : std_logic_vector(4 downto 0);

begin

    -- ------------------------------------------------------------------------
    -- IRQ input flops
    --
    -- Register external IRQ signals (mainly to avoid a through-path from IRQs to
    -- bus request signals). Always clocked, as it's used to generate a wakeup.
    -- Input registers can be removed on a per-IRQ basis, but this should be done
    -- with care as it does create a through-path from the IRQ to the bus.
    IRQ_INPUT_FF : for i in 0 to NUMBER_OF_IRQs - 1 generate
        BYPASS : if IRQ_INPUTREG_BYPASS(i) generate
            irq_reg(i) <= irq(i);
        else generate
            IRQ_FF : process(clk, rst_n) is
            begin
                if rst_n = '0' then
                    irq_reg(i) <= '0';
                elsif rising_edge(clk) then
                    irq_reg(i) <= irq(i);
                end if;
            end process IRQ_FF;
        end generate BYPASS;
    end generate IRQ_INPUT_FF;
    
    -- ----------------------------------------------------------------------------
    -- CSR write
    meiea_rdata <= (MAX_NUMBER_OF_IRQ_C - 1 downto NUMBER_OF_IRQs => '0') & meiea_reg;
    meifa_rdata <= (MAX_NUMBER_OF_IRQ_C - 1 downto NUMBER_OF_IRQs => '0') & meifa_reg;
    meipra_rdata <= (MAX_NUMBER_OF_IRQ_C * 4 - 1 downto NUMBER_OF_IRQs => '0') & meipra_reg;

    UPDATE_IRQ_REG_ARRAYS : process(clk, rst_n) is
        variable i_vec : unsigned(IRQ_INDEX_BITS - 1 downto 0);
    begin
        if rst_n = '0' then
            meiea_reg <= (others => '0');
            meifa_reg <= (others => '0');
            meipra_reg <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to NUMBER_OF_IRQs - 1 loop
                i_vec := to_unsigned(i, IRQ_INDEX_BITS);

                -- CSR write update. Note raw wdata is used for array indexing
                -- Necessary for correctness, and also avoid a loop with rdata.
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEIEA and 
                   unsigned(wdata_raw(4 downto 0)) = i_vec(IRQ_INDEX_BITS - 1 downto 4) then
                    meiea_rdata(i) <= wdata(16 + (i mod 16));
                end if;
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEIFA and 
                   unsigned(wdata_raw(4 downto 0)) = i_vec(IRQ_INDEX_BITS - 1 downto 4) then
                    meifa_rdata(i) <= wdata(16 + (i mod 16));
                end if;
                if wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEIPRA and 
                   unsigned(wdata_raw(6 downto 0)) = i_vec(IRQ_INDEX_BITS - 1 downto 2) then
                    meiea_rdata(i) <= wdata(16 + (i mod 16));
                end if;

                -- Clear IRQ force when the corresponding IRQ is sampled from meinext
                -- (so that an IRQ can be posted *once* without modifying the ISR source)
                if meinext_irq = std_logic_vector(i_vec) and ren_m_mode = '1' and 
                   addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEINEXT and meinext_noirq = '0' then
                    meifa_reg(i) <= '0';
                end if;
            end loop;            
        end if;
    end process UPDATE_IRQ_REG_ARRAYS;
    
    preempt_level_next <= 5x"10" when meinext_noirq = '1' else 
                          std_logic_vector(
                            shift_left(to_unsigned(1, 5), 4 - IRQ_PRIORITY_BITS) + 
                            resize(unsigned(eirq_highest_priority), 5)
                          );
        
    process(clk, rst_n) is
    begin
        if rst_n = '0' then
            meicontext_pppreempt_reg <= (others => '0');
            meicontext_ppreempt_reg <= (others => '0');
            meicontext_preempt_reg <= (others => '0');
            meicontext_noirq_reg <= '0';
            meicontext_irq_reg <= (others => '0');
            meicontext_mreteirq_reg <= '0';
        elsif rising_edge(clk) then
            if trapreq_update_enter = '1' then
                if trap_entry_is_eirq = '1' then
                    -- Priority save. Note the MSB of preempt needn't be saved, since
                    -- when it is set, preemption is impossible, so we won't be here.
                    meicontext_pppreempt_reg <= meicontext_ppreempt_reg and IRQ_PRIORITY_MASK;
                    meicontext_ppreempt_reg <= meicontext_preempt_reg(3 downto 0) and IRQ_PRIORITY_MASK;
                    -- Setting preempt isn't strictly necessary, since an updating read
                    -- of meinext ought to be performed before re-enabling IRQs via 
                    -- mstatus.mie, but it seems the least surprising thing to do:
                    meicontext_preempt_reg <= preempt_level_next and ('1' & IRQ_PRIORITY_MASK);
                    meicontext_mreteirq_reg <= '1';
                else
                    meicontext_mreteirq_reg <= '0';
                end if;
            elsif trapreq_update_exit = '1' then
                meicontext_mreteirq_reg <= '0';
                if meicontext_mreteirq_reg = '1' then
                    -- Priority restore
                    meicontext_pppreempt_reg <= (others => '0');
                    meicontext_ppreempt_reg <= meicontext_pppreempt_reg and IRQ_PRIORITY_MASK;
                    meicontext_preempt_reg <= '1' & (meicontext_ppreempt_reg and IRQ_PRIORITY_MASK);
                end if;
            elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEICONTEXT then
                meicontext_pppreempt_reg <= wdata(31 downto 28) and IRQ_PRIORITY_MASK;
                meicontext_ppreempt_reg <= wdata(27 downto 24) and IRQ_PRIORITY_MASK;
                meicontext_preempt_reg <= wdata(20 downto 16) and ('1' & IRQ_PRIORITY_MASK);
                meicontext_noirq_reg <= wdata(15);
                meicontext_irq_reg <= wdata(12 downto 4);
                meicontext_mreteirq_reg <= wdata(0);
            elsif wen_m_mode = '1' and addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEINEXT and wdata(0) = '1' then
                -- Interrupt has been sampled, with the update request set, so update
                -- the context (including preemption level) appropriately.
                meicontext_preempt_reg <= preempt_level_next and ('1' & IRQ_PRIORITY_MASK);
                meicontext_noirq_reg <= meinext_noirq;
                meicontext_irq_reg <= meinext_irq;
            end if;
        end if;        
    end process;

    meicontext_clearts <= '1' when wen_m_mode = '1' and
                                   wtype /= CSR_WTYPE.C and
                                   addr = CSR_ADDRESSES.CUSTOM_M_MODE.MEICONTEXT and
                                   wdata_raw(1) = '1'
                              else '0';

    -- ----------------------------------------------------------------------------
    -- External interrupt logic
    --
    -- Trap request is asserted when there is an interrupt at or above our current
    -- preemption level. meinext displays interrupts at or above our *previous*
    -- preemption level: this masking helps avoid re-taking IRQs in frames that you
    -- have preempted. 

        
    
end architecture rtl;
