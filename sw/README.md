# Firmware for hazard4eduMinimal

| Folder                    | Content                                                                          |
|---------------------------|----------------------------------------------------------------------------------|
| [`hello`](hello)          | hello world in C: greeting, `misa` decoding, a counter, UART echo                |
| [`hello_cpp`](hello_cpp)  | the same in C++20: global constructor, `constexpr`/`static_assert`, `requires`   |
| [`newlib_c`](newlib_c)    | C with the newlib-nano C library: `printf` with floats, `libm`, `malloc` (GCC only) |
| [`newlib_cpp`](newlib_cpp) | C++20 with libstdc++: `std::vector`, `std::array`, `<algorithm>`, `printf` (GCC only) |
| [`cmake`](cmake)          | shared CMake files (below)                                                       |
| [`bsp`](bsp)              | shared board support files (below)                                               |

Every project is a CMake project of its own (open its folder in VS Code), but they all use the same toolchain
file, build settings and board support files:

| File                          | Content                                                                      |
|-------------------------------|------------------------------------------------------------------------------|
| `cmake/riscv-rv32im.cmake`    | toolchain file: C, C++ and assembler, `-march=rv32im_zicsr -mabi=ilp32`, GCC if found, otherwise clang; C++ without exceptions, RTTI and thread-safe statics |
| `cmake/hazard4eduMinimal.cmake` | `hazard4edu_firmware(<target> [NEWLIB])`: adds the BSP, `F_CPU`, warnings, `.bin`/`.lst`/`.map` and the `run` target |
| `bsp/crt0.S`                  | start-up: `gp`, `sp` = `0x10000`, `mtvec`, counters on, clear `.bss`, constructors (`.init_array`), `main` |
| `bsp/link.ld`                 | everything in the 64 KiB SRAM, `_start` at the reset vector `0x0`            |
| `bsp/uart16550.[ch]`          | register definitions and polling UART driver, divisor = F_CPU / (16 × baud) |
| `bsp/memfuncs.c`              | freestanding: `memcpy`, `memmove`, `memset`, `memcmp` (the compiler calls them on its own) |
| `bsp/cxx_support.cpp`         | freestanding C++: `__cxa_pure_virtual`, `__cxa_atexit`, `operator delete` stubs |
| `bsp/syscalls.c`              | NEWLIB: `_write`/`_read` on the UART, `_sbrk` (heap), stubs; initialises the UART before main |
| `bsp/cxx_newlib.cpp`          | NEWLIB C++: `operator new`/`delete` and libstdc++'s `std::__throw_*` call `abort()`, which keeps exception handling (~100 KiB) out |

## Freestanding or with the C/C++ library

| | `hazard4edu_firmware(app)` (freestanding) | `hazard4edu_firmware(app NEWLIB)` |
|---|---|---|
| Compiler | GCC or clang | RISC-V GCC with newlib (Arch: `riscv64-elf-gcc`, `riscv64-elf-newlib`) |
| Libraries | none (GCC: `libgcc`) | newlib-nano (`libc_nano`, `libm_nano`), `libgcc`, C++: `libstdc++` |
| Flags | `-ffreestanding -nostdlib` | `--specs=nano.specs` (compile and link) |
| `printf`, `malloc`, `<math.h>`, `float`/`double` | no (`float` only with GCC: `libgcc`) | yes; float in software (no FPU) |
| C++ standard headers | no | yes (no exceptions, no RTTI) |
| Size of the demos | 0.7–2 KiB | 17–19 KiB, 32–38 KiB with `PRINTF_FLOAT` |

The freestanding projects (`hello`, `hello_cpp`) need neither GCC nor newlib, so they keep building on
systems with clang only. The NEWLIB projects stop at configure time with a message if GCC or newlib is missing.

## A new project

```cmake
cmake_minimum_required(VERSION 3.20)
if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../cmake/riscv-rv32im.cmake)
endif()
project(myapp LANGUAGES C ASM)          # add CXX for C++
include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)
add_executable(myapp src/main.c)
hazard4edu_firmware(myapp)
```

Copy `CMakePresets.json` and `.vscode/` from `hello` and replace `hello.elf` with the new name.

## Debug and Release builds

Every project has a Debug and a Release preset, each with its own build folder, so both can exist side by side:

| Preset           | Build type | Flags                  | Folder           |
|------------------|------------|------------------------|------------------|
| `rv32im`         | Debug      | `-Og -g3`              | `build/`         |
| `rv32im-release` | Release    | `-O2 -g3 -DNDEBUG`     | `build-release/` |

(`hello` also has `rv32im-clang-release`/`rv32im-gcc-release`, the NEWLIB projects `rv32im-nofloat-release`.
`-DCMAKE_BUILD_TYPE=MinSizeRel` gives `-Os` for size.)

```bash
cmake --preset rv32im-release
cmake --build --preset rv32im-release            # build-release/<name>.elf, .bin, .lst, .map
cmake --build build-release --target run         # load it over JTAG and start it
```

Loading is the same for both: `make -C ../../hdl/systems/hazard4eduMinimal run ELF=build-release/<name>.elf`
writes the ELF into the SRAM over JTAG and starts it at `0x0` (the bitstream must be loaded; the SRAM is
not initialised by the bitstream, so the program is gone after a power cycle or FPGA reload).

The debug information (`-g3`) is kept in Release too: it stays in the `.elf` on the PC and is never loaded
into the SRAM, so it costs nothing on the target. In VS Code, the tasks **build (release)** and
**run on board (release, JTAG load + start)** and the launch configurations **Hazard3 Release (OpenOCD + gdb)**
and **Hazard3 Release (Cortex-Debug)** use `build-release/`. Debugging optimised code works, but the compiler
has moved, merged and removed code:

