// The few run-time functions a freestanding C++ program still needs. There is no C++ runtime library
// (no libsupc++ / libc++abi): exceptions, RTTI and thread-safe local statics are switched off in the
// toolchain file (sw/cmake/riscv-rv32im.cmake), and there is no heap.
//
// hazard4edu_firmware() (sw/cmake/hazard4eduMinimal.cmake) adds this file to every C++ project.
#include <stddef.h>

namespace {
[[noreturn]] void cxx_fatal()
{
    // Stop where a debugger can find it (see mcause/mepc in trap_spin for comparison)
    for (;;) {
        __asm__ volatile("ebreak");
    }
}
}

extern "C" {

// Called if a pure virtual function is called, e.g. from the constructor of an abstract base class
[[noreturn]] void __cxa_pure_virtual() { cxx_fatal(); }

// Destructors of global objects are registered with __cxa_atexit. main never returns and crt0.S
// never calls them, so the registration is simply ignored
void *__dso_handle = nullptr;
int __cxa_atexit(void (*)(void *), void *, void *) { return 0; }
int atexit(void (*)(void)) { return 0; }

}

// A class with a virtual destructor references operator delete (the "deleting destructor"), even if
// no object is ever created with new. There is no heap, so it must never actually be called
void operator delete(void *) noexcept { cxx_fatal(); }
void operator delete(void *, size_t) noexcept { cxx_fatal(); }
