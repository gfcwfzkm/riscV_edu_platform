# newlib_cpp: firmware for the hazard4eduMinimal SoC that uses the C library newlib-nano and libstdc++.
# Needs a RISC-V GCC with newlib (e.g. the packages riscv64-elf-gcc and riscv64-elf-newlib); the
# freestanding demos hello and hello_cpp build without them.
#
#   cmake --preset rv32im          (or: cmake -B build -DCMAKE_TOOLCHAIN_FILE=../cmake/riscv-rv32im.cmake)
#   cmake --build build            -> build/newlib_cpp.elf, newlib_cpp.bin, newlib_cpp.lst
#   cmake --build build --target run   load newlib_cpp.elf over JTAG and start it (needs the bitstream loaded)
#
# -DPRINTF_FLOAT=OFF leaves %f/%e/%g out of printf and scanf (smaller program).
cmake_minimum_required(VERSION 3.20)

if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../cmake/riscv-rv32im.cmake)
endif()
# newlib needs GCC: do not fall back to clang
set(RISCV_TOOLCHAIN gcc CACHE STRING "auto, gcc or clang")

project(newlib_cpp LANGUAGES C CXX ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)

add_executable(newlib_cpp
  src/main.cpp
)
set_target_properties(newlib_cpp PROPERTIES CXX_STANDARD 23 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS OFF)
hazard4edu_firmware(newlib_cpp NEWLIB)