* stepping jumps back and forth between lines, and some lines cannot take a breakpoint;
* local variables are kept in registers or computed away and show as `<optimized out>`; `volatile` and
  global variables can always be watched;
* small functions are inlined: no breakpoint in them, no own frame in the call stack;
* `stepi` and the disassembly view (or `<name>.lst`) always show what really runs.

## Settings

* `F_CPU` (CMake cache variable, default `50000000`): CPU clock in Hz, passed to the code as `F_CPU`
  (`-DF_CPU=50000000u`). The UART runs on the same clock. Change with `cmake -B build -DF_CPU=...`.
* `RISCV_TOOLCHAIN` (`auto`, `gcc`, `clang`) and `RISCV_GCC_PREFIX`: see the toolchain file and
  [`hello/README.md`](hello/README.md#toolchain). `auto` takes GCC if one is installed; the NEWLIB projects
  set `gcc`.
* `PRINTF_FLOAT` (NEWLIB, default `ON`): `printf` with `%f`/`%e`/`%g` (`-u _printf_float`, about +13 KiB).
  With `OFF` these conversions print nothing; the code sees `PRINTF_FLOAT=0/1`. Presets `rv32im` and
  `rv32im-nofloat`.
* `SCANF_FLOAT` (NEWLIB, default `OFF`): `scanf` with floating point (`-u _scanf_float`, pulls in `strtod`,
  about +10 KiB).

## Limits

* Freestanding: no C library, no C++ standard headers (clang has none for bare-metal RISC-V), no compiler
  runtime with clang (64-bit division and floating point do not link), no heap.
* NEWLIB: the heap is the RAM between `.bss` and the 4 KiB reserved for the stack (`_sbrk` stops there; the
  stack itself is not checked). There are no files; stdin/stdout/stderr are the UART.
* C++: no exceptions, no RTTI. With libstdc++, errors that would throw (`std::vector::at`, out of memory)
  call `abort()`, and the program stops in `_exit` (`bsp/crt0.S`). See [C++ exceptions](#c-exceptions).
* Destructors of global objects never run.

## C++ exceptions

`throw`, `try` and `catch` are not available in any of the projects, on purpose: on a 64 KiB SRAM the
run-time support for exceptions takes about half of the memory.

### What switches them off

1. **Compiler flags.** The toolchain file compiles all C++ with `-fno-exceptions -fno-unwind-tables`
   (also `-fno-rtti`). `throw`, `try` and `catch` in the code are compile errors.
2. **`bsp/cxx_newlib.cpp`** (NEWLIB projects). The prebuilt libstdc++ is built with exceptions, so its error
   paths throw: a single `std::vector::push_back` references `std::__throw_length_error`, and `operator new`
   throws `std::bad_alloc`. This file replaces those functions and `operator new`/`delete` with versions that
   call `abort()`. Without it, the unwinder, the demangler and `std::string` are linked in and `newlib_cpp`
   overflows the SRAM by about 45 KiB.
3. **Start-up code and linker script.** Exceptions need the unwind tables (`.eh_frame`) and the
   language-specific tables (`.gcc_except_table`) of every function, and the unwinder must be told where
   `.eh_frame` is. GCC's start files `crtbegin.o`/`crtend.o` normally do that; the projects are linked with
   `-nostartfiles` and `bsp/crt0.S`/`bsp/link.ld` do not do it.

### What it costs

Measured with `riscv64-elf-gcc` 16.2, newlib-nano, `-Os`, GCC's own start files:

| Program                                                         | Code size |
|-----------------------------------------------------------------|-----------|
| `printf("hi")`                                                  | 8 KiB     |
| the same plus one `throw std::runtime_error` / `catch`          | 74 KiB: does not fit into the SRAM |
| the same, with a short `__gnu_cxx::__verbose_terminate_handler` | 39 KiB    |

The default terminate handler prints the type of an uncaught exception and links the C++ name demangler
(about 35 KiB); a replacement that only stops the program removes it. The remaining ~31 KiB are the actual
mechanism: the unwinder (`libgcc`), the personality routine and `__cxa_throw` (`libsupc++`), the unwind
tables, and the emergency pool for exception objects, which also takes heap memory at start-up. With
`printf` for floats (`PRINTF_FLOAT`) a program ends up at about 50 KiB, leaving little for heap and stack.

### What would be needed to introduce them

A third mode next to freestanding and `NEWLIB`, e.g. `hazard4edu_firmware(app NEWLIB EXCEPTIONS)`, which:

1. compiles with `-fexceptions` instead of `-fno-exceptions -fno-unwind-tables` (the flags would move from
   the toolchain file into `hazard4edu_firmware()`, like `-ffreestanding` already did);
2. leaves out `bsp/cxx_newlib.cpp`, so that libstdc++'s own `operator new` and `std::__throw_*` throw;
3. adds a short `__gnu_cxx::__verbose_terminate_handler` (e.g. `abort()`) to keep the demangler out;
4. keeps `.eh_frame` and `.gcc_except_table` in `bsp/link.ld` (`KEEP(...)`, so `--gc-sections` does not
   remove them) and registers `.eh_frame` at start-up: either link GCC's `crtbegin.o`/`crtend.o` (around
   `crt0.S`, which then must also call their init code) or call `__register_frame_info()` from `crt0.S`
   before the constructors;
5. is tested on the board with a program that throws through several functions and from a constructor,
   and one with an uncaught exception.

The other projects stay as they are. RTTI (`dynamic_cast`, `typeid`) is independent of this: exceptions
work with `-fno-rtti`, as GCC still emits the type information of thrown types.
