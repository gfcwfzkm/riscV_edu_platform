/* Register definitions and polling driver for the 16550 compatible UART of hazard4eduMinimal
 * (hdl/modules/uart), in the style of the AVR XMEGA device headers
 *
 * Differences from a PC16550D, as implemented in hdl/modules/uart (see its doc/README.md):
 *   - registers are byte wide and must be accessed with byte loads/stores;
 *   - the FIFOs are always enabled (FCR.FIFOEN and DMAMODE have no effect, IIR.FIFOSTAT reads 0b11);
 *   - IER: only ERBFI and ETBEI are stored. ELSI reads back as 0, so the receiver line status
 *     interrupt cannot be enabled; EDSSI does not exist (no modem status);
 *   - MCR: only LOOP is implemented (the other bits read back as 0);
 *   - MSR is not implemented and reads as 0; the character timeout interrupt does not exist.
 */
#ifndef UART16550_H
#define UART16550_H

#include <stdint.h>

#define UART16550_BASE   0x00010000u   /* see hdl/systems/hazard4eduMinimal/README.md */
#define UART16550_CLK_HZ 50000000u     /* the baud generator runs on the 50 MHz board clock */

/* Divisor latch value for a baud rate: clock / (16 * baud), rounded (27 for 115200 baud) */
#define UART16550_BAUD_DIVISOR(clk_hz, baud) (((clk_hz) + 8u * (baud)) / (16u * (baud)))

#ifndef REGISTER8_T_DEFINED
#define REGISTER8_T_DEFINED
typedef volatile uint8_t register8_t;
#endif

/* ==========================================================================================
 * Register map. Offsets 0 to 2 hold two or three registers each: which one is accessed depends
 * on the direction (read/write) and on LCR.DLAB.
 * ========================================================================================== */
typedef struct UART16550_struct {
    union {
        register8_t RBR;    /* 0x00  read,  DLAB = 0: receiver buffer */
        register8_t THR;    /* 0x00  write, DLAB = 0: transmitter holding register */
        register8_t DLL;    /* 0x00  DLAB = 1: divisor latch, low byte */
    };
    union {
        register8_t IER;    /* 0x01  DLAB = 0: interrupt enable */
        register8_t DLM;    /* 0x01  DLAB = 1: divisor latch, high byte */
    };
    union {
        register8_t IIR;    /* 0x02  read:  interrupt identification */
        register8_t FCR;    /* 0x02  write: FIFO control */
    };
    register8_t LCR;        /* 0x03  line control */
    register8_t MCR;        /* 0x04  modem control */
    register8_t LSR;        /* 0x05  line status */
    register8_t MSR;        /* 0x06  modem status (not implemented, reads 0) */
    register8_t SCR;        /* 0x07  scratch */
} UART16550_t;

_Static_assert(sizeof(UART16550_t) == 8, "UART16550_t must map the 8 byte registers");

#define UART0 (*(UART16550_t *)UART16550_BASE)   /* hazard4eduMinimal UART */

/* ==========================================================================================
 * IER - interrupt enable (DLAB = 0)
 * ========================================================================================== */
#define UART_ERBFI_bm  0x01u    /* received data available interrupt enable bit mask */
#define UART_ERBFI_bp  0        /* received data available interrupt enable bit position */
#define UART_ETBEI_bm  0x02u    /* transmitter holding register empty interrupt enable bit mask */
#define UART_ETBEI_bp  1        /* transmitter holding register empty interrupt enable bit position */
#define UART_ELSI_bm   0x04u    /* receiver line status interrupt enable bit mask (not stored, see above) */
#define UART_ELSI_bp   2        /* receiver line status interrupt enable bit position */

/* ==========================================================================================
 * IIR - interrupt identification (read)
 * ========================================================================================== */
#define UART_INTPEND_bm   0x01u /* 0 = an interrupt is pending, 1 = none pending, bit mask */
#define UART_INTPEND_bp   0     /* interrupt pending bit position */
#define UART_INTID_gm     0x0Eu /* interrupt identification group mask */
#define UART_INTID_gp     1     /* interrupt identification group position */
#define UART_FIFOSTAT_gm  0xC0u /* FIFOs enabled (always 0b11 here) group mask */
#define UART_FIFOSTAT_gp  6     /* FIFOs enabled group position */

/* Interrupt identification, highest priority first (compare with IIR & UART_INTID_gm) */
typedef enum UART_INTID_enum {
    UART_INTID_LINESTATUS_gc = (0x03u << 1),  /* receiver line status: overrun, parity, framing error or break */
    UART_INTID_RXDATA_gc     = (0x02u << 1),  /* received data available (FIFO trigger level reached) */
    UART_INTID_THRE_gc       = (0x01u << 1),  /* transmitter holding register empty */
    UART_INTID_MODEM_gc      = (0x00u << 1),  /* modem status (not implemented) */
} UART_INTID_t;

/* ==========================================================================================
 * FCR - FIFO control (write)
 * ========================================================================================== */
#define UART_FIFOEN_bm    0x01u /* FIFO enable bit mask (FIFOs are always on here) */
#define UART_FIFOEN_bp    0     /* FIFO enable bit position */
#define UART_RXFIFORST_bm 0x02u /* receiver FIFO reset bit mask (self-clearing) */
#define UART_RXFIFORST_bp 1     /* receiver FIFO reset bit position */
#define UART_TXFIFORST_bm 0x04u /* transmitter FIFO reset bit mask (self-clearing) */
#define UART_TXFIFORST_bp 2     /* transmitter FIFO reset bit position */
#define UART_DMAMODE_bm   0x08u /* DMA mode select bit mask (no effect here) */
#define UART_DMAMODE_bp   3     /* DMA mode select bit position */
#define UART_RXTRIG_gm    0xC0u /* receiver FIFO trigger level group mask */
#define UART_RXTRIG_gp    6     /* receiver FIFO trigger level group position */

