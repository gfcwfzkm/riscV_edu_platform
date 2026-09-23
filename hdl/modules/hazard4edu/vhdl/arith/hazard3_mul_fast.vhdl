library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

entity hazard3_mul_fast is
    generic(
        MULH_FAST : boolean;
        MUL_FAST : boolean;
        MUL_FASTER : boolean
    );
    port(
        clk        : in  std_logic;
        rst_n      : in  std_logic;

        op         : in  std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        op_vld     : in  std_logic;
        op_a       : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        op_b       : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);

        result     : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        result_vld : out std_logic
    );
end entity hazard3_mul_fast;

architecture rtl of hazard3_mul_fast is

    signal result_valid_reg : std_logic;
    signal op_a_reg, op_b_reg : std_logic_vector(DATA_WIDTH_C-1 downto 0);

begin

    -- Sanity-checks:
    assert not (MULH_FAST and not MUL_FAST) 
        report "MULH_FAST requires that MUL_FAST is also set."
        severity FAILURE;
    
    assert not (MUL_FASTER and not MUL_FAST)
        report "MUL_FASTER requires that MUL_FAST is also set."
        severity FAILURE;

    -- Latency of this module is 1:
    REG_VALID : process(clk, rst_n) is
    begin
        if rst_n = '0' then
            result_valid_reg <= '0';
        elsif rising_edge(clk) then
            result_valid_reg <= op_vld;
        end if;
    end process REG_VALID;
    result_vld <= result_valid_reg;

    MUL_ONLY : if not MULH_FAST generate
        
    end generate MUL_ONLY;
    
    

end architecture rtl;
