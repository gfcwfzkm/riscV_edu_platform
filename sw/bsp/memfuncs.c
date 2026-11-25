/* memcpy, memmove, memset and memcmp. There is no C library, but even freestanding code needs these
 * four: the compiler calls them on its own, e.g. to zero a local array (char buf[64] = {0}) or to copy
 * a struct. Simple byte loops: small and easy to step through, not fast.
 *
 * This file is compiled with -fno-builtin (and, for GCC, -fno-tree-loop-distribute-patterns, see
 * sw/cmake/hazard4eduMinimal.cmake): otherwise the compiler may recognise the loop in memset and
 * replace it with a call to memset itself. */
#include <stddef.h>

void *memcpy(void *restrict dest, const void *restrict src, size_t n)
{
    unsigned char *d = dest;
    const unsigned char *s = src;
    while (n-- > 0u) {
        *d++ = *s++;
    }
    return dest;
}

void *memmove(void *dest, const void *src, size_t n)
{
    unsigned char *d = dest;
    const unsigned char *s = src;
    if (d < s) {
        while (n-- > 0u) {
            *d++ = *s++;
        }
    } else {
        /* dest overlaps the end of src: copy backwards */
        while (n-- > 0u) {
            d[n] = s[n];
        }
    }
    return dest;
}

void *memset(void *dest, int value, size_t n)
{
    unsigned char *d = dest;
    while (n-- > 0u) {
        *d++ = (unsigned char)value;
    }
    return dest;
}

int memcmp(const void *a, const void *b, size_t n)
{
    const unsigned char *x = a;
    const unsigned char *y = b;
    for (size_t i = 0; i < n; ++i) {
        if (x[i] != y[i]) {
            return x[i] - y[i];
        }
    }
    return 0;
}
