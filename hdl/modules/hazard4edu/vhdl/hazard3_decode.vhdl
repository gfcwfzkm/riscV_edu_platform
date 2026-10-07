library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hazard3_constants.all;

entity hazard3_decode is
    generic (
        RESET_VECTOR        : std_logic_vector(31 downto 0) := x"00000000";
        EXTENSION_A         : boolean := true;
        EXTENSION_C         : boolean := true;
        EXTENSION_E         : boolean := true;
        EXTENSION_M         : boolean := true;
        CSR_M_MANDATORY     : boolean := true;
        CSR_M_TRAP          : boolean := true;
        CSR_COUNTER         : boolean := false;
        U_MODE               : boolean := false;
        DEBUG_SUPPORT       : boolean := false;
        BRANCH_PREDICTOR    : boolean := false;
        W_REGADDR           : positive := 5;
        W_ALUOP             : positive := 6;
        W_ALUSRC            : positive := 1;
        W_MEMOP             : positive := 5;
        W_BCOND             : positive := 2;
        W_EXCEPT            : positive := 4;
    );
    port (
        clk, rst_n                    : in std_logic;
        fd_cir                        : in std_logic_vector(31 downto 0);
        fd_cir_err, fd_cir_predbranch : in std_logic_vector(1 downto 0);
        fd_cir_vld                    : in std_logic_vector(1 downto 0);
        fd_cir_is_32bit, fd_cir_invalid_16bit, fd_cir_is_uop : in std_logic;
        fd_cir_uop_nonfinal, fd_cir_uop_no_pc_update, fd_cir_uop_atomic : in std_logic;
        df_cir_use                    : out std_logic_vector(1 downto 0);
        df_cir_flush_behind           : out std_logic;
        df_uop_stall, df_uop_clear, df_lspair_phase_next : out std_logic;
        d_pc                          : out std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        debug_mode, m_mode, trap_wfi  : in std_logic;
        debug_dpc_wdata               : in std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        debug_dpc_wen                 : in std_logic;
        debug_dpc_rdata               : out std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        d_starved                     : out std_logic;
        x_stall, f_jump_now, x_jump_not_except : in std_logic;
        f_jump_target, d_btb_target_addr : in std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        d_imm                         : out std_logic_vector(DATA_WIDTH_C-1 downto 0);
        d_rs1, d_rs2, d_rd            : out std_logic_vector(W_REGADDR-1 downto 0);
        d_funct3_32b                  : out std_logic_vector(2 downto 0);
        d_funct7_32b                  : out std_logic_vector(6 downto 0);
        d_alusrc_a, d_alusrc_b        : out std_logic_vector(W_ALUSRC-1 downto 0);
        d_aluop                       : out std_logic_vector(W_ALUOP-1 downto 0);
        d_memop                       : out std_logic_vector(W_MEMOP-1 downto 0);
        d_mulop                       : out std_logic_vector(MULOP_WIDTH_C-1 downto 0);
        d_csr_ren, d_csr_wen          : out std_logic;
        d_csr_wtype                   : out std_logic_vector(1 downto 0);
        d_csr_w_imm                   : out std_logic;
        d_branchcond                  : out std_logic_vector(W_BCOND-1 downto 0);
        d_addr_offs                   : out std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        d_addr_is_regoffs             : out std_logic;
        d_except                      : out std_logic_vector(W_EXCEPT-1 downto 0);
        d_sleep_wfi, d_sleep_block, d_sleep_unblock : out std_logic;
        d_no_pc_increment, d_uninterruptible : out std_logic;
        d_lspair_offset               : out std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        d_fence_i, d_fence_d          : out std_logic
    );
end entity;

