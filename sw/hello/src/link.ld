/* Linker script for hazard4eduMinimal: everything runs from the 64 KiB SRAM at 0x0.
 * The reset vector is 0x0, so _start (crt0.S, section .text.init) is placed first.
 * The program is loaded over JTAG; there is no copy of .data from a load address. */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

/* Bytes reserved for the stack at the top of the RAM (only checked, not enforced at run time) */
__stack_size = DEFINED(__stack_size) ? __stack_size : 4K;

SECTIONS
{
  .text : {
    KEEP(*(.text.init))
    *(.text .text.*)
  } > RAM

  .rodata : ALIGN(4) {
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > RAM

  .data : ALIGN(4) {
    *(.data .data.*)
    /* gp points 2 KiB into the small data, so it reaches +-2 KiB with one instruction */
    __global_pointer$ = . + 0x800;
    *(.sdata .sdata.*)
  } > RAM

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > RAM

  __heap_start = ALIGN(16);
  __stack_top  = ORIGIN(RAM) + LENGTH(RAM);

  ASSERT(__heap_start + __stack_size <= __stack_top, "program and stack do not fit into the 64 KiB SRAM")

  /DISCARD/ : { *(.comment) *(.note .note.*) *(.riscv.attributes.discard) }
}
