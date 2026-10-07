library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.hazard3_constants.all;

entity hazard3_instr_decompress is
    generic(
        EXTENSION_C : boolean := TRUE;
        EXTENSION_M : boolean := TRUE
    );
    port(
        clk                       : in  std_logic;
        rst_n                     : in  std_logic;
        instr_in                  : in  std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        instr_is_32bit            : out std_logic;
        instr_out                 : out std_logic_vector(DATA_WIDTH_C - 1 downto 0);
        instr_out_is_uop          : out std_logic;
        instr_out_is_final_uop    : out std_logic;
        instr_out_uop_no_pc_update : out std_logic;
        instr_out_uop_atomic      : out std_logic;
        instr_out_uop_stall       : in  std_logic;
        instr_out_uop_clear       : in  std_logic;
        df_uop_step               : out std_logic_vector(3 downto 0);
        invalid                   : out std_logic
    );
end entity hazard3_instr_decompress;

architecture rtl of hazard3_instr_decompress is
    constant REGISTER_ADDRESS_WIDTH : positive := 5;
    constant REGISTER_X0            : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0) := "00000";
    constant REGISTER_X1            : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0) := "00001";
    constant REGISTER_X2            : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0) := "00010";

    function format_rd(register_number : std_logic_vector) return std_logic_vector is
    begin
        return x"00000" & register_number & "0000000";
    end function format_rd;

    function format_rs1(register_number : std_logic_vector) return std_logic_vector is
    begin
        return x"000" & register_number & "000000000000000";
    end function format_rs1;

    function format_rs2(register_number : std_logic_vector) return std_logic_vector is
    begin
        return "0000000" & register_number & x"00000";
    end function format_rs2;

    function any_bit_set(value : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for index in value'range loop
            result := result or value(index);
        end loop;
        return result;
    end function any_bit_set;

    signal rd_long              : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal rs1_long             : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal rs2_long             : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal rd_short             : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal rs1_short            : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal rs2_short            : std_logic_vector(REGISTER_ADDRESS_WIDTH - 1 downto 0);
    signal immediate_ci         : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal immediate_cj         : std_logic_vector(DATA_WIDTH_C - 1 downto 0);
    signal immediate_cb         : std_logic_vector(DATA_WIDTH_C - 1 downto 0);

begin
    rd_long   <= instr_in(11 downto 7);
    rs1_long  <= instr_in(11 downto 7);
    rs2_long  <= instr_in(6 downto 2);
    rd_short  <= "01" & instr_in(4 downto 2);
    rs1_short <= "01" & instr_in(9 downto 7);
    rs2_short <= "01" & instr_in(4 downto 2);

    immediate_ci <= (11 downto 5 => instr_in(12)) & instr_in(6 downto 2) & x"00000";
    immediate_cj <= instr_in(12) & instr_in(8) & instr_in(10 downto 9) & instr_in(6) &
                    instr_in(7) & instr_in(2) & instr_in(11) & instr_in(5 downto 3) &
                    (20 downto 12 => instr_in(12)) & x"000";
    immediate_cb <= (31 downto 28 => instr_in(12)) & instr_in(6 downto 5) & instr_in(2) &
                    "0000000000000" & instr_in(11 downto 10) & instr_in(4 downto 3) &
                    instr_in(12) & "0000000";

    instr_out_is_uop <= '0';
    instr_out_is_final_uop <= '0';
    instr_out_uop_atomic <= '0';
    instr_out_uop_no_pc_update <= '0';
    df_uop_step <= (others => '0');

    instr_passthrough : if not EXTENSION_C generate
        passthrough_logic : process(all) is
        begin
            instr_is_32bit <= '1';
            instr_out <= instr_in;
            invalid <= '0';
        end process passthrough_logic;
    end generate instr_passthrough;

    instr_decompress : if EXTENSION_C generate
        decompress_logic : process(all) is
        begin
            instr_is_32bit <= '1';
            instr_out <= instr_in;
            invalid <= '0';

            if instr_in(1 downto 0) /= "11" then
                instr_is_32bit <= '0';
                instr_out <= (others => '0');

                if std_match(instr_in(15 downto 0), OPCODE_C.C_ADDI4SPN) then
                    instr_out <= OPCODE_C.ADDI or format_rd(rd_short) or format_rs1(REGISTER_X2) or
                                 ("00" & instr_in(10 downto 7) & instr_in(12 downto 11) &
                                  instr_in(5) & instr_in(6) & "00" & x"00000");
                    invalid <= not any_bit_set(instr_in(12 downto 2));
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_LW) then
                    instr_out <= OPCODE_C.LW or format_rd(rd_short) or format_rs1(rs1_short) or
                                 ("00000" & instr_in(5) & instr_in(12 downto 10) &
                                  instr_in(6) & "00" & x"00000");
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SW) then
                    instr_out <= OPCODE_C.SW or format_rs2(rs2_short) or format_rs1(rs1_short) or
                                 ("00000" & instr_in(5) & instr_in(12) & "0000000000000" &
                                  instr_in(11 downto 10) & instr_in(6) & "00" & "0000000");
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_ADDI) then
                    instr_out <= OPCODE_C.ADDI or format_rd(rd_long) or format_rs1(rs1_long) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_JAL) then
                    instr_out <= OPCODE_C.JAL or format_rd(REGISTER_X1) or immediate_cj;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_J) then
                    instr_out <= OPCODE_C.JAL or format_rd(REGISTER_X0) or immediate_cj;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_LI) then
                    instr_out <= OPCODE_C.ADDI or format_rd(rd_long) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_LUI) then
                    if rd_long = REGISTER_X2 then
                        instr_out <= OPCODE_C.ADDI or format_rd(REGISTER_X2) or format_rs1(REGISTER_X2) or
                                     ((29 downto 27 => instr_in(12)) & instr_in(4 downto 3) &
                                      instr_in(5) & instr_in(2) & instr_in(6) & x"000000");
                    else
                        instr_out <= OPCODE_C.LUI or format_rd(rd_long) or
                                     ((26 downto 12 => instr_in(12)) & instr_in(6 downto 2) & x"000");
                    end if;
                    invalid <= not any_bit_set(instr_in(12) & instr_in(6 downto 2));
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SLLI) then
                    instr_out <= OPCODE_C.SLLI or format_rd(rs1_long) or format_rs1(rs1_long) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SRAI) then
                    instr_out <= OPCODE_C.SRAI or format_rd(rs1_short) or format_rs1(rs1_short) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SRLI) then
                    instr_out <= OPCODE_C.SRLI or format_rd(rs1_short) or format_rs1(rs1_short) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_ANDI) then
                    instr_out <= OPCODE_C.ANDI or format_rd(rs1_short) or format_rs1(rs1_short) or immediate_ci;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_AND) then
                    instr_out <= OPCODE_C.AND_OP or format_rd(rs1_short) or format_rs1(rs1_short) or format_rs2(rs2_short);
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_OR) then
                    instr_out <= OPCODE_C.OR_OP or format_rd(rs1_short) or format_rs1(rs1_short) or format_rs2(rs2_short);
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_XOR) then
                    instr_out <= OPCODE_C.XOR_OP or format_rd(rs1_short) or format_rs1(rs1_short) or format_rs2(rs2_short);
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SUB) then
                    instr_out <= OPCODE_C.SUB or format_rd(rs1_short) or format_rs1(rs1_short) or format_rs2(rs2_short);
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_ADD) then
                    if rs2_long /= (REGISTER_ADDRESS_WIDTH - 1 downto 0 => '0') then
                        instr_out <= OPCODE_C.ADD or format_rd(rd_long) or format_rs1(rs1_long) or format_rs2(rs2_long);
                    elsif rs1_long /= (REGISTER_ADDRESS_WIDTH - 1 downto 0 => '0') then
                        instr_out <= OPCODE_C.JALR or format_rd(REGISTER_X1) or format_rs1(rs1_long);
                    else
                        instr_out <= OPCODE_C.EBREAK;
                    end if;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_MV) then
                    if rs2_long /= (REGISTER_ADDRESS_WIDTH - 1 downto 0 => '0') then
                        instr_out <= OPCODE_C.ADD or format_rd(rd_long) or format_rs2(rs2_long);
                    else
                        instr_out <= OPCODE_C.JALR or format_rs1(rs1_long);
                        invalid <= not any_bit_set(rs1_long);
                    end if;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_LWSP) then
                    instr_out <= OPCODE_C.LW or format_rd(rd_long) or format_rs1(REGISTER_X2) or
                                 ("0000" & instr_in(3 downto 2) & instr_in(12) &
                                  instr_in(6 downto 4) & "00" & x"00000");
                    invalid <= not any_bit_set(rd_long);
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_SWSP) then
                    instr_out <= OPCODE_C.SW or format_rs2(rs2_long) or format_rs1(REGISTER_X2) or
                                 ("0000" & instr_in(8 downto 7) & instr_in(12) & "0000000000000" &
                                  instr_in(11 downto 9) & "00" & "0000000");
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_BEQZ) then
                    instr_out <= OPCODE_C.BEQ or format_rs1(rs1_short) or immediate_cb;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_BNEZ) then
                    instr_out <= OPCODE_C.BNE or format_rs1(rs1_short) or immediate_cb;
                elsif std_match(instr_in(15 downto 0), OPCODE_C.C_MUL) then
                    instr_out <= OPCODE_C.MUL or format_rd(rs1_short) or format_rs1(rs1_short) or format_rs2(rs2_short);
                    if not EXTENSION_M then
                        invalid <= '1';
                    end if;
                else
                    invalid <= '1';
                end if;
            end if;
        end process decompress_logic;
    end generate instr_decompress;
end architecture rtl;
