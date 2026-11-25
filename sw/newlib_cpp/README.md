# newlib_cpp – firmware with the C/C++ library for hazard4eduMinimal

C++20 with libstdc++ on top of newlib-nano: `std::array` with `std::sort` and `std::accumulate`,
`std::vector` on the heap, `std::sqrt`, `printf` from the constructor of a global object; then `tick <n>`
once per second. Exceptions and RTTI stay off; `bsp/cxx_newlib.cpp` keeps libstdc++'s exception handling
out of the program (it would not fit into the 64 KiB SRAM).

Needs a RISC-V GCC with newlib, on Arch Linux the packages `riscv64-elf-gcc` and `riscv64-elf-newlib`
(the freestanding demos `hello` and `hello_cpp` build without them). See [`sw/README.md`](../README.md) for
what `hazard4edu_firmware(... NEWLIB)` adds and for the options.

```bash
cmake --preset rv32im           # printf with %f; or: cmake --preset rv32im-nofloat (smaller)
cmake --build build             # build/newlib_cpp.elf, .bin, .lst, .map
cmake --build build --target run
# optimised (-O2): cmake --preset rv32im-release, then the same with build-release
```

Output on the UART, 115200 8N1, as for [`hello`](../hello/README.md); the VS Code configurations in
`.vscode/` use `build/newlib_cpp.elf`.
