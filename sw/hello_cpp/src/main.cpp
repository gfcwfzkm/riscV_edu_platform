// Hello world in C++20 for hazard4eduMinimal: the C++ counterpart of sw/hello. Prints a greeting and
// then a counter over the UART (115200 baud, 8N1); received characters are echoed back.
#include <stdint.h>

#include "uart16550.h"

constinit volatile uint32_t counter = 0;    // volatile: easy to watch and change from the debugger

uint32_t read_mcycle()
{
    uint32_t cycles;
    __asm__ volatile("csrr %0, mcycle" : "=r"(cycles));
    return cycles;
}

void delay_cycles(uint32_t cycles)
{
    const uint32_t start = read_mcycle();
    while (read_mcycle() - start < cycles) {
        if (const int c = uart_getc_nonblocking(); c >= 0) {
            uart_putc(static_cast<char>(c));
        }
    }
}

// With -ffreestanding, main is an ordinary function to the compiler and its name would be mangled;
// extern "C" keeps the plain name "main" that crt0.S calls
extern "C" int main()
{
    uart_init(115200u);
    uart_puts("\nHello from hazard4eduMinimal (Hazard3) in C++!\n");

    for (;;) {
        counter = counter + 1;
        uart_puts("tick ");
        uart_put_dec(static_cast<uint32_t>(counter));
        uart_puts("\n");
        delay_cycles(F_CPU);   // about one second
    }
}
