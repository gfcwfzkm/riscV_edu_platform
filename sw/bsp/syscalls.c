/* System calls for newlib (only linked by hazard4edu_firmware(<target> NEWLIB)).
 *
 * newlib implements printf, malloc, ... in C, but at the bottom it calls a few functions that only the
 * platform can provide: where do bytes go (_write), where do they come from (_read), where is free
 * memory (_sbrk). Here stdout/stderr go to the UART, stdin comes from it, and the heap is the RAM between
 * the end of .bss and the stack. There are no files. _exit is in crt0.S.
 *
 * These definitions replace the ones in newlib's libgloss, which would use ecall (and end in trap_spin). */
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/stat.h>

#include "uart16550.h"

#define BAUD 115200u

/* From the linker script (bsp/link.ld) */
extern char __heap_start[];
extern char __stack_top[];
extern char __stack_size[];   /* a symbol whose address is the value */

/* The UART is initialised before main (constructor priority 101: before C++ global objects), so
 * printf works from the first line of main and in constructors of C++ global objects */
__attribute__((constructor(101))) static void stdio_uart_init(void)
{
    uart_init(BAUD);
}

int _write(int fd, const char *buf, int len)
{
    if (fd != 1 && fd != 2) {
        errno = EBADF;
        return -1;
    }
    for (int i = 0; i < len; ++i) {
        if (buf[i] == '\n') {
            uart_putc('\r');   /* terminals expect \r\n */
        }
        uart_putc(buf[i]);
    }
    return len;
}

/* Blocks until at least one byte has arrived; returns one byte per call. Echo is left to the program. */
int _read(int fd, char *buf, int len)
{
    if (fd != 0) {
        errno = EBADF;
        return -1;
    }
    if (len <= 0) {
        return 0;
    }
    int c;
    while ((c = uart_getc_nonblocking()) < 0) {
    }
    buf[0] = (char)(c == '\r' ? '\n' : c);   /* Enter sends \r */
    return 1;
}

/* Grow the heap by increment bytes (malloc calls this). The heap may grow up to the space reserved
 * for the stack (__stack_size below __stack_top); the stack itself is not checked at run time. */
void *_sbrk(ptrdiff_t increment)
{
    static char *heap_end = __heap_start;
    char *const limit = __stack_top - (uintptr_t)__stack_size;

    if (increment > limit - heap_end || increment < __heap_start - heap_end) {
        errno = ENOMEM;
        return (void *)-1;
    }
    char *previous = heap_end;
    heap_end += increment;
    return previous;
}

/* stdin/stdout/stderr are terminals: newlib then buffers stdout by line instead of fully */
int _isatty(int fd)
{
    return fd >= 0 && fd <= 2;
}

int _fstat(int fd, struct stat *st)
{
    if (!_isatty(fd)) {
        errno = EBADF;
        return -1;
    }
    st->st_mode = S_IFCHR;
    return 0;
}

int _close(int fd)
{
    (void)fd;
    errno = EBADF;
    return -1;
}

int _lseek(int fd, int offset, int whence)
{
    (void)fd;
    (void)offset;
    (void)whence;
    errno = ESPIPE;
    return -1;
}

/* Used by abort() and raise(): there is only one process */
int _getpid(void)
{
    return 1;
}

int _kill(int pid, int sig)
{
    (void)pid;
    (void)sig;
    errno = EINVAL;
    return -1;
}
