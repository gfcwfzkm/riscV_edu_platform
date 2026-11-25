# Hello world in C++20 for the hazard4eduMinimal SoC (hdl/systems/hazard4eduMinimal).
#
#   cmake --preset rv32im          (or: cmake -B build -DCMAKE_TOOLCHAIN_FILE=../cmake/riscv-rv32im.cmake)
#   cmake --build build            -> build/hello_cpp.elf, hello_cpp.bin, hello_cpp.lst
#   cmake --build build --target run   load hello_cpp.elf over JTAG and start it (needs the bitstream loaded)
#
# Same toolchain file, build settings and board support files as sw/hello (sw/cmake, sw/bsp).
cmake_minimum_required(VERSION 3.20)

if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/../cmake/riscv-rv32im.cmake)
endif()

project(hello_cpp LANGUAGES C CXX ASM)

include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)

add_executable(hello_cpp
  src/main.cpp
)
set_target_properties(hello_cpp PROPERTIES CXX_STANDARD 23 CXX_STANDARD_REQUIRED ON CXX_EXTENSIONS OFF)
hazard4edu_firmware(hello_cpp)