/* Receiver FIFO trigger level for the received data available interrupt */
typedef enum UART_RXTRIG_enum {
    UART_RXTRIG_1BYTE_gc   = (0x00u << 6),   /* 1 byte */
    UART_RXTRIG_4BYTES_gc  = (0x01u << 6),   /* 4 bytes */
    UART_RXTRIG_8BYTES_gc  = (0x02u << 6),   /* 8 bytes */
    UART_RXTRIG_14BYTES_gc = (0x03u << 6),   /* 14 bytes */
} UART_RXTRIG_t;

/* ==========================================================================================
 * LCR - line control
 * ========================================================================================== */
#define UART_WLS_gm    0x03u    /* word length select group mask */
#define UART_WLS_gp    0        /* word length select group position */
#define UART_STB_bm    0x04u    /* stop bits: 0 = 1 stop bit, 1 = 2 stop bits (1.5 for 5-bit words), bit mask */
#define UART_STB_bp    2        /* stop bits bit position */
#define UART_PMODE_gm  0x38u    /* parity mode (PEN, EPS, stick parity) group mask */
#define UART_PMODE_gp  3        /* parity mode group position */
#define UART_PEN_bm    0x08u    /* parity enable bit mask */
#define UART_PEN_bp    3        /* parity enable bit position */
#define UART_EPS_bm    0x10u    /* even parity select bit mask */
#define UART_EPS_bp    4        /* even parity select bit position */
#define UART_SPAR_bm   0x20u    /* stick parity bit mask */
#define UART_SPAR_bp   5        /* stick parity bit position */
#define UART_BC_bm     0x40u    /* break control: hold TxD low, bit mask */
#define UART_BC_bp     6        /* break control bit position */
#define UART_DLAB_bm   0x80u    /* divisor latch access bit mask */
#define UART_DLAB_bp   7        /* divisor latch access bit position */

/* Word length */
typedef enum UART_WLS_enum {
    UART_WLS_5BIT_gc = (0x00u << 0),    /* 5 data bits */
    UART_WLS_6BIT_gc = (0x01u << 0),    /* 6 data bits */
    UART_WLS_7BIT_gc = (0x02u << 0),    /* 7 data bits */
    UART_WLS_8BIT_gc = (0x03u << 0),    /* 8 data bits */
} UART_WLS_t;

/* Parity mode */
typedef enum UART_PMODE_enum {
    UART_PMODE_DISABLED_gc = (0x00u << 3),  /* no parity */
    UART_PMODE_ODD_gc      = (0x01u << 3),  /* odd parity */
    UART_PMODE_EVEN_gc     = (0x03u << 3),  /* even parity */
    UART_PMODE_MARK_gc     = (0x05u << 3),  /* parity bit always 1 */
    UART_PMODE_SPACE_gc    = (0x07u << 3),  /* parity bit always 0 */
} UART_PMODE_t;

/* ==========================================================================================
 * MCR - modem control
 * ========================================================================================== */
#define UART_DTR_bm    0x01u    /* data terminal ready bit mask (not implemented) */
#define UART_DTR_bp    0        /* data terminal ready bit position */
#define UART_RTS_bm    0x02u    /* request to send bit mask (not implemented) */
#define UART_RTS_bp    1        /* request to send bit position */
#define UART_OUT1_bm   0x04u    /* output 1 bit mask (not implemented) */
#define UART_OUT1_bp   2        /* output 1 bit position */
#define UART_OUT2_bm   0x08u    /* output 2 bit mask (not implemented) */
#define UART_OUT2_bp   3        /* output 2 bit position */
#define UART_LOOP_bm   0x10u    /* loopback: TxD held high, transmitter feeds the receiver, bit mask */
#define UART_LOOP_bp   4        /* loopback bit position */

/* ==========================================================================================
 * LSR - line status
 * ========================================================================================== */
#define UART_DR_bm     0x01u    /* data ready: the receiver FIFO holds at least one byte, bit mask */
#define UART_DR_bp     0        /* data ready bit position */
#define UART_OE_bm     0x02u    /* overrun error bit mask */
#define UART_OE_bp     1        /* overrun error bit position */
#define UART_PE_bm     0x04u    /* parity error bit mask */
#define UART_PE_bp     2        /* parity error bit position */
#define UART_FE_bm     0x08u    /* framing error bit mask */
#define UART_FE_bp     3        /* framing error bit position */
#define UART_BI_bm     0x10u    /* break interrupt bit mask */
#define UART_BI_bp     4        /* break interrupt bit position */
#define UART_THRE_bm   0x20u    /* transmitter holding register (FIFO) empty bit mask */
#define UART_THRE_bp   5        /* transmitter holding register empty bit position */
#define UART_TEMT_bm   0x40u    /* transmitter empty: FIFO and shift register idle, bit mask */
#define UART_TEMT_bp   6        /* transmitter empty bit position */
#define UART_RXFE_bm   0x80u    /* error in the receiver FIFO bit mask */
#define UART_RXFE_bp   7        /* error in the receiver FIFO bit position */

/* ==========================================================================================
 * Polling driver (uart16550.c), working on UART0
 * ========================================================================================== */
void uart_init(uint32_t baud);          /* 8N1, FIFOs cleared */
void uart_putc(char c);
void uart_puts(const char *s);          /* "\n" is sent as "\r\n" */
void uart_put_hex(uint32_t value);      /* 0x0000002a */
void uart_put_dec(uint32_t value);
int  uart_getc_nonblocking(void);       /* received byte, or -1 if the receive FIFO is empty */
void uart_flush(void);                  /* wait until the last bit has left the transmitter */

#endif
