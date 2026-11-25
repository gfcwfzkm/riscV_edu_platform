# hello_cpp – C++20 firmware example for hazard4eduMinimal

The C++ counterpart of [`../hello`](../hello): prints a greeting, then `tick <n>` about once per second, and
echoes characters it receives (115200 8N1). It uses the same toolchain file, build settings and board support
files (see [`sw/README.md`](../README.md)) and calls the C UART driver `bsp/uart16550.[ch]`.

## Freestanding C++ on this target

* **Global constructors:** the global `Uart uart;` initialises the UART in its constructor. The compiler puts
  a pointer to that code into `.init_array`; `bsp/link.ld` collects the table and `bsp/crt0.S` calls every
  entry before `main`.
* **`extern "C" int main()`:** with `-ffreestanding` the compiler does not treat `main` specially, so it would
  get a mangled C++ name that `crt0.S` cannot find.
* **No exceptions, RTTI or thread-safe statics** (set in the toolchain file): they need a C++ runtime library.
  The few functions the compiler may still call are in `bsp/cxx_support.cpp`, `memset` etc. in `bsp/memfuncs.c`.
* **No standard library headers:** the installed clang has no C++ headers for bare-metal RISC-V (not even
  `<cstdint>` or `<array>`); only the C headers `<stdint.h>`/`<stddef.h>` that come with the compiler work.

## Build, run, debug

Exactly as for [`hello`](../hello/README.md): `cmake --preset rv32im`, `cmake --build build`,
`cmake --build build --target run`; Release: `rv32im-release`, `build-release/`. The VS Code configurations in
`.vscode/` use `build/hello_cpp.elf` and `build-release/hello_cpp.elf`.
