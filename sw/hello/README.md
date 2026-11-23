# hello – firmware example for hazard4eduMinimal

Bare-metal hello world for the [hazard4eduMinimal](../../hdl/systems/hazard4eduMinimal) SoC on the GECKO5Education
(Hazard3 RV32IM, 64 KiB SRAM at `0x0`, 16550 UART at `0x10000`, 50 MHz). It prints a greeting and `misa`, then
`tick <n>` about once per second, and echoes characters it receives.

| File                      | Content                                                                         |
|---------------------------|---------------------------------------------------------------------------------|
| `cmake/riscv-rv32im.cmake`| toolchain file: `-march=rv32im_zicsr -mabi=ilp32`, GCC if found, otherwise clang |
| `src/crt0.S`              | start-up: `gp`, `sp` = `0x10000`, `mtvec`, counters on, clear `.bss`, `main`    |
| `src/link.ld`             | everything in the SRAM, `_start` at the reset vector `0x0`                      |
| `src/uart16550.[ch]`      | polling UART driver, divisor = 50 MHz / (16 × baud) = 27 for 115200             |
| `src/main.c`              | the program                                                                     |
| `.vscode/`                | build tasks and two debug configurations (open this folder in VS Code)          |

**No compressed instructions:** the SoC is built without the C extension because of an open predecode bug in
the core (`hdl/modules/hazard4edu/doc/NOTES.md`). The toolchain file refuses a `-march` with `c`.

## Toolchain

* **clang** (tested, clang 23): `clang --target=riscv32-unknown-elf` with `ld.lld`, `llvm-objcopy`, `llvm-objdump`,
  `llvm-size`. No libc or runtime library is used.
* **GCC** (optional, not tested yet): any of `riscv32-unknown-elf-`, `riscv64-unknown-elf-`, `riscv-none-elf-`,
  `riscv64-elf-`, `riscv32-elf-gcc` on `PATH`, or `-DRISCV_GCC_PREFIX=<prefix>`. It is linked against its `libgcc`.

`RISCV_TOOLCHAIN=auto` (default) takes GCC if one is found, else clang. The presets `rv32im-clang` and
`rv32im-gcc` force one of them.

## Build and run

```bash
cmake --preset rv32im          # or: cmake -B build   (the toolchain file is picked up by default)
cmake --build build            # build/hello.elf, hello.bin, hello.lst, hello.map
```

The FPGA must be configured with the SoC first (`make -C ../../hdl/systems/hazard4eduMinimal load`, or the VS Code
task *load bitstream (FPGA SRAM)*). Then:

```bash
cmake --build build --target run    # = make -C ../../hdl/systems/hazard4eduMinimal run ELF=build/hello.elf
```

Output: the board's second FT2232H channel (the second `ttyUSB` of the `Dual RS232-HS` device), 115200 8N1,
e.g. `picocom -b 115200 /dev/ttyUSB3`.

## Debugging in VS Code

Open `sw/hello` as the workspace folder. Extensions: *C/C++* (`ms-vscode.cpptools`), optionally *CMake Tools* and
*Cortex-Debug* (`marus25.cortex-debug`).

* **Hazard3 (OpenOCD + gdb)** (`cppdbg`): the `openocd` task builds the program and starts
  `make -C ../../hdl/systems/hazard4eduMinimal openocd` in the background. gdb then connects with
  `target extended-remote localhost:3333`, does `monitor reset halt`, loads the ELF and stops at `main`.
  OpenOCD is stopped again when the session ends.
* **Hazard3 (Cortex-Debug)**: Cortex-Debug starts OpenOCD itself (path from `cortex-debug.openocdPath` in
  `.vscode/settings.json`, `/opt/oss-cad-suite/bin/openocd`) with `openocd/gecko5-hazard3.cfg`.

Both need a gdb with RISC-V support. Set `miDebuggerPath` / `gdbPath` in `launch.json` if `gdb` is not
the right one:

| System              | gdb                                                                              |
|---------------------|----------------------------------------------------------------------------------|
| Arch Linux          | `gdb` already supports all architectures (`set architecture riscv:rv32` works); `riscv64-elf-gdb` also exists |
| Debian / Ubuntu     | `sudo apt install gdb-multiarch`, then use `gdb-multiarch`                         |
| Windows / macOS     | `riscv-none-elf-gdb` from the xPack RISC-V toolchain                               |

Check with `gdb -batch -ex 'set architecture riscv:rv32'`.

The core has 2 hardware triggers. Breakpoints in the SRAM are software breakpoints (`ebreak`), so there is no
practical limit. After gdb detaches, OpenOCD leaves the hart **halted**. To let the program continue, use
`resume` in OpenOCD's telnet (`:4444`) or run the program again.

Tested on the board (2026-11-23, clang 23, GNU gdb 18.1, OpenOCD from the OSS CAD Suite), with the same command
sequence as the `cppdbg` configuration run through gdb's MI. Results: reset-halt and load, a temporary breakpoint
at `main`, `next`/`step`/`stepi`, interrupting the running program, a breakpoint in `uart_put_dec`, and
writing `counter`. Not yet clicked through in the VS Code UI.