architecture rtl of hazard3_decode is
    signal pc, pc_next, pc_inc : std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
    signal cir_lock_prev : std_logic := '0';
    signal cir_lock : std_logic;
    signal d_instr : std_logic_vector(31 downto 0);
    signal d_invalid_32bit, d_invalid, d_except_bus : std_logic;
    signal d_stall, partial_predicted_branch, predicted_branch : std_logic;
    signal d_imm_i, d_imm_s, d_imm_b, d_imm_u, d_imm_j : std_logic_vector(31 downto 0);
    function zext(v : std_logic_vector; n : natural) return std_logic_vector is
        variable r : std_logic_vector(n-1 downto 0) := (others => '0');
    begin r(v'length-1 downto 0) := v; return r; end;
begin
    d_instr <= fd_cir when EXTENSION_C else fd_cir(31 downto 2) & "11";
    d_imm_i <= (31 downto 11 => d_instr(31)) & d_instr(30 downto 20);
    d_imm_s <= (31 downto 11 => d_instr(31)) & d_instr(30 downto 25) & d_instr(11 downto 7);
    d_imm_b <= (31 downto 12 => d_instr(31)) & d_instr(7) & d_instr(30 downto 25) &
               d_instr(11 downto 8) & '0';
    d_imm_u <= d_instr(31 downto 12) & (11 downto 0 => '0');
    d_imm_j <= (31 downto 20 => d_instr(31)) & d_instr(19 downto 12) & d_instr(20) &
               d_instr(30 downto 21) & '0';
    d_starved <= (not (fd_cir_vld(0) or fd_cir_vld(1))) or
                 (fd_cir_vld(0) and fd_cir_is_32bit);
    d_stall <= x_stall or d_starved or fd_cir_uop_nonfinal;
    d_except_bus <= ((fd_cir_vld(0) or fd_cir_vld(1)) and fd_cir_err(0)) or
                    (fd_cir_vld(1) and fd_cir_is_32bit and fd_cir_err(1));
    d_invalid <= fd_cir_invalid_16bit or d_invalid_32bit;
    partial_predicted_branch <= '0' when not BRANCH_PREDICTOR else
                                (not d_starved) and fd_cir_is_32bit and
                                (fd_cir_predbranch(0) xor fd_cir_predbranch(1));
    predicted_branch <= '0' when not BRANCH_PREDICTOR else fd_cir_predbranch(0);
    df_uop_stall <= x_stall or d_starved;
    df_uop_clear <= f_jump_now and not df_cir_flush_behind;
    df_cir_use <= "00" when d_stall or d_starved else "10" when fd_cir_is_32bit = '1' else "01";
    df_cir_flush_behind <= (f_jump_now and x_jump_not_except and d_stall) and not cir_lock_prev;
    df_lspair_phase_next <= '0';
    d_lspair_offset <= (others => '0');
    d_no_pc_increment <= fd_cir_uop_nonfinal;
    d_uninterruptible <= '0';
    d_pc <= pc; debug_dpc_rdata <= pc;
    pc_inc <= std_logic_vector(unsigned(pc) + 4) when fd_cir_is_32bit = '1' else
              std_logic_vector(unsigned(pc) + 2);
    cir_lock <= (cir_lock_prev and not ((not d_stall) or
                 (f_jump_now and not x_jump_not_except))) or
                (f_jump_now and x_jump_not_except and d_stall);
    process(clk, rst_n)
    begin
        if rst_n = '0' then pc <= RESET_VECTOR(ADDRESS_WIDTH_C-1 downto 0); cir_lock_prev <= '0';
        elsif rising_edge(clk) then
            if debug_dpc_wen = '1' then
                pc <= debug_dpc_wdata;
            elsif debug_mode = '1' then
                null;
            elsif f_jump_now = '1' and not
                (f_jump_now = '1' and x_jump_not_except = '1' and d_stall = '1' and
                 not (fd_cir_is_uop = '1' and fd_cir_uop_no_pc_update = '0' and x_stall = '0')) then
                pc <= f_jump_target;
            elsif cir_lock_prev = '1' and d_stall = '0' and
                fd_cir_uop_no_pc_update = '0' then
                pc <= f_jump_target;
            elsif f_jump_now = '0' and fd_cir_uop_nonfinal = '1' and
                fd_cir_uop_no_pc_update = '0' and x_stall = '0' then
                pc <= f_jump_target;
            elsif d_stall = '0' and cir_lock = '0' then
                pc <= d_btb_target_addr when predicted_branch = '1' else pc_inc;
            end if;
            cir_lock_prev <=
            ((cir_lock_prev and not (not d_stall or (f_jump_now and not x_jump_not_except))) or
             (f_jump_now and x_jump_not_except and d_stall));
        end if;
    end process;

    process(all)
        variable rs1, rs2, rd : std_logic_vector(W_REGADDR-1 downto 0);
        variable imm : std_logic_vector(DATA_WIDTH_C-1 downto 0);
        variable alu : std_logic_vector(W_ALUOP-1 downto 0);
        variable mem : std_logic_vector(W_MEMOP-1 downto 0);
        variable mul : std_logic_vector(MULOP_WIDTH_C-1 downto 0);
        variable csr_wtype : std_logic_vector(1 downto 0);
        variable branch : std_logic_vector(W_BCOND-1 downto 0);
        variable ex : std_logic_vector(W_EXCEPT-1 downto 0);
        variable aoff : std_logic_vector(ADDRESS_WIDTH_C-1 downto 0);
        variable srca, srcb, regoff, csr_r, csr_w, csr_i, wfi, fence, fence_i : std_logic;
        variable invalid_now : std_logic;
    begin
        rs1 := d_instr(19 downto 15); rs2 := d_instr(24 downto 20); rd := d_instr(11 downto 7);
        mul := (others => '0'); csr_wtype := "00";
        imm := zext(d_imm_i, DATA_WIDTH_C); alu := ALUOP_C.ADD; mem := std_logic_vector(to_unsigned(16, W_MEMOP));
        branch := std_logic_vector(to_unsigned(0, W_BCOND)); ex := std_logic_vector(to_unsigned(15, W_EXCEPT));
        aoff := (others => 'X'); srca := '0'; srcb := '0'; regoff := '0';
        csr_r := '0'; csr_w := '0'; csr_i := '0'; wfi := '0'; fence := '0'; fence_i := '0'; invalid_now := '0';
        d_funct3_32b <= fd_cir(14 downto 12); d_funct7_32b <= fd_cir(31 downto 25);
        if std_match(d_instr, OPCODE_C.BEQ) then rd := (others=>'0'); alu := ALUOP_C.SUB; branch := "10";
        elsif std_match(d_instr, OPCODE_C.BNE) then rd := (others=>'0'); alu := ALUOP_C.SUB; branch := "11";
        elsif std_match(d_instr, OPCODE_C.BLT) then rd := (others=>'0'); alu := ALUOP_C.LT; branch := "11";
        elsif std_match(d_instr, OPCODE_C.BGE) then rd := (others=>'0'); alu := ALUOP_C.LT; branch := "10";
        elsif std_match(d_instr, OPCODE_C.BLTU) then rd := (others=>'0'); alu := ALUOP_C.LTU; branch := "11";
        elsif std_match(d_instr, OPCODE_C.BGEU) then rd := (others=>'0'); alu := ALUOP_C.LTU; branch := "10";
        elsif std_match(d_instr, OPCODE_C.JALR) then branch := "01"; regoff := '1'; rs2 := (others=>'0'); srca := '1'; srcb := '1'; if fd_cir_is_32bit='1' then imm := zext(x"00000004", DATA_WIDTH_C); else imm := zext(x"00000002", DATA_WIDTH_C); end if;
        elsif std_match(d_instr, OPCODE_C.JAL) then branch := "01"; rs1 := (others=>'0'); rs2 := (others=>'0'); srca := '1'; srcb := '1'; if fd_cir_is_32bit='1' then imm := zext(x"00000004", DATA_WIDTH_C); else imm := zext(x"00000002", DATA_WIDTH_C); end if;
        elsif std_match(d_instr, OPCODE_C.LUI) then alu := ALUOP_C.RS2; imm := zext(d_imm_u,DATA_WIDTH_C); srcb := '1'; rs1 := (others=>'0'); rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.AUIPC) then imm := zext(d_imm_u,DATA_WIDTH_C); srca := '1'; srcb := '1'; rs1 := (others=>'0'); rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.ADDI) then srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SLLI) then alu := ALUOP_C.SLL_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SLTI) then alu := ALUOP_C.LT; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SLTIU) then alu := ALUOP_C.LTU; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.XORI) then alu := ALUOP_C.XOR_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SRLI) then alu := ALUOP_C.SRL_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SRAI) then alu := ALUOP_C.SRA_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.ORI) then alu := ALUOP_C.OR_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.ANDI) then alu := ALUOP_C.AND_OP; srcb := '1'; rs2 := (others=>'0');
        elsif std_match(d_instr, OPCODE_C.SUB) then alu := ALUOP_C.SUB;
        elsif std_match(d_instr, OPCODE_C.SLL32) then alu := ALUOP_C.SLL_OP;
        elsif std_match(d_instr, OPCODE_C.SLT) then alu := ALUOP_C.LT;
        elsif std_match(d_instr, OPCODE_C.SLTU) then alu := ALUOP_C.LTU;
        elsif std_match(d_instr, OPCODE_C.XOR_OP) then alu := ALUOP_C.XOR_OP;
        elsif std_match(d_instr, OPCODE_C.SRL32) then alu := ALUOP_C.SRL_OP;
        elsif std_match(d_instr, OPCODE_C.SRA32) then alu := ALUOP_C.SRA_OP;
        elsif std_match(d_instr, OPCODE_C.OR_OP) then alu := ALUOP_C.OR_OP;
        elsif std_match(d_instr, OPCODE_C.AND_OP) then alu := ALUOP_C.AND_OP;
        elsif std_match(d_instr, OPCODE_C.LW) then regoff := '1'; rs2 := (others=>'0'); mem := std_logic_vector(to_unsigned(0,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.LH) then regoff := '1'; rs2 := (others=>'0'); mem := std_logic_vector(to_unsigned(1,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.LB) then regoff := '1'; rs2 := (others=>'0'); mem := std_logic_vector(to_unsigned(2,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.LBU) then regoff := '1'; rs2 := (others=>'0'); mem := std_logic_vector(to_unsigned(4,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.LHU) then regoff := '1'; rs2 := (others=>'0'); mem := std_logic_vector(to_unsigned(3,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.SW) then regoff := '1'; alu := ALUOP_C.RS2; rd := (others=>'0'); mem := std_logic_vector(to_unsigned(5,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.SH) then regoff := '1'; alu := ALUOP_C.RS2; rd := (others=>'0'); mem := std_logic_vector(to_unsigned(6,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.SB) then regoff := '1'; alu := ALUOP_C.RS2; rd := (others=>'0'); mem := std_logic_vector(to_unsigned(7,W_MEMOP));
        elsif std_match(d_instr, OPCODE_C.MUL) or std_match(d_instr, OPCODE_C.MULH) or
              std_match(d_instr, OPCODE_C.MULHSU) or std_match(d_instr, OPCODE_C.MULHU) or
              std_match(d_instr, OPCODE_C.DIV) or std_match(d_instr, OPCODE_C.DIVU) or
              std_match(d_instr, OPCODE_C.REM_OP) or std_match(d_instr, OPCODE_C.REMU) then
            if EXTENSION_M then
                alu := ALUOP_C.MULDIV;
                if std_match(d_instr, OPCODE_C.MUL) then mul := MULOP_C.MUL;
                elsif std_match(d_instr, OPCODE_C.MULH) then mul := MULOP_C.MULH;
                elsif std_match(d_instr, OPCODE_C.MULHSU) then mul := MULOP_C.MULHSU;
                elsif std_match(d_instr, OPCODE_C.MULHU) then mul := MULOP_C.MULHU;
                elsif std_match(d_instr, OPCODE_C.DIV) then mul := MULOP_C.DIV;
                elsif std_match(d_instr, OPCODE_C.DIVU) then mul := MULOP_C.DIVU;
                elsif std_match(d_instr, OPCODE_C.REM_OP) then mul := MULOP_C.REMI;
                else mul := MULOP_C.REMIU; end if;
            else invalid_now := '1'; end if;
        elsif fd_cir_is_32bit = '1' and (std_match(d_instr, OPCODE_C.LR_W) or std_match(d_instr, OPCODE_C.SC_W) or
              std_match(d_instr, OPCODE_C.AMOSWAP_W) or std_match(d_instr, OPCODE_C.AMOADD_W) or
              std_match(d_instr, OPCODE_C.AMOXOR_W) or std_match(d_instr, OPCODE_C.AMOAND_W) or
              std_match(d_instr, OPCODE_C.AMOOR_W) or std_match(d_instr, OPCODE_C.AMOMIN_W) or
              std_match(d_instr, OPCODE_C.AMOMAX_W) or std_match(d_instr, OPCODE_C.AMOMINU_W) or
              std_match(d_instr, OPCODE_C.AMOMAXU_W)) then
            if EXTENSION_A then
                regoff := '1'; mem := std_logic_vector(to_unsigned(10,W_MEMOP));
                if std_match(d_instr, OPCODE_C.LR_W) then mem := std_logic_vector(to_unsigned(8,W_MEMOP)); rs2 := (others=>'0');
                elsif std_match(d_instr, OPCODE_C.SC_W) then mem := std_logic_vector(to_unsigned(9,W_MEMOP)); alu := ALUOP_C.RS2;
                elsif std_match(d_instr, OPCODE_C.AMOSWAP_W) then alu := ALUOP_C.RS2;
                elsif std_match(d_instr, OPCODE_C.AMOADD_W) then alu := ALUOP_C.ADD;
                elsif std_match(d_instr, OPCODE_C.AMOXOR_W) then alu := ALUOP_C.XOR_OP;
                elsif std_match(d_instr, OPCODE_C.AMOAND_W) then alu := ALUOP_C.AND_OP;
                elsif std_match(d_instr, OPCODE_C.AMOOR_W) then alu := ALUOP_C.OR_OP;
                elsif std_match(d_instr, OPCODE_C.AMOMIN_W) then alu := ALUOP_C.MIN;
                elsif std_match(d_instr, OPCODE_C.AMOMAX_W) then alu := ALUOP_C.MAX;
                elsif std_match(d_instr, OPCODE_C.AMOMINU_W) then alu := ALUOP_C.MINU;
                else alu := ALUOP_C.MAXU; end if;
            else invalid_now := '1'; end if;
        elsif std_match(d_instr, OPCODE_C.CSRRW) or std_match(d_instr, OPCODE_C.CSRRS) or
              std_match(d_instr, OPCODE_C.CSRRC) or std_match(d_instr, OPCODE_C.CSRRWI) or
              std_match(d_instr, OPCODE_C.CSRRSI) or std_match(d_instr, OPCODE_C.CSRRCI) then
            if CSR_M_MANDATORY or CSR_M_TRAP or CSR_COUNTER then
                rs2 := (others=>'0'); imm := zext(d_imm_i,DATA_WIDTH_C); csr_r := '1'; csr_w := '1';
                if std_match(d_instr, OPCODE_C.CSRRW) or std_match(d_instr, OPCODE_C.CSRRWI) then
                    csr_r := '0' when rd = (rd'range => '0') else '1'; csr_wtype := "00";
                elsif std_match(d_instr, OPCODE_C.CSRRS) or std_match(d_instr, OPCODE_C.CSRRSI) then
                    csr_w := '0' when rs1 = (rs1'range => '0') else '1'; csr_wtype := "01";
                else
                    csr_w := '0' when rs1 = (rs1'range => '0') else '1'; csr_wtype := "10";
                end if;
                csr_i := '1' when std_match(d_instr, OPCODE_C.CSRRWI) or
                    std_match(d_instr, OPCODE_C.CSRRSI) or std_match(d_instr, OPCODE_C.CSRRCI) else '0';
            else invalid_now := '1'; end if;
        elsif d_instr(6 downto 0) = "0001111" then fence := '1';
        elsif std_match(d_instr, OPCODE_C.FENCE_I) then fence_i := '1';
        elsif d_instr = OPCODE_C.ECALL then
            if CSR_M_MANDATORY or CSR_M_TRAP or CSR_COUNTER then
                if m_mode='1' or not U_MODE then ex := x"B"; else ex := x"8"; end if;
                rs1 := (others=>'0'); rs2 := (others=>'0'); rd := (others=>'0');
            else invalid_now := '1'; end if;
        elsif d_instr = OPCODE_C.EBREAK then ex := std_logic_vector(to_unsigned(3,W_EXCEPT)); rs1 := (others=>'0'); rs2 := (others=>'0'); rd := (others=>'0');
        elsif d_instr = OPCODE_C.MRET then if CSR_M_MANDATORY or CSR_M_TRAP then if m_mode='1' then ex := x"A"; else invalid_now := '1'; end if; else invalid_now := '1'; end if;
        elsif d_instr = OPCODE_C.WFI then if (CSR_M_MANDATORY or CSR_M_TRAP) and trap_wfi='0' then wfi := '1'; else invalid_now := '1'; end if;
        else invalid_now := '1';
        end if;
        if d_instr(6 downto 0) = "0101111" and
           d_instr(31 downto 27) /= "00000" and d_instr(31 downto 27) /= "00001" and
           d_instr(31 downto 27) /= "00010" and d_instr(31 downto 27) /= "00011" and
           d_instr(31 downto 27) /= "00100" and d_instr(31 downto 27) /= "01000" and
           d_instr(31 downto 27) /= "01100" and d_instr(31 downto 27) /= "10000" and
           d_instr(31 downto 27) /= "10100" and d_instr(31 downto 27) /= "11000" and
           d_instr(31 downto 27) /= "11100" then
            invalid_now := '1'; regoff := '0';
        end if;
        if std_match(d_instr, OPCODE_C.JAL) then
            aoff := zext(d_imm_j, ADDRESS_WIDTH_C);
        elsif d_instr(6 downto 0) = "1100011" or
              std_match(d_instr, OPCODE_C.BEQ) or std_match(d_instr, OPCODE_C.BNE) or
              std_match(d_instr, OPCODE_C.BLT) or std_match(d_instr, OPCODE_C.BGE) or
              std_match(d_instr, OPCODE_C.BLTU) or std_match(d_instr, OPCODE_C.BGEU) then
            if predicted_branch='1' then
                if fd_cir_is_32bit='1' then aoff := std_logic_vector(to_unsigned(4,ADDRESS_WIDTH_C));
                else aoff := std_logic_vector(to_unsigned(2,ADDRESS_WIDTH_C)); end if;
            else aoff := zext(d_imm_b,ADDRESS_WIDTH_C); end if;
        elsif std_match(d_instr, OPCODE_C.SB) or std_match(d_instr, OPCODE_C.SH) or
              std_match(d_instr, OPCODE_C.SW) or std_match(d_instr, OPCODE_C.LB) or
              std_match(d_instr, OPCODE_C.LH) or std_match(d_instr, OPCODE_C.LW) or
              std_match(d_instr, OPCODE_C.LBU) or std_match(d_instr, OPCODE_C.LHU) or
              std_match(d_instr, OPCODE_C.JALR) then
            if std_match(d_instr, OPCODE_C.SB) or std_match(d_instr, OPCODE_C.SH) or
               std_match(d_instr, OPCODE_C.SW) then aoff := zext(d_imm_s,ADDRESS_WIDTH_C);
            else aoff := zext(d_imm_i,ADDRESS_WIDTH_C); end if;
        elsif fd_cir_is_32bit = '1' and (std_match(d_instr, OPCODE_C.AMOSWAP_W) or std_match(d_instr, OPCODE_C.AMOADD_W) or
              std_match(d_instr, OPCODE_C.AMOXOR_W) or std_match(d_instr, OPCODE_C.AMOAND_W) or
              std_match(d_instr, OPCODE_C.AMOOR_W) or std_match(d_instr, OPCODE_C.AMOMIN_W) or
              std_match(d_instr, OPCODE_C.AMOMAX_W) or std_match(d_instr, OPCODE_C.AMOMINU_W) or
              std_match(d_instr, OPCODE_C.AMOMAXU_W) or std_match(d_instr, OPCODE_C.LR_W) or
              std_match(d_instr, OPCODE_C.SC_W)) then
            aoff := (others => '0');
        end if;
        if partial_predicted_branch='1' then aoff := (others => '0'); end if;
        if EXTENSION_E and (rd(4)='1' or rs1(4)='1' or rs2(4)='1') then invalid_now := '1'; end if;
        d_invalid_32bit <= invalid_now;
        if invalid_now='1' or fd_cir_invalid_16bit='1' or d_starved='1' or d_except_bus='1' or partial_predicted_branch='1' then
            rs1 := (others=>'0'); rs2 := (others=>'0'); rd := (others=>'0'); mem := std_logic_vector(to_unsigned(16,W_MEMOP)); branch := (others=>'0'); csr_r := '0'; csr_w := '0'; ex := (others=>'1'); wfi := '0'; fence := '0';
            if EXTENSION_M then alu := ALUOP_C.ADD; end if;
            if d_except_bus='1' then ex := std_logic_vector(to_unsigned(1,W_EXCEPT)); elsif (invalid_now='1' or fd_cir_invalid_16bit='1') and d_starved='0' then ex := std_logic_vector(to_unsigned(2,W_EXCEPT)); end if;
        end if;
        if partial_predicted_branch='1' then branch := "01"; end if;
        if cir_lock_prev='1' then branch := (others => '0'); end if;
        d_rs1 <= rs1; d_rs2 <= rs2; d_rd <= rd; d_imm <= imm; d_aluop <= alu; d_memop <= mem; d_mulop <= mul;
        d_alusrc_a <= (others=>'0'); d_alusrc_a(0) <= srca; d_alusrc_b <= (others=>'0'); d_alusrc_b(0) <= srcb;
        d_branchcond <= branch; d_addr_is_regoffs <= regoff; d_except <= ex; d_csr_ren <= csr_r; d_csr_wen <= csr_w; d_csr_w_imm <= csr_i; d_csr_wtype <= csr_wtype;
        d_sleep_wfi <= wfi; d_sleep_block <= '0'; d_sleep_unblock <= '0'; d_fence_i <= fence_i; d_fence_d <= fence;
        d_addr_offs <= aoff;
    end process;
end architecture;
