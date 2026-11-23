library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Wishbone B4 classic master for one Hazard3 core bus port (registered
-- outputs). Replaces the AHB-Lite glue of hazard3_cpu_2port.
--
-- The core's bus handshake is AHB-shaped: an address phase (aph_req /
-- aph_ready) followed one cycle later by a data phase (dph_ready / dph_err),
-- with the next address phase allowed to overlap the current data phase.
--
-- Mapping used here:
--   - AHB address phase  -> address, size and direction are captured into
--                           registers (ADDR_O, SEL_O, WE_O come from flops).
--   - AHB data phase     -> one Wishbone classic cycle: CYC_O = STB_O = 1 until
--                           ACK_I or ERR_I. Store data (DAT_O) is the core's
--                           data-phase write data, which is valid exactly then.
--   - ACK_I              -> dph_ready; the next address phase may be accepted in
--                           the same cycle, so back-to-back transfers keep CYC_O
--                           asserted.
--   - ERR_I              -> emulates the two-cycle AHB error response: the cycle
--                           ends, dph_err is raised for two cycles, dph_ready only
--                           in the second one, and no new address is accepted in
--                           the first one (the core uses it to cancel its next
--                           request).
--
-- Only one transfer is outstanding at a time; CTI_O is always "000" (classic).
entity hazard3_wb_master is
    generic(
        W_ADDR : positive := 32;
        W_DATA : positive := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;

        -- Core side
        aph_req   : in  std_logic;
        aph_ready : out std_logic;
        dph_ready : out std_logic;
        dph_err   : out std_logic;
        haddr     : in  std_logic_vector(W_ADDR - 1 downto 0);
        hsize     : in  std_logic_vector(2 downto 0);
        hwrite    : in  std_logic;
        wdata     : in  std_logic_vector(W_DATA - 1 downto 0);
        rdata     : out std_logic_vector(W_DATA - 1 downto 0);

        -- Wishbone master side
        CYC_O  : out std_logic;
        STB_O  : out std_logic;
        ADDR_O : out std_logic_vector(W_ADDR - 1 downto 0);
        SEL_O  : out std_logic_vector(W_DATA / 8 - 1 downto 0);
        WE_O   : out std_logic;
        DAT_O  : out std_logic_vector(W_DATA - 1 downto 0);
        CTI_O  : out std_logic_vector(2 downto 0);
        BTE_O  : out std_logic_vector(1 downto 0);
        LOCK_O : out std_logic;
        ACK_I  : in  std_logic;
        ERR_I  : in  std_logic;
        DAT_I  : in  std_logic_vector(W_DATA - 1 downto 0)
    );
end entity hazard3_wb_master;

architecture rtl of hazard3_wb_master is

    constant HSIZE_BYTE  : std_logic_vector(2 downto 0) := "000";
    constant HSIZE_HWORD : std_logic_vector(2 downto 0) := "001";

    signal busy_reg     : std_logic; -- a Wishbone cycle (= AHB data phase) is in progress
    signal err_pend_reg : std_logic; -- second cycle of an emulated AHB error response
    signal addr_reg     : std_logic_vector(W_ADDR - 1 downto 0);
    signal sel_reg      : std_logic_vector(3 downto 0);
    signal we_reg       : std_logic;

    signal wb_ack     : std_logic;
    signal wb_err     : std_logic;
    signal aph_accept : std_logic;
    signal sel_next   : std_logic_vector(3 downto 0);

begin

    wb_ack <= busy_reg and ACK_I and not ERR_I;
    wb_err <= busy_reg and ERR_I;

    -- A new address is taken when the port is idle, or in the cycle the current
    -- transfer is acknowledged (like hready high at the end of an AHB data phase).
    aph_accept <= aph_req and not err_pend_reg and not wb_err and (not busy_reg or wb_ack);

    aph_ready <= aph_accept;
    dph_ready <= wb_ack or err_pend_reg;
    dph_err   <= wb_err or err_pend_reg;
    rdata     <= DAT_I;

    process(all) begin
        case hsize is
            when HSIZE_BYTE =>
                sel_next <= std_logic_vector(shift_left(to_unsigned(1, 4), to_integer(unsigned(haddr(1 downto 0)))));
            when HSIZE_HWORD =>
                sel_next <= "1100" when ?? haddr(1) else "0011";
            when others =>
                sel_next <= "1111";
        end case;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            if ?? rst then
                busy_reg     <= '0';
                err_pend_reg <= '0';
                addr_reg     <= (others => '0');
                sel_reg      <= (others => '0');
                we_reg       <= '0';
            else
                err_pend_reg <= wb_err;
                if ?? aph_accept then
                    busy_reg <= '1';
                    addr_reg <= haddr(W_ADDR - 1 downto 2) & "00";
                    sel_reg  <= sel_next;
                    we_reg   <= hwrite;
                elsif ?? (wb_ack or wb_err) then
                    busy_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    CYC_O  <= busy_reg;
    STB_O  <= busy_reg;
    ADDR_O <= addr_reg;
    SEL_O  <= sel_reg;
    WE_O   <= we_reg;
    DAT_O  <= wdata;
    CTI_O  <= "000";
    BTE_O  <= "00";
    LOCK_O <= '0';

end architecture rtl;
