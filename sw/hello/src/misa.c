#include "misa.h"

#include "uart16550.h"

/* Extension letters as listed in the RISC-V privileged specification (misa encoding table) */
static const char *const ext_names[26] = {
    "atomic",                               /* A */
    "bit manipulation (B)",                 /* B */
    "compressed instructions",              /* C */
    "double-precision floating point",      /* D */
    "RV32E/RV64E base ISA (16 registers)",  /* E */
    "single-precision floating point",      /* F */
    "reserved",                             /* G */
    "hypervisor",                           /* H */
    "RV32I/64I/128I base ISA",              /* I */
    "reserved",                             /* J */
    "reserved",                             /* K */
    "reserved",                             /* L */
    "integer multiply/divide",              /* M */
    "user-level interrupts (reserved)",     /* N */
    "reserved",                             /* O */
    "packed SIMD (reserved)",               /* P */
    "quad-precision floating point",        /* Q */
    "reserved",                             /* R */
    "supervisor mode",                      /* S */
    "reserved",                             /* T */
    "user mode",                            /* U */
    "vector",                               /* V */
    "reserved",                             /* W */
    "non-standard extensions present",      /* X */
    "reserved",                             /* Y */
    "reserved",                             /* Z */
};

/* Unprivileged extensions in the canonical ISA string order (after the base I or E) */
static const char isa_order[] = "MAFDQCBPVH";

uint32_t misa_read(void)
{
    uint32_t misa;
    __asm__ volatile("csrr %0, misa" : "=r"(misa));
    return misa;
}

misa_mxl_t misa_mxl(uint32_t misa)
{
    return (misa_mxl_t)((misa & MISA_MXL_gm) >> MISA_MXL_gp);
}

unsigned misa_xlen(uint32_t misa)
{
    switch (misa_mxl(misa)) {
    case MISA_MXL_32:  return 32u;
    case MISA_MXL_64:  return 64u;
    case MISA_MXL_128: return 128u;
    default:           return 0u;
    }
}

int misa_has(uint32_t misa, char ext)
{
    if (ext < 'A' || ext > 'Z') {
        return 0;
    }
    return (misa & MISA_EXT_bm(ext)) != 0u;
}

const char *misa_ext_name(char ext)
{
    if (ext < 'A' || ext > 'Z') {
        return "?";
    }
    return ext_names[ext - 'A'];
}

void misa_print(uint32_t misa)
{
    uart_puts("misa = ");
    uart_put_hex(misa);
    uart_puts("\n");

    if (misa == 0u) {
        uart_puts("  misa is not implemented (reads 0)\n");
        return;
    }

    unsigned xlen = misa_xlen(misa);
    uart_puts("  MXL = ");
    uart_put_dec((uint32_t)misa_mxl(misa));
    uart_puts(" -> XLEN ");
    uart_put_dec(xlen);
    uart_puts("\n");

    /* ISA string: RV<xlen><base><extensions>, then non-standard extensions as "_X" */
    uart_puts("  ISA:   RV");
    uart_put_dec(xlen);
    uart_putc(misa_has(misa, 'E') ? 'E' : 'I');
    for (const char *p = isa_order; *p != '\0'; p++) {
        if (misa_has(misa, *p)) {
            uart_putc(*p);
        }
    }
    if (misa_has(misa, 'X')) {
        uart_puts("_X");
    }
    uart_puts("\n");

    /* Privilege modes: machine mode always exists, S and U are optional */
    uart_puts("  modes: M");
    if (misa_has(misa, 'S')) {
        uart_puts(", S");
    }
    if (misa_has(misa, 'U')) {
        uart_puts(", U");
    }
    uart_puts("\n");

    /* Every extension bit that is set */
    for (char ext = 'A'; ext <= 'Z'; ext++) {
        if (misa_has(misa, ext)) {
            uart_puts("    ");
            uart_putc(ext);
            uart_puts("  ");
            uart_puts(misa_ext_name(ext));
            uart_puts("\n");
        }
    }
}
