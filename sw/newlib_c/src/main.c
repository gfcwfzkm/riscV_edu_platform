/* printf, floating point, libm and malloc on hazard4eduMinimal, with the newlib-nano C library
 * (115200 baud, 8N1). The core has no FPU: float and double are computed in software (libgcc).
 * stdout goes to the UART through bsp/syscalls.c, which also initialises the UART before main. */
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static uint32_t read_mcycle(void)
{
    uint32_t cycles;
    __asm__ volatile("csrr %0, mcycle" : "=r"(cycles));
    return cycles;
}

int main(void)
{
    printf("\nHello from hazard4eduMinimal with newlib-nano!\n");
    printf("F_CPU = %lu Hz, printf with float: %s\n", (unsigned long)F_CPU, PRINTF_FLOAT ? "yes" : "no");

    /* libm in software floating point; the cycle count shows what that costs */
    volatile double x = 2.0;   /* volatile: computed at run time, not by the compiler */
    uint32_t start = read_mcycle();
    double root = sqrt(x);
    uint32_t cycles = read_mcycle() - start;
#if PRINTF_FLOAT
    printf("sqrt(%g) = %.9f (%lu cycles), sin(1) = %f\n", x, root, (unsigned long)cycles, sin(1.0));
#else
    /* Without PRINTF_FLOAT, %f prints nothing: print the digits as integers instead */
    printf("sqrt(2) * 1e6 = %ld (%lu cycles); build with PRINTF_FLOAT=ON for %%f\n",
           lround(root * 1e6), (unsigned long)cycles);
#endif

    /* The heap: malloc takes memory from _sbrk (bsp/syscalls.c) */
    char *text = malloc(64);
    if (text != NULL) {
        snprintf(text, 64, "malloc(64) returned %p", (void *)text);
        puts(text);
        free(text);
    }

    for (uint32_t seconds = 1;; ++seconds) {
        start = read_mcycle();
        while (read_mcycle() - start < F_CPU) {
        }
        printf("tick %lu\n", (unsigned long)seconds);
    }
}
