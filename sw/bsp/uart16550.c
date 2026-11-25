#include "uart16550.h"

void uart_init(uint32_t baud)
{
    uint32_t divisor = UART16550_BAUD_DIVISOR(UART16550_CLK_HZ, baud);

    UART0.LCR = UART_DLAB_bm;                           /* DLL/DLM instead of RBR/THR and IER */
    UART0.DLL = (uint8_t)(divisor & 0xffu);
    UART0.DLM = (uint8_t)(divisor >> 8);
    UART0.LCR = UART_WLS_8BIT_gc | UART_PMODE_DISABLED_gc;   /* 8N1, DLAB = 0 */
    UART0.FCR = UART_FIFOEN_bm | UART_RXFIFORST_bm | UART_TXFIFORST_bm | UART_RXTRIG_1BYTE_gc;
}

void uart_putc(char c)
{
    while ((UART0.LSR & UART_THRE_bm) == 0u) {
    }
    UART0.THR = (uint8_t)c;
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
    if ((UART0.LSR & UART_DR_bm) == 0u) {
        return -1;
    }
    return UART0.RBR;
}

void uart_flush(void)
{
    while ((UART0.LSR & UART_TEMT_bm) == 0u) {
    }
}
