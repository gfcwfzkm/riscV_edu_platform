# hazard4edu – open issues and notes

Findings that are known but deliberately **not fixed yet**, with the steps to reproduce them.

## 1. `c.beqz` / `c.bnez` compare against x8–x15 instead of x0

**Status:** open, not fixed (found 2026-11-23). Present in the Verilog reference **and** mirrored on purpose in
the VHDL port, so the equivalence checks pass. The same line also exists in upstream Hazard3 (`stable` and
`develop`, unchanged since at least 2025-09). Upstream's own core has not been tested for it.

### What is wrong

`verilog/hazard3_frontend.v` (around line 785) predecodes the register numbers for the register file read.
The "fine" rs2 predecode is supposed to force rs2 to x0 for compressed branches, because `c.beqz rs1', off`
expands to `beq rs1', x0, off`:

```verilog
casez ({|EXTENSION_C, next_instr})                                                   // 1 + 32 = 33 bits
{1'b1, 1'bz, 1'bz, 16'hzzzz, `RVOPC_C_BEQZ}: predecode_rs2_fine = 5'd0;           // 1+1+1+16+16 = 35 bits
{1'b1, 1'bz, 1'bz, 16'hzzzz, `RVOPC_C_BNEZ}: predecode_rs2_fine = 5'd0;
default:                                     predecode_rs2_fine = predecode_rs2_coarse;
endcase
```

The case items are 35 bits wide but the selector is only 33 bits. Verilog extends all operands to the widest
width, and the selector is zero-extended, so the leading `1'b1` of the items is compared against a `0` and
**never matches**. `predecode_rs2_fine` therefore stays `predecode_rs2_coarse`, which for a CB-format
instruction is `{2'b01, instr[4:2]}`: one of **x8–x15**, selected by the branch offset bits `imm[2:1|5]`.

In the core (`hazard3_core.v`), the bypass select `x_rs2_select_regs_xm_mw` is computed from that
predecoded register number, not from the decoded `d_rs2` (which is correctly 0). The branch comparator
(`x_rs2_bypass`) therefore sees the content of x8–x15 instead of 0.

**Effect:** `c.beqz` / `c.bnez` give wrong results whenever the register selected by the offset bits is
non-zero. This affects any code built with the C extension (`-march=rv32*c`). With a zeroed register file
(e.g. right after FPGA configuration), simple programs may appear to work until s0/s1/a0–a5 are used.

The VHDL port (`vhdl/hazard3_frontend.vhdl`, comment just before `v_rs2_fine := v_rs2_coarse;`) copies the
behaviour so that it stays equivalent to the Verilog reference.

### Likely fix (not applied)

Make the items 33 bits wide, the same as the `predecode_rs1_fine` cases just above them, and do the matching
change in the VHDL port:

```verilog
{1'b1, 16'hzzzz, `RVOPC_C_BEQZ}: predecode_rs2_fine = 5'd0;    // -> beq rs1, x0, label
{1'b1, 16'hzzzz, `RVOPC_C_BNEZ}: predecode_rs2_fine = 5'd0;    // -> bne rs1, x0, label
```

### Reproduce A: tool semantics only (seconds)

Shows that both Icarus Verilog and Yosys never match the 35-bit item. `casetest.v`:

```verilog
module casetest(input [31:0] next_instr, output reg [4:0] fine);
  always @(*) begin
    casez ({1'b1, next_instr})
      {1'b1, 1'bz, 1'bz, 16'hzzzz, 16'b110???????????01}: fine = 5'd0;  // `RVOPC_C_BEQZ
      default: fine = 5'd9;
    endcase
  end
endmodule
module tbc; reg [31:0] i; wire [4:0] f; casetest u(i, f);
  initial begin i = 32'h0000dee5; #1 $display("c.beqz -> rs2_fine=%0d (expected 0)", f); end
endmodule
```

```bash
iverilog -o c.vvp casetest.v && vvp -n c.vvp          # prints rs2_fine=9
yosys -p "read_verilog casetest.v; hierarchy -top casetest; proc; opt; eval -set next_instr 32'h0000dee5 -show fine"
                                                      # Eval result: \fine = 5'01001
```

### Reproduce B: wrong branch on the CPU

A program in which `a3 = 0`, so `c.beqz a3` must branch, while x9 (s1) is non-zero. The offset (+32) makes
`instr[4:2] = 001`, so the coarse predecode picks x9. The program writes `T` (taken, correct) or `F`
(fall-through, wrong) to the UART transmit register at `0x10000`. `beqz.S`:

```asm
    .section .text.start
    .global _start
_start:
    lui   a1, 0x10          # UART base (16550 THR at offset 0)
    li    s1, S1_VALUE      # the register that the faulty predecode reads instead of x0
    li    a3, 0
    .option push
    .option rvc
br: c.beqz a3, taken        # a3 == 0  -> must be taken
    .option pop
    li    a0, 'F'           # fall-through = WRONG
    sb    a0, 0(a1)
1:  j     1b
    .org  br - _start + 32
taken:
    li    a0, 'T'           # taken = correct
    sb    a0, 0(a1)
2:  j     2b
```

Build with clang/lld, for S1_VALUE = 0 and 5 (any linker script that places `.text.start` at the reset
vector 0x0 will do):

```bash
clang --target=riscv32-unknown-elf -march=rv32imac -mabi=ilp32 -nostdlib -DS1_VALUE=5 -c beqz.S -o b5.o
ld.lld -Ttext=0 b5.o -o b5.elf
llvm-objdump -d b5.elf | grep -A1 '<br>:'             # c285  beqz a3, ...  -> bits [4:2] = 001
llvm-objcopy -O binary b5.elf b5.bin                  # then convert to 32-bit words for $readmemh
```

Run it on any system with the core, RAM at 0x0 and the UART at 0x10000, for example the minimal SoC in
`hdl/systems/hazard4eduMinimal`, simulated with Icarus Verilog with the RAM preloaded. Zero the register
file first (`cpu.core.regs.dataARam.s_memory` / `dataBRam.s_memory`), as the LUT RAM is zero after FPGA
configuration, and watch the bytes written to the UART TX FIFO (`uartBus.s_TxFifoWe` /
`s_dataInReg[7:0]`). Result observed on 2026-11-23:

| Frontend                         | s1 = 0 | s1 = 5 |
|----------------------------------|--------|--------|
| as in the repository             | T      | **F**  |
| with the 33-bit case items above | T      | T      |

## 2. `x_stall_on_raw` used before its declaration

**Status:** open, not fixed. `verilog/hazard3_core.v` uses `x_stall_on_raw` in the custom-instruction block
(`wire ci_op_vld = d_is_ci && !(x_stall_on_raw || ci_posted);`, around line 436) but declares it later
(`reg x_stall_on_raw;`, around line 517). Yosys accepts this, Icarus Verilog does not:

```text
hazard3_core.v:436: error: Unable to bind wire/reg/memory `x_stall_on_raw' ...
```

To simulate with Icarus Verilog, move the declaration above the custom-instruction block, in a scratch
copy for now. This changes no logic.

## 3. Icarus Verilog and `NUM_IRQS = 1`

With `NUM_IRQS = 1`, Icarus Verilog rejects zero-width replications and part selects in
`arith/hazard3_onehot_encode.v` and `hazard3_irq_ctrl.v` ("Concatenation repeat may not be zero",
"part select i[-1:0] is out of order"). Yosys and GHDL accept them. For simulation with Icarus, use
`NUM_IRQS >= 2`.
