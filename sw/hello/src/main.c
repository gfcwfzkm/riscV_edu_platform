/* Hello world for hazard4eduMinimal: prints a greeting and then a counter over the UART
 * (115200 baud, 8N1, the board's second FT2232H channel). Characters received on the UART
 * are echoed back. At start-up the misa CSR is read and decoded (misa.c). */
#include <stdint.h>

#include "misa.h"
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

int main(void)
{
    uart_init(BAUD);
    uart_puts("\nHello from hazard4eduMinimal (Hazard3)!\n");
    misa_print(misa_read());

    for (;;) {
        counter++;
        uart_puts("tick ");
        uart_put_dec(counter);
        uart_puts("\n");
        delay_cycles(F_CPU);   /* about one second */
    }
}
