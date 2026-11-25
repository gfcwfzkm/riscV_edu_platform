/* Linker script for hazard4eduMinimal: everything runs from the 64 KiB SRAM at 0x0.
 * The reset vector is 0x0, so _start (crt0.S, section .text.init) is placed first.
 * The program is loaded over JTAG; there is no copy of .data from a load address.
 * Shared by all projects in sw/ (C and C++). */

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

  /* Constructors, called by crt0.S before main: .preinit_array first, then .init_array sorted by
   * priority (__attribute__((constructor(N))), [[gnu::init_priority(N)]]), then the unsorted rest */
  .init_array : ALIGN(4) {
    __init_array_start = .;
    KEEP(*(.preinit_array))
    KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP(*(.init_array .ctors))
    __init_array_end = .;
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

  /* Destructors are never called (see crt0.S) */
  /DISCARD/ : { *(.comment) *(.note .note.*) *(.riscv.attributes.discard) *(.fini_array .fini_array.* .dtors .dtors.*) }
}
