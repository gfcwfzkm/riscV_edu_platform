library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package hazard3_constants is

    -- ========================================================================
    -- Top Level Constants 
    -- ========================================================================

    constant DATA_WIDTH_C               : integer := 32;
    constant ADDRESS_WIDTH_C            : integer := 32;
    constant ALUOP_WIDTH_C              : integer := 6;
    constant SHIFT_AMOUNT_WIDTH_C       : integer := 5;
    constant MULOP_WIDTH_C              : integer := 3;
    constant COMPRESSED_INSTR_WIDTH_C   : integer := 16;
    constant INSTRUCTION_WIDTH_C        : integer := 32;
    constant REGISTER_ADDRESS_WIDTH_C   : integer := 5;
    constant BRANCH_CONDITION_WIDTH_C   : integer := 2;
    constant EXCEPTION_WIDTH_C          : integer := 4;
    constant ALU_SOURCE_WIDTH_C         : integer := 1;
    constant MEMOP_WIDTH_C              : integer := 5;
    constant MAX_NUMBER_OF_IRQ_C        : integer := 512;
    constant CSR_ADDRESS_WIDTH_C        : integer := 12;
    constant MTVEC_WRITE_MASK_C         : std_logic_vector(ADDRESS_WIDTH_C - 1 downto 0) := x"FFFF_FFFF";

    -- ========================================================================
    -- Record Type Declarations (Nested Hierarchy)
    -- ========================================================================

    type alu_operations_t is record
        ADD     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SUB     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        LT      : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        LTU     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        AND_OP  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        OR_OP   : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        XOR_OP  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SRL_OP  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SRA_OP  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SLL_OP  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        MULDIV  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        RS2     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SHXADD  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        CLZ     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        CPOP    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        CTZ     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ANDN    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ORN     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        XNOR_OP : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        MAX     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        MAXU    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        MIN     : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        MINU    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ORC_B   : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        REV8    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ROTL    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ROTR    : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SEXT_B  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        SEXT_H  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        ZEXT_H  : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
        CLMUL   : std_logic_vector(ALUOP_WIDTH_C - 1 downto 0);
    end record;

    type mul_operations_t is record
        MUL    : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        MULH   : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        MULHSU : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        MULHU  : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        DIV    : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        DIVU   : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        REMI   : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
        REMIU  : std_logic_vector(MULOP_WIDTH_C - 1 downto 0);
    end record;

    type opcode_constants_t is record
        C_ADDI4SPN : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_LW       : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SW       : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_ADDI     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_JAL      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_J        : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_LI       : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_LUI      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SRLI     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SRAI     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_ANDI     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SUB      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_XOR      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_OR       : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_AND      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_BEQZ     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_BNEZ     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SLLI     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_MV       : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_ADD      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_LWSP     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_SWSP     : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        C_MUL      : std_logic_vector(COMPRESSED_INSTR_WIDTH_C - 1 downto 0);
        ADDI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        JALR       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        JAL        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LUI        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLLI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SRLI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SRAI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        ANDI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        ADD        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SUB        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AND_OP     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        OR_OP      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        XOR_OP     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LW         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SW         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        MUL        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BEQ        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BNE        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BLT        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BGE        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BLTU       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        BGEU       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AUIPC      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLTI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLTIU      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        XORI       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        ORI        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLL32      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLT        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SLTU       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SRL32      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SRA32      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LB         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LH         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LBU        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LHU        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SB         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SH         : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        LR_W       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        SC_W       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMO        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRW      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRS      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRC      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRWI     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRSI     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        CSRRCI     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        FENCE      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        ECALL      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        MRET       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        WFI        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        FENCE_I    : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        EBREAK     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        MULH       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        MULHSU     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        MULHU      : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        DIV        : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        DIVU       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        REM_OP     : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        REMU       : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOSWAP_W  : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOADD_W   : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOXOR_W   : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOAND_W   : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOOR_W    : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOMIN_W   : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOMAX_W   : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOMINU_W  : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
        AMOMAXU_W  : std_logic_vector(INSTRUCTION_WIDTH_C - 1 downto 0);
    end record;

    type exception_constants_t is record
        NO_EXCEPTION                    : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        INSTRUCTION_MISALIGNED          : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        INSTRUCTION_FAULT               : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        ILLEGAL_INSTRUCTION             : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        EBREAKPOINT                     : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        LOAD_ADDRESS_MISALIGNED         : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        LOAD_ACCESS_FAULT               : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        STORE_ADDRESS_MISALIGNED        : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        STORE_ACCESS_FAULT              : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        ENVIRONMENT_CALL_FROM_U_MODE    : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        RETURN_FROM_M_MODE              : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        ENVIRONMENT_CALL_FROM_M_MODE    : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
        EXCEPTION_REFETCH               : std_logic_vector(EXCEPTION_WIDTH_C - 1 downto 0);
    end record;

    type memory_operation_constants_t is record
        LOAD_WORD               : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        LOAD_HALF               : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        LOAD_BYTE               : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        LOAD_HALF_UNSIGNED      : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        LOAD_BYTE_UNSIGNED      : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        STORE_WORD              : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        STORE_HALF              : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        STORE_BYTE              : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        LOAD_RESERVED_WORD      : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        STORE_CONDITIONAL_WORD  : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        ATOMIC_MEM_OP           : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
        NONE                    : std_logic_vector(MEMOP_WIDTH_C - 1 downto 0);
    end record;

    type branch_conditions_t is record
        NEVER       : std_logic_vector(BRANCH_CONDITION_WIDTH_C - 1 downto 0);
        ALWAYS      : std_logic_vector(BRANCH_CONDITION_WIDTH_C - 1 downto 0);
        ZERO        : std_logic_vector(BRANCH_CONDITION_WIDTH_C - 1 downto 0);
        NOT_ZERO    : std_logic_vector(BRANCH_CONDITION_WIDTH_C - 1 downto 0);
    end record;

    type alu_source_a is record
        RS1 : std_logic_vector(ALU_SOURCE_WIDTH_C - 1 downto 0);
        PC  : std_logic_vector(ALU_SOURCE_WIDTH_C - 1 downto 0);
    end record;

    type alu_source_b is record
        RS2 : std_logic_vector(ALU_SOURCE_WIDTH_C - 1 downto 0);
        IMM : std_logic_vector(ALU_SOURCE_WIDTH_C - 1 downto 0);
    end record;

    type csr_access_types_t is record
        W : std_logic_vector(1 downto 0);
        S : std_logic_vector(1 downto 0);
        C : std_logic_vector(1 downto 0);
    end record;

    -- Machine Information Registers (Read-Only)
    type addresses_csr_machine_info_t is record
        MVENDORID   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Vendor ID
        MARCHID     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Architecture ID
        MIMPID      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Implementation ID
        MHARTID     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Hardware thread ID
        MCONFIGPTR  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Pointer to configuration data structures
    end record;

    -- Machine Trap Setup (Read/Write)
    type addresses_csr_machine_trap_setup_t is record
        MSTATUS     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine status register
        MSTATUSH    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- As of priv-1.12 this must be present even if tied 0
        MISA        : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- ISA and extensions
        MEDELEG     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine exception delegation register
        MIDELEG     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine interrupt delegation register
        MIE         : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine interrupt-enable register
        MTVEC       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine trap-handler base address
        MCOUNTEREN  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine counter enable
    end record;

    -- Machine Trap Handling (Read/Write)
    type addresses_csr_machine_trap_handling_t is record
        MSCRATCH    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Scratch register for machine trap handlers
        MEPC        : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine exception program counter
        MCAUSE      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine trap cause
        MTVAL       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine bad address or instruction
        MIP         : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Machine interrupt pending
    end record;

    -- Machine Memory Protection (Read/Write)
    type addresses_csr_machine_memory_protection_t is record
        PMPCFG0     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection configuration
        PMPCFG1     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection configuration, RV32 only
        PMPCFG2     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection configuration
        PMPCFG3     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection configuration, RV32 only
        PMPADDR0    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR1    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR2    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR3    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR4    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR5    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR6    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR7    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR8    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR9    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR10   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR11   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR12   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR13   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR14   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        PMPADDR15   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Physical memory protection address register
        MSECCFG     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MSECCFGH    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
    end record;

    -- Performance Counters (Read/Write)
    type addresses_csr_performance_counters_t is record
        MCYCLE          : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Raw cycles since start of day
        MINSTRET        : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Instruction retire count since start of day
        MHPMCOUNTER3    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER4    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER5    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER6    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER7    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER8    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER9    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER10   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER11   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER12   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER13   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER14   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER15   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER16   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER17   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER18   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER19   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER20   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER21   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER22   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER23   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER24   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER25   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER26   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER27   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER28   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER29   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER30   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMCOUNTER31   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MCYCLEH         : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- High halves of each counter
        MINSTRETH       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER3H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER4H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER5H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER6H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER7H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER8H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER9H   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER10H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER11H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER12H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER13H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER14H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER15H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER16H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER17H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER18H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER19H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER20H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER21H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER22H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER23H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER24H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER25H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER26H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER27H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER28H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER29H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER30H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MHPMCOUNTER31H  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MCOUNTINHIBIT   : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Count inhibit register for mcycle/minstret
        MHPMEVENT3      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT4      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT5      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT6      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT7      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT8      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT9      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT10     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT11     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT12     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT13     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT14     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT15     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT16     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT17     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT18     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT19     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT20     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT21     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT22     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT23     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT24     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT25     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT26     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT27     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT28     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT29     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT30     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
        MHPMEVENT31     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- WARL (we tie to 0)
    end record;

    -- Other Standard M-Mode CSRs
    type addresses_csr_other_standard_m_mode_t is record
        MENVCFG     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MENVCFGH    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
    end record;

    -- Custom M-Mode CSRs
    type addresses_csr_custom_m_mode_t is record
        PMPCFGM0    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Make PMP regions M-mode without locking
        MEIEA       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- External interrupt pending array
        MEIPA       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- External interrupt enable array
        MEIFA       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- External interrupt force array
        MEIPRA      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- External interrupt priority array
        MEINEXT     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Next external interrupt
        MEICONTEXT  : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- External interrupt context register
        MSLEEP      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- M-mode sleep control register
        H3MISA      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Hazard3 M-mode ISA identification register
    end record;

    -- U-Mode CSRs
    type addresses_csr_u_mode_t is record
        CYCLE       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TIME        : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        INSTRET     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        CYCLEH      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TIMEH       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        INSTRETH    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        SLEEP       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- U-mode subset of M-mode sleep control
    end record;

    -- Trigger Module CSRs
    type addresses_csr_trigger_module_t is record
        TSELECT     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TDATA1      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TDATA2      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TDATA3      : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TINFO       : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        TCONTROL    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        MCONTEXT    : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
    end record;

    -- D-Mode CSRs
    type addresses_csr_d_mode_t is record
        DCSR        : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        DPC         : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);
        DMDATA0     : std_logic_vector(CSR_ADDRESS_WIDTH_C - 1 downto 0);   -- Custom read/write
    end record;

    -- Master CSR Addresses Record Type
    type csr_addresses_t is record
        MACHINE_INFO              : addresses_csr_machine_info_t;               -- Machine Information Registers (Read-Only)
        MACHINE_TRAP_SETUP        : addresses_csr_machine_trap_setup_t;         -- Machine Trap Setup (Read/Write)
        MACHINE_TRAP_HANDLING     : addresses_csr_machine_trap_handling_t;      -- Machine Trap Handling (Read/Write)
        MACHINE_MEMORY_PROTECTION : addresses_csr_machine_memory_protection_t;  -- Machine Memory Protection (Read/Write)
        PERFORMANCE_COUNTERS      : addresses_csr_performance_counters_t;       -- Performance Counters (Read/Write)
        OTHER_STANDARD_M_MODE     : addresses_csr_other_standard_m_mode_t;      -- Other Standard M-Mode CSRs
        CUSTOM_M_MODE             : addresses_csr_custom_m_mode_t;              -- Custom M-Mode CSRs
        U_MODE                    : addresses_csr_u_mode_t;                     -- U-Mode CSRs
        TRIGGER_MODULE            : addresses_csr_trigger_module_t;             -- Trigger Module CSRs
        D_MODE                    : addresses_csr_d_mode_t;                     -- D-Mode CSRs
    end record;

    type mimpid_rtl_t is record
        PRERELEASE : std_logic_vector(0 downto 0);
        MAJOR      : std_logic_vector(3 downto 0);
        MINOR      : std_logic_vector(7 downto 0);
        PATCH      : std_logic_vector(7 downto 0);
    end record;

    -- ========================================================================
    -- Constant Initialization
    -- ========================================================================

    -- MIMPID records the release version. To be updated
    -- manually with every release!
    constant RTL_MIMPID : mimpid_rtl_t  := (
        PRERELEASE => 1d"0",
        MAJOR      => 4d"1",
        MINOR      => 8d"1",
        PATCH      => 8d"1"
    );

    constant ALUOP_C : alu_operations_t := (
        ADD     => 6x"00",
        SUB     => 6x"01",
        LT      => 6x"02",
        LTU     => 6x"04",
        AND_OP  => 6x"06",
        OR_OP   => 6x"07",
        XOR_OP  => 6x"08",
        SRL_OP  => 6x"09",
        SRA_OP  => 6x"0A",
        SLL_OP  => 6x"0B",
        MULDIV  => 6x"0C",
        RS2     => 6x"0D",
        SHXADD  => 6x"20",
        CLZ     => 6x"23",
        CPOP    => 6x"24",
        CTZ     => 6x"25",
        ANDN    => 6x"26",
        ORN     => 6x"27",
        XNOR_OP => 6x"28",
        MAX     => 6x"29",
        MAXU    => 6x"2A",
        MIN     => 6x"2B",
        MINU    => 6x"2C",
        ORC_B   => 6x"2D",
        REV8    => 6x"2E",
        ROTL    => 6x"2F",
        ROTR    => 6x"30",
        SEXT_B  => 6x"31",
        SEXT_H  => 6x"32",
        ZEXT_H  => 6x"33",
        CLMUL   => 6x"34"
    );

    constant MULOP_C : mul_operations_t := (
        MUL    => 3x"0",
        MULH   => 3x"1",
        MULHSU => 3x"2",
        MULHU  => 3x"3",
        DIV    => 3x"4",
        DIVU   => 3x"5",
        REMI   => 3x"6",
        REMIU  => 3x"7"
    );

    constant OPCODE_C : opcode_constants_t := (
        C_ADDI4SPN => "000-----------00",
        C_LW       => "010-----------00",
        C_SW       => "110-----------00",
        C_ADDI     => "000-----------01",
        C_JAL      => "001-----------01",
        C_J        => "101-----------01",
        C_LI       => "010-----------01",
        C_LUI      => "011-----------01",
        C_SRLI     => "100000--------01",
        C_SRAI     => "100001--------01",
        C_ANDI     => "100-10--------01",
        C_SUB      => "100011---00---01",
        C_XOR      => "100011---01---01",
        C_OR       => "100011---10---01",
        C_AND      => "100011---11---01",
        C_BEQZ     => "110-----------01",
        C_BNEZ     => "111-----------01",
        C_SLLI     => "0000----------10",
        C_MV       => "1000----------10",
        C_ADD      => "1001----------10",
        C_LWSP     => "010-----------10",
        C_SWSP     => "110-----------10",
        C_MUL      => "100111---10---01",
        ADDI       => "-----------------000-----0010011",
        JALR       => "-----------------000-----1100111",
        JAL        => "-------------------------1101111",
        LUI        => "-------------------------0110111",
        SLLI       => "0000000----------001-----0010011",
        SRLI       => "0000000----------101-----0010011",
        SRAI       => "0100000----------101-----0010011",
        ANDI       => "-----------------111-----0010011",
        ADD        => "0000000----------000-----0110011",
        SUB        => "0100000----------000-----0110011",
        AND_OP     => "0000000----------111-----0110011",
        OR_OP      => "0000000----------110-----0110011",
        XOR_OP     => "0000000----------100-----0110011",
        LW         => "-----------------010-----0000011",
        SW         => "-----------------010-----0100011",
        BEQ        => "-----------------000-----1100011",
        BNE        => "-----------------001-----1100011",
        MUL        => "0000001----------000-----0110011",
        BLT        => "-----------------100-----1100011",
        BGE        => "-----------------101-----1100011",
        BLTU       => "-----------------110-----1100011",
        BGEU       => "-----------------111-----1100011",
        AUIPC      => "-------------------------0010111",
        SLTI       => "-----------------010-----0010011",
        SLTIU      => "-----------------011-----0010011",
        XORI       => "-----------------100-----0010011",
        ORI        => "-----------------110-----0010011",
        SLL32      => "0000000----------001-----0110011",
        SLT        => "0000000----------010-----0110011",
        SLTU       => "0000000----------011-----0110011",
        SRL32      => "0000000----------101-----0110011",
        SRA32      => "0100000----------101-----0110011",
        LB         => "-----------------000-----0000011",
        LH         => "-----------------001-----0000011",
        LBU        => "-----------------100-----0000011",
        LHU        => "-----------------101-----0000011",
        SB         => "-----------------000-----0100011",
        SH         => "-----------------001-----0100011",
        LR_W       => "00010--00000-----010-----0101111",
        SC_W       => "00011------------010-----0101111",
        AMO        => "-----------------010-----0101111",
        CSRRW      => "-----------------001-----1110011",
        CSRRS      => "-----------------010-----1110011",
        CSRRC      => "-----------------011-----1110011",
        CSRRWI     => "-----------------101-----1110011",
        CSRRSI     => "-----------------110-----1110011",
        CSRRCI     => "-----------------111-----1110011",
        FENCE      => "------------00000000000000001111",
        ECALL      => "00000000000000000000000001110011",
        MRET       => "00110000001000000000000001110011",
        WFI        => "00010000010100000000000001110011",
        FENCE_I    => "00000000000000000001000000001111",
        EBREAK     => "00000000000100000000000001110011",
        MULH       => "0000001----------001-----0110011",
        MULHSU     => "0000001----------010-----0110011",
        MULHU      => "0000001----------011-----0110011",
        DIV        => "0000001----------100-----0110011",
        DIVU       => "0000001----------101-----0110011",
        REM_OP     => "0000001----------110-----0110011",
        REMU       => "0000001----------111-----0110011",
        AMOSWAP_W  => "00001------------010-----0101111",
        AMOADD_W   => "00000------------010-----0101111",
        AMOXOR_W   => "00100------------010-----0101111",
        AMOAND_W   => "01100------------010-----0101111",
        AMOOR_W    => "01000------------010-----0101111",
        AMOMIN_W   => "10000------------010-----0101111",
        AMOMAX_W   => "10100------------010-----0101111",
        AMOMINU_W  => "11000------------010-----0101111",
        AMOMAXU_W  => "11100------------010-----0101111"
    );

    constant EXCEPT_C : exception_constants_t := (
        NO_EXCEPTION                    => x"F",
        INSTRUCTION_MISALIGNED          => x"0",
        INSTRUCTION_FAULT               => x"1",
        ILLEGAL_INSTRUCTION             => x"2",
        EBREAKPOINT                     => x"3",
        LOAD_ADDRESS_MISALIGNED         => x"4",
        LOAD_ACCESS_FAULT               => x"5",
        STORE_ADDRESS_MISALIGNED        => x"6",
        STORE_ACCESS_FAULT              => x"7",
        ENVIRONMENT_CALL_FROM_U_MODE    => x"8",
        RETURN_FROM_M_MODE              => x"A",
        ENVIRONMENT_CALL_FROM_M_MODE    => x"B",
        EXCEPTION_REFETCH               => x"E"
    );

    constant MEMOP_C : memory_operation_constants_t := (
        LOAD_WORD               => 5x"00",
        LOAD_HALF               => 5x"01",
        LOAD_BYTE               => 5x"02",
        LOAD_HALF_UNSIGNED      => 5x"03",
        LOAD_BYTE_UNSIGNED      => 5x"04",
        STORE_WORD              => 5x"05",
        STORE_HALF              => 5x"06",
        STORE_BYTE              => 5x"07",
        LOAD_RESERVED_WORD      => 5x"08",
        STORE_CONDITIONAL_WORD  => 5x"09",
        ATOMIC_MEM_OP           => 5x"0A",
        NONE                    => 5x"10"
    );

    constant BRANCH_C : branch_conditions_t := (
        NEVER       => "00",
        ALWAYS      => "01",
        ZERO        => "10",
        NOT_ZERO    => "11"
    );

    constant ALUSRCA_C : alu_source_a  := (
        RS1 => "0",
        PC  => "1"
    );

    constant ALUSRCB_C : alu_source_b  := (
        RS2 => "0",
        IMM => "1"
    );

    constant CSR_WTYPE : csr_access_types_t := (
        W => "00",
        S => "01",
        C => "10"
    );

    constant CSR_ADDRESSES : csr_addresses_t := (
        MACHINE_INFO => (
            MVENDORID       => 12x"f11",
            MARCHID         => 12x"f12",
            MIMPID          => 12x"f13",
            MHARTID         => 12x"f14",
            MCONFIGPTR      => 12x"f15"
        ),
        MACHINE_TRAP_SETUP => (
            MSTATUS         => 12x"300",
            MSTATUSH        => 12x"310",
            MISA            => 12x"301",
            MEDELEG         => 12x"302",
            MIDELEG         => 12x"303",
            MIE             => 12x"304",
            MTVEC           => 12x"305",
            MCOUNTEREN      => 12x"306"
        ),
        MACHINE_TRAP_HANDLING => (
            MSCRATCH        => 12x"340",
            MEPC            => 12x"341",
            MCAUSE          => 12x"342",
            MTVAL           => 12x"343",
            MIP             => 12x"344"
        ),
        MACHINE_MEMORY_PROTECTION => (
            PMPCFG0         => 12x"3a0",
            PMPCFG1         => 12x"3a1",
            PMPCFG2         => 12x"3a2",
            PMPCFG3         => 12x"3a3",
            PMPADDR0        => 12x"3b0",
            PMPADDR1        => 12x"3b1",
            PMPADDR2        => 12x"3b2",
            PMPADDR3        => 12x"3b3",
            PMPADDR4        => 12x"3b4",
            PMPADDR5        => 12x"3b5",
            PMPADDR6        => 12x"3b6",
            PMPADDR7        => 12x"3b7",
            PMPADDR8        => 12x"3b8",
            PMPADDR9        => 12x"3b9",
            PMPADDR10       => 12x"3ba",
            PMPADDR11       => 12x"3bb",
            PMPADDR12       => 12x"3bc",
            PMPADDR13       => 12x"3bd",
            PMPADDR14       => 12x"3be",
            PMPADDR15       => 12x"3bf",
            MSECCFG         => 12x"747",
            MSECCFGH        => 12x"757"
        ),
        PERFORMANCE_COUNTERS => (
            MCYCLE          => 12x"b00",
            MINSTRET        => 12x"b02",
            MHPMCOUNTER3    => 12x"b03",
            MHPMCOUNTER4    => 12x"b04",
            MHPMCOUNTER5    => 12x"b05",
            MHPMCOUNTER6    => 12x"b06",
            MHPMCOUNTER7    => 12x"b07",
            MHPMCOUNTER8    => 12x"b08",
            MHPMCOUNTER9    => 12x"b09",
            MHPMCOUNTER10   => 12x"b0a",
            MHPMCOUNTER11   => 12x"b0b",
            MHPMCOUNTER12   => 12x"b0c",
            MHPMCOUNTER13   => 12x"b0d",
            MHPMCOUNTER14   => 12x"b0e",
            MHPMCOUNTER15   => 12x"b0f",
            MHPMCOUNTER16   => 12x"b10",
            MHPMCOUNTER17   => 12x"b11",
            MHPMCOUNTER18   => 12x"b12",
            MHPMCOUNTER19   => 12x"b13",
            MHPMCOUNTER20   => 12x"b14",
            MHPMCOUNTER21   => 12x"b15",
            MHPMCOUNTER22   => 12x"b16",
            MHPMCOUNTER23   => 12x"b17",
            MHPMCOUNTER24   => 12x"b18",
            MHPMCOUNTER25   => 12x"b19",
            MHPMCOUNTER26   => 12x"b1a",
            MHPMCOUNTER27   => 12x"b1b",
            MHPMCOUNTER28   => 12x"b1c",
            MHPMCOUNTER29   => 12x"b1d",
            MHPMCOUNTER30   => 12x"b1e",
            MHPMCOUNTER31   => 12x"b1f",
            MCYCLEH         => 12x"b80",
            MINSTRETH       => 12x"b82",
            MHPMCOUNTER3H   => 12x"b83",
            MHPMCOUNTER4H   => 12x"b84",
            MHPMCOUNTER5H   => 12x"b85",
            MHPMCOUNTER6H   => 12x"b86",
            MHPMCOUNTER7H   => 12x"b87",
            MHPMCOUNTER8H   => 12x"b88",
            MHPMCOUNTER9H   => 12x"b89",
            MHPMCOUNTER10H  => 12x"b8a",
            MHPMCOUNTER11H  => 12x"b8b",
            MHPMCOUNTER12H  => 12x"b8c",
            MHPMCOUNTER13H  => 12x"b8d",
            MHPMCOUNTER14H  => 12x"b8e",
            MHPMCOUNTER15H  => 12x"b8f",
            MHPMCOUNTER16H  => 12x"b90",
            MHPMCOUNTER17H  => 12x"b91",
            MHPMCOUNTER18H  => 12x"b92",
            MHPMCOUNTER19H  => 12x"b93",
            MHPMCOUNTER20H  => 12x"b94",
            MHPMCOUNTER21H  => 12x"b95",
            MHPMCOUNTER22H  => 12x"b96",
            MHPMCOUNTER23H  => 12x"b97",
            MHPMCOUNTER24H  => 12x"b98",
            MHPMCOUNTER25H  => 12x"b99",
            MHPMCOUNTER26H  => 12x"b9a",
            MHPMCOUNTER27H  => 12x"b9b",
            MHPMCOUNTER28H  => 12x"b9c",
            MHPMCOUNTER29H  => 12x"b9d",
            MHPMCOUNTER30H  => 12x"b9e",
            MHPMCOUNTER31H  => 12x"b9f",
            MCOUNTINHIBIT   => 12x"320",
            MHPMEVENT3      => 12x"323",
            MHPMEVENT4      => 12x"324",
            MHPMEVENT5      => 12x"325",
            MHPMEVENT6      => 12x"326",
            MHPMEVENT7      => 12x"327",
            MHPMEVENT8      => 12x"328",
            MHPMEVENT9      => 12x"329",
            MHPMEVENT10     => 12x"32a",
            MHPMEVENT11     => 12x"32b",
            MHPMEVENT12     => 12x"32c",
            MHPMEVENT13     => 12x"32d",
            MHPMEVENT14     => 12x"32e",
            MHPMEVENT15     => 12x"32f",
            MHPMEVENT16     => 12x"330",
            MHPMEVENT17     => 12x"331",
            MHPMEVENT18     => 12x"332",
            MHPMEVENT19     => 12x"333",
            MHPMEVENT20     => 12x"334",
            MHPMEVENT21     => 12x"335",
            MHPMEVENT22     => 12x"336",
            MHPMEVENT23     => 12x"337",
            MHPMEVENT24     => 12x"338",
            MHPMEVENT25     => 12x"339",
            MHPMEVENT26     => 12x"33a",
            MHPMEVENT27     => 12x"33b",
            MHPMEVENT28     => 12x"33c",
            MHPMEVENT29     => 12x"33d",
            MHPMEVENT30     => 12x"33e",
            MHPMEVENT31     => 12x"33f"
        ),
        OTHER_STANDARD_M_MODE => (
            MENVCFG         => 12x"30a",
            MENVCFGH        => 12x"31a"
        ),
        CUSTOM_M_MODE => (
            PMPCFGM0        => 12x"bd0",
            MEIEA           => 12x"be0",
            MEIPA           => 12x"be1",
            MEIFA           => 12x"be2",
            MEIPRA          => 12x"be3",
            MEINEXT         => 12x"be4",
            MEICONTEXT      => 12x"be5",
            MSLEEP          => 12x"bf0",
            H3MISA          => 12x"bf1"
        ),
        U_MODE => (
            CYCLE           => 12x"c00",
            TIME            => 12x"c01",
            INSTRET         => 12x"c02",
            CYCLEH          => 12x"c80",
            TIMEH           => 12x"c81",
            INSTRETH        => 12x"c82",
            SLEEP           => 12x"8f0"
        ),
        TRIGGER_MODULE => (
            TSELECT         => 12x"7a0",
            TDATA1          => 12x"7a1",
            TDATA2          => 12x"7a2",
            TDATA3          => 12x"7a3",
            TINFO           => 12x"7a4",
            TCONTROL        => 12x"7a5",
            MCONTEXT        => 12x"7a8"
        ),
        D_MODE => (
            DCSR            => 12x"7b0",
            DPC             => 12x"7b1",
            DMDATA0         => 12x"bff"
        )
    );

    -- ========================================================================
    -- Custom Functions
    -- ========================================================================

    function to_std_logic(value : boolean) return std_logic;

    function clog2(value : integer) return natural;

    function num_of_regs(e_extension : boolean) return positive;
    
    type std_logic_array_t is array (natural range <>) of std_logic_vector;

end package hazard3_constants;

package body hazard3_constants is

    function to_std_logic(value : boolean)
        return std_logic is
    begin
        if value then
            return '1';
        else
            return '0';
        end if;
    end function to_std_logic;

    function clog2(value : integer)
        return natural is
    begin
        return natural(ceil(log2(real(value))));
    end function clog2;

    function num_of_regs(e_extension : boolean)
        return positive is
    begin
        if e_extension then
            return 16;
        else
            return 32;
        end if;
    end function num_of_regs;
    
    
end package body hazard3_constants;

