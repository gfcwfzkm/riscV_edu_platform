// The C++ standard library (libstdc++) on hazard4eduMinimal, on top of newlib-nano (115200 baud, 8N1).
// Still without exceptions and RTTI (see the toolchain file). The core has no FPU: float and double are
// computed in software (libgcc). printf goes to the UART through bsp/syscalls.c.
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <numeric>
#include <vector>

namespace {

// A global object whose constructor prints: bsp/syscalls.c initialises the UART first
struct Greeter {
    Greeter() { std::printf("\nHello from hazard4eduMinimal with libstdc++ and newlib-nano!\n"); }
} greeter;

std::uint32_t read_mcycle()
{
    std::uint32_t cycles;
    __asm__ volatile("csrr %0, mcycle" : "=r"(cycles));
    return cycles;
}

} // namespace

int main()
{
    // <array> and <algorithm>
    std::array values{7, 3, 9, 1, 5};
    std::ranges::sort(values);
    std::printf("sorted:");
    for (int v : values) {
        std::printf(" %d", v);
    }
    std::printf(", sum = %d\n", std::accumulate(values.begin(), values.end(), 0));

    // <vector> on the heap (operator new -> malloc -> _sbrk) and <cmath> in software floating point
    std::vector<float> roots;
    for (int i = 1; i <= 5; ++i) {
        roots.push_back(std::sqrt(static_cast<float>(i)));
    }
#if PRINTF_FLOAT
    std::printf("sqrt(1..5):");
    for (float r : roots) {
        std::printf(" %.4f", static_cast<double>(r));
    }
    std::printf("\n");
#else
    std::printf("sqrt(5) * 1000 = %ld; build with PRINTF_FLOAT=ON for %%f\n", std::lround(roots.back() * 1000.0f));
#endif

    for (std::uint32_t seconds = 1;; ++seconds) {
        const std::uint32_t start = read_mcycle();
        while (read_mcycle() - start < F_CPU) {
        }
        std::printf("tick %lu\n", static_cast<unsigned long>(seconds));
    }
}
