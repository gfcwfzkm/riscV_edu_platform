// C++ programs with libstdc++ (hazard4edu_firmware(<target> NEWLIB)): keep exception handling out.
//
// The programs are compiled with -fno-exceptions, but the prebuilt libstdc++ is not: its error paths
// throw. A single std::vector::push_back references std::__throw_length_error, and operator new
// throws std::bad_alloc. Linking those pulls in the unwinder, the name demangler of the terminate
// handler and std::string for the exception messages: about 100 KiB, more than the 64 KiB SRAM.
//
// The functions below replace the library's versions (the linker takes them from here and never
// loads the library object that defines them). Every error that would throw calls abort() instead,
// which ends in _exit (bsp/crt0.S). Replacing operator new/delete is allowed by the C++ standard;
// the std::__throw_* functions are libstdc++ internals (bits/functexcept.h), all of them from
// libstdc++'s functexcept.o must be defined here, or the linker reports duplicate definitions.
#include <bits/functexcept.h>
#include <cstdlib>
#include <new>

// ---------------------------------------------------------------------------- operator new / delete

void *operator new(std::size_t size)
{
    void *p = std::malloc(size != 0u ? size : 1u);
    if (p == nullptr) {
        std::abort();   // out of heap memory (instead of throwing std::bad_alloc)
    }
    return p;
}

void *operator new[](std::size_t size) { return operator new(size); }
void *operator new(std::size_t size, const std::nothrow_t &) noexcept { return std::malloc(size != 0u ? size : 1u); }
void *operator new[](std::size_t size, const std::nothrow_t &) noexcept { return std::malloc(size != 0u ? size : 1u); }

void operator delete(void *p) noexcept { std::free(p); }
void operator delete[](void *p) noexcept { std::free(p); }
void operator delete(void *p, std::size_t) noexcept { std::free(p); }
void operator delete[](void *p, std::size_t) noexcept { std::free(p); }
void operator delete(void *p, const std::nothrow_t &) noexcept { std::free(p); }
void operator delete[](void *p, const std::nothrow_t &) noexcept { std::free(p); }

// ---------------------------------------------------------------------------- libstdc++ error paths

namespace std {
void __throw_bad_exception() { abort(); }
void __throw_bad_alloc() { abort(); }
void __throw_bad_array_new_length() { abort(); }
void __throw_bad_cast() { abort(); }
void __throw_bad_typeid() { abort(); }
void __throw_logic_error(const char *) { abort(); }
void __throw_domain_error(const char *) { abort(); }
void __throw_invalid_argument(const char *) { abort(); }
void __throw_length_error(const char *) { abort(); }
void __throw_out_of_range(const char *) { abort(); }
void __throw_out_of_range_fmt(const char *, ...) { abort(); }
void __throw_runtime_error(const char *) { abort(); }
void __throw_range_error(const char *) { abort(); }
void __throw_overflow_error(const char *) { abort(); }
void __throw_underflow_error(const char *) { abort(); }
} // namespace std
