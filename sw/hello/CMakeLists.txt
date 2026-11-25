# Hello world firmware (C) for the hazard4eduMinimal SoC (hdl/systems/hazard4eduMinimal).
#
#   cmake --preset rv32im          (or: cmake -B build -DCMAKE_TOOLCHAIN_FILE=../cmake/riscv-rv32im.cmake)
#   cmake --build build            -> build/hello.elf, hello.bin, hello.lst
#   cmake --build build --target run   load hello.elf over JTAG and start it (needs the bitstream loaded)
#
# The toolchain file and the build settings are shared with the other projects in sw/ (sw/cmake),
# the start-up code, linker script and UART driver come from sw/bsp.
cmake_minimum_required(VERSION 3.20)

if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../cmake/riscv-rv32im.cmake)
endif()

project(hello LANGUAGES C ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)

add_executable(hello
  src/main.c
  src/misa.c
)
hazard4edu_firmware(hello)
