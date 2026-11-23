/* Reading and decoding the RISC-V misa CSR (machine ISA register).
 *
 *   bits 31:30  MXL   native base integer width: 1 = 32 bit, 2 = 64 bit, 3 = 128 bit
 *   bits 29:26        reserved (0)
 *   bits 25:0         extensions: bit 0 = 'A' ... bit 25 = 'Z'
 *
 * misa may also read as 0, which means "not implemented"; the ISA then has to be found
 * out some other way.
 */
#ifndef MISA_H
#define MISA_H

#include <stdint.h>

#define MISA_MXL_gm   0xC0000000u     /* machine XLEN group mask (RV32 layout) */
#define MISA_MXL_gp   30              /* machine XLEN group position */
#define MISA_EXT_gm   0x03FFFFFFu     /* extension bits 'A' to 'Z' group mask */

/* Bit mask of an extension letter, e.g. MISA_EXT_bm('M') */
#define MISA_EXT_bm(letter) (1u << ((letter) - 'A'))

typedef enum misa_mxl_enum {
    MISA_MXL_NONE = 0,  /* misa not implemented */
    MISA_MXL_32   = 1,
    MISA_MXL_64   = 2,
    MISA_MXL_128  = 3,
} misa_mxl_t;

uint32_t    misa_read(void);                    /* csrr misa */
misa_mxl_t  misa_mxl(uint32_t misa);
unsigned    misa_xlen(uint32_t misa);           /* 32, 64, 128, or 0 if misa is not implemented */
int         misa_has(uint32_t misa, char ext);  /* 1 if the extension letter 'A'..'Z' is set */
const char *misa_ext_name(char ext);            /* description of an extension letter */
void        misa_print(uint32_t misa);          /* decoded report on the UART */

#endif
