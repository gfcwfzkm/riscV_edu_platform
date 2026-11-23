/* Hello world for hazard4eduMinimal: prints a greeting and then a counter over the UART
 * (115200 baud, 8N1, the board's second FT2232H channel). Characters received on the UART
 * are echoed back. */
#include <stdint.h>

#include "uart16550.h"

#define BAUD 115200u

static volatile uint32_t counter;   /* volatile: easy to watch and change from the debugger */

static uint32_t read_mcycle(void)
{
    uint32_t cycles;
    __asm__ volatile("csrr %0, mcycle" : "=r"(cycles));
    return cycles;
}

static void delay_cycles(uint32_t cycles)
{
    uint32_t start = read_mcycle();
    while ((uint32_t)(read_mcycle() - start) < cycles) {
        int c = uart_getc_nonblocking();
        if (c >= 0) {
            uart_putc((char)c);
        }
    }
}

static uint32_t read_misa(void)
{
    uint32_t misa;
    __asm__ volatile("csrr %0, misa" : "=r"(misa));
    return misa;
}

int main(void)
{
    uart_init(BAUD);
    uart_puts("\nHello from hazard4eduMinimal (Hazard3 RV32IM)!\n");
    uart_puts("misa = ");
    uart_put_hex(read_misa());
    uart_puts("\n");

    for (;;) {
        counter++;
        uart_puts("tick ");
        uart_put_dec(counter);
        uart_puts("\n");
        delay_cycles(UART16550_CLK_HZ);   /* about one second at 50 MHz */
    }
}
