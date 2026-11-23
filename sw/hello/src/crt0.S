/* Start-up code for hazard4eduMinimal (RV32IM, program in SRAM at 0x0).
 *
 * The CPU starts at 0x0 after reset, and the debugger also starts programs there.
 * .data is already in place (the ELF is loaded over JTAG), so only .bss is cleared. */

    .section .text.init, "ax"
    .globl _start
_start:
    /* gp must not be set with a gp-relative instruction */
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop
    la      sp, __stack_top             /* 0x10000, end of the SRAM; the stack grows down */

    /* Traps end in trap_spin, where a debugger can look at mcause / mepc */
    la      t0, trap_spin
    csrw    mtvec, t0

    /* Hazard3 resets mcountinhibit with the counters stopped: let mcycle and minstret run */
    csrw    mcountinhibit, zero

    /* Clear .bss word by word; the linker script aligns start and end to 4 bytes */
    la      t0, __bss_start
    la      t1, __bss_end
1:  bgeu    t0, t1, 2f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       1b
2:
    li      a0, 0                       /* argc */
    li      a1, 0                       /* argv */
    call    main

    /* main returned: stay here */
    .globl _exit
_exit:
    wfi
    j       _exit

    /* mtvec needs 4-byte alignment (direct mode) */
    .balign 4
    .globl trap_spin
trap_spin:
    j       trap_spin
