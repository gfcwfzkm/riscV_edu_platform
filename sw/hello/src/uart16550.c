#include "uart16550.h"

/* Byte registers (the UART only supports byte access) */
#define UART_REG(offset) (*(volatile uint8_t *)(UART16550_BASE + (offset)))
#define UART_RBR UART_REG(0)    /* read,  LCR.DLAB = 0: receive buffer */
#define UART_THR UART_REG(0)    /* write, LCR.DLAB = 0: transmit holding register */
#define UART_DLL UART_REG(0)    /* LCR.DLAB = 1: divisor low byte */
#define UART_DLM UART_REG(1)    /* LCR.DLAB = 1: divisor high byte */
#define UART_FCR UART_REG(2)    /* write: FIFO control */
#define UART_LCR UART_REG(3)    /* line control */
#define UART_LSR UART_REG(5)    /* line status */

#define LCR_8N1  0x03u
#define LCR_DLAB 0x80u
#define FCR_CLEAR_FIFOS 0x06u   /* reset the receive and transmit FIFOs */
#define LSR_DR   0x01u          /* receive data ready */
#define LSR_THRE 0x20u          /* transmit FIFO empty */
#define LSR_TEMT 0x40u          /* transmitter empty */

void uart_init(uint32_t baud)
{
    /* divisor = clock / (16 * baud), rounded: 27 for 115200 baud at 50 MHz */
    uint32_t divisor = (UART16550_CLK_HZ + 8u * baud) / (16u * baud);

    UART_LCR = LCR_DLAB;
    UART_DLL = (uint8_t)(divisor & 0xffu);
    UART_DLM = (uint8_t)(divisor >> 8);
    UART_LCR = LCR_8N1;
    UART_FCR = FCR_CLEAR_FIFOS;
}

void uart_putc(char c)
{
    while ((UART_LSR & LSR_THRE) == 0u) {
    }
    UART_THR = (uint8_t)c;
}

void uart_puts(const char *s)
{
    while (*s != '\0') {
        if (*s == '\n') {
            uart_putc('\r');
        }
        uart_putc(*s++);
    }
}

void uart_put_hex(uint32_t value)
{
    static const char digits[] = "0123456789abcdef";
    uart_puts("0x");
    for (int shift = 28; shift >= 0; shift -= 4) {
        uart_putc(digits[(value >> shift) & 0xfu]);
    }
}

void uart_put_dec(uint32_t value)
{
    char buffer[10];
    int count = 0;
    do {
        buffer[count++] = (char)('0' + value % 10u);   /* RV32IM: hardware divide */
        value /= 10u;
    } while (value != 0u);
    while (count > 0) {
        uart_putc(buffer[--count]);
    }
}

int uart_getc_nonblocking(void)
{
    if ((UART_LSR & LSR_DR) == 0u) {
        return -1;
    }
    return UART_RBR;
}

void uart_flush(void)
{
    while ((UART_LSR & LSR_TEMT) == 0u) {
    }
}
