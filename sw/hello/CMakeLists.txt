# Hello world firmware for the hazard4eduMinimal SoC (hdl/systems/hazard4eduMinimal).
#
#   cmake --preset rv32im          (or: cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/riscv-rv32im.cmake)
#   cmake --build build            -> build/hello.elf, hello.bin, hello.lst
#   cmake --build build --target run   load hello.elf over JTAG and start it (needs the bitstream loaded)
cmake_minimum_required(VERSION 3.20)

if(NOT CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/cmake/riscv-rv32im.cmake)
endif()

project(hello LANGUAGES C ASM)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()
# -Og keeps the code small enough and still easy to step through
set(CMAKE_C_FLAGS_DEBUG "-Og -g3")
set(CMAKE_ASM_FLAGS_DEBUG "-g3")

set(SOC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../hdl/systems/hazard4eduMinimal CACHE PATH "hazard4eduMinimal SoC folder")
set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/src/link.ld)

add_executable(hello
  src/crt0.S
  src/main.c
  src/misa.c
  src/uart16550.c
)
set_target_properties(hello PROPERTIES SUFFIX ".elf" LINK_DEPENDS ${LINKER_SCRIPT})
target_compile_options(hello PRIVATE $<$<COMPILE_LANGUAGE:C>:-Wall -Wextra -std=c11>)
target_link_options(hello PRIVATE -T${LINKER_SCRIPT} -Wl,-Map=$<TARGET_FILE_DIR:hello>/hello.map)

add_custom_command(TARGET hello POST_BUILD
  COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:hello> $<TARGET_FILE_DIR:hello>/hello.bin
  COMMAND ${CMAKE_OBJDUMP} -d -S $<TARGET_FILE:hello> > $<TARGET_FILE_DIR:hello>/hello.lst
  COMMAND ${CMAKE_SIZE} $<TARGET_FILE:hello>
  VERBATIM)

# Load and start the program over JTAG via the SoC's Makefile (OpenOCD)
add_custom_target(run
  COMMAND make -C ${SOC_DIR} run ELF=$<TARGET_FILE:hello>
  DEPENDS hello
  USES_TERMINAL
  VERBATIM)

message(STATUS "hazard4eduMinimal firmware: ${RISCV_COMPILER_KIND}, -march=${RISCV_ARCH} -mabi=${RISCV_ABI}")
