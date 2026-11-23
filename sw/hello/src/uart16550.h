/* Polling driver for the 16550 compatible UART of hazard4eduMinimal (hdl/modules/uart). */
#ifndef UART16550_H
#define UART16550_H

#include <stdint.h>

#define UART16550_BASE   0x00010000u   /* see hdl/systems/hazard4eduMinimal/README.md */
#define UART16550_CLK_HZ 50000000u     /* the UART runs on the 50 MHz bus clock */

void uart_init(uint32_t baud);
void uart_putc(char c);
void uart_puts(const char *s);          /* "\n" is sent as "\r\n" */
void uart_put_hex(uint32_t value);      /* 0x0000002a */
void uart_put_dec(uint32_t value);
int  uart_getc_nonblocking(void);       /* received byte, or -1 if the receive FIFO is empty */
void uart_flush(void);                  /* wait until the last bit has left the transmitter */

#endif
