library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

entity hazard3_regfile_1w2r is
    generic (
        EXTENSION_E   : boolean := true;
        RESET_REGFILE : boolean := false
    );
    port (
        clk    : in std_logic;
        rst_n  : in std_logic;

        raddr1 : in  std_logic_vector(REGISTER_ADDRESS_WIDTH_C - 1 downto 0);
        rdata1 : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        raddr2 : in  std_logic_vector(REGISTER_ADDRESS_WIDTH_C - 1 downto 0);
        rdata2 : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        waddr  : in std_logic_vector(REGISTER_ADDRESS_WIDTH_C - 1 downto 0);
        wdata  : in std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        wen    : in std_logic
    );
end entity hazard3_regfile_1w2r;

architecture rtl of hazard3_regfile_1w2r is

    constant NUMBER_OF_REGISTERS   : positive := num_of_regs(EXTENSION_E);
    constant REGISTER_ADDRESS_MASK : std_logic_vector(REGISTER_ADDRESS_WIDTH_C - 1 downto 0) := not to_std_logic(EXTENSION_E) & x"F";

    type mem_t is array (0 to NUMBER_OF_REGISTERS - 1) of
        std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal register_memory : mem_t;
    signal raddr1_masked   : std_logic_vector(4 downto 0);
    signal raddr2_masked   : std_logic_vector(4 downto 0);
    signal waddr_masked    : std_logic_vector(4 downto 0);

begin
    raddr1_masked <= raddr1 and REGISTER_ADDRESS_MASK;
    raddr2_masked <= raddr2 and REGISTER_ADDRESS_MASK;
    waddr_masked  <= waddr and REGISTER_ADDRESS_MASK;

    REGFILE_WITH_RESET : if RESET_REGFILE generate
        process(clk, rst_n)
        begin
            if rst_n = '0' then
                register_memory <= (others => (others => '0'));
                rdata1 <= (others => '0');
                rdata2 <= (others => '0');
            elsif rising_edge(clk) then
                if wen = '1' then
                    register_memory(to_integer(unsigned(waddr_masked))) <= wdata;
                end if;
                rdata1 <= register_memory(to_integer(unsigned(raddr1_masked)));
                rdata2 <= register_memory(to_integer(unsigned(raddr2_masked)));
            end if;
        end process;
    end generate REGFILE_WITH_RESET;

    REGFILE_WITHOUT_RESET : if not RESET_REGFILE generate
        process(clk)
        begin
            if rising_edge(clk) then
                if wen = '1' then
                    register_memory(to_integer(unsigned(waddr_masked))) <= wdata;
                end if;
                rdata1 <= register_memory(to_integer(unsigned(raddr1_masked)));
                rdata2 <= register_memory(to_integer(unsigned(raddr2_masked)));
            end if;
        end process;
    end generate REGFILE_WITHOUT_RESET;
end architecture rtl;
