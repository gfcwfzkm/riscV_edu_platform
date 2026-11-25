# newlib_c: firmware for the hazard4eduMinimal SoC that uses the C library newlib-nano.
# Needs a RISC-V GCC with newlib (e.g. the packages riscv64-elf-gcc and riscv64-elf-newlib); the
# freestanding demos hello and hello_cpp build without them.
#
#   cmake --preset rv32im          (or: cmake -B build -DCMAKE_TOOLCHAIN_FILE=../cmake/riscv-rv32im.cmake)
#   cmake --build build            -> build/newlib_c.elf, newlib_c.bin, newlib_c.lst
#   cmake --build build --target run   load newlib_c.elf over JTAG and start it (needs the bitstream loaded)
#
# -DPRINTF_FLOAT=OFF leaves %f/%e/%g out of printf and scanf (smaller program).
cmake_minimum_required(VERSION 3.20)

if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../cmake/riscv-rv32im.cmake)
endif()
# newlib needs GCC: do not fall back to clang
set(RISCV_TOOLCHAIN gcc CACHE STRING "auto, gcc or clang")

project(newlib_c LANGUAGES C ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)

add_executable(newlib_c
  src/main.c
)
hazard4edu_firmware(newlib_c NEWLIB)
