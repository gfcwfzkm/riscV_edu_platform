# newlib_c – firmware with the C library for hazard4eduMinimal

C with the newlib-nano C library: `printf` (also with `float`/`double`), `snprintf`, `sqrt`/`sin` from
`libm` and `malloc`. It prints the results and how many cycles `sqrt` takes in software floating point
(the core has no FPU), then `tick <n>` once per second.

Needs a RISC-V GCC with newlib, on Arch Linux the packages `riscv64-elf-gcc` and `riscv64-elf-newlib`
(the freestanding demos `hello` and `hello_cpp` build without them). See [`sw/README.md`](../README.md) for
what `hazard4edu_firmware(... NEWLIB)` adds and for the options.

```bash
cmake --preset rv32im           # printf with %f; or: cmake --preset rv32im-nofloat (smaller)
cmake --build build             # build/newlib_c.elf, .bin, .lst, .map
cmake --build build --target run
# optimised (-O2): cmake --preset rv32im-release, then the same with build-release
```

Output on the UART, 115200 8N1, as for [`hello`](../hello/README.md); the VS Code configurations in
`.vscode/` use `build/newlib_c.elf`.
