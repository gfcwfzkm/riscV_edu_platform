# Common build settings for firmware running on the hazard4eduMinimal SoC (hdl/systems/hazard4eduMinimal).
#
# Include this after project():
#
#   include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/hazard4eduMinimal.cmake)
#   add_executable(app src/main.c)
#   hazard4edu_firmware(app)            # freestanding: no C/C++ library (GCC or clang)
#   hazard4edu_firmware(app NEWLIB)     # newlib-nano C library, libm, libstdc++ for C++ (GCC only)
#
# Both modes add the board support files from sw/bsp (start-up code, linker script, UART driver), the
# F_CPU definition, the compiler warnings, the .bin/.lst/.map outputs and a "run" target that loads the
# program over JTAG.
#
#   freestanding  -ffreestanding -nostdlib; bsp/memfuncs.c (memcpy, memset, ...), for C++ also
#                 bsp/cxx_support.cpp; with GCC libgcc is linked (soft-float and 64-bit division)
#   NEWLIB        --specs=nano.specs, libc_nano, libm_nano, libgcc, for C++ libstdc++; bsp/syscalls.c
#                 connects stdin/stdout/stderr to the UART and malloc to the free RAM (heap)
include_guard(GLOBAL)

get_filename_component(HAZARD4EDU_SW_DIR ${CMAKE_CURRENT_LIST_DIR}/.. ABSOLUTE)
set(HAZARD4EDU_BSP_DIR ${HAZARD4EDU_SW_DIR}/bsp)
set(SOC_DIR ${HAZARD4EDU_SW_DIR}/../hdl/systems/hazard4eduMinimal CACHE PATH "hazard4eduMinimal SoC folder")

# CPU clock in Hz, passed to the sources as F_CPU (the UART baud generator runs on the same clock).
# Override with e.g. -DF_CPU=25000000
set(F_CPU 50000000 CACHE STRING "CPU clock frequency in Hz")
if(NOT F_CPU MATCHES "^[1-9][0-9]*$")
  message(FATAL_ERROR "F_CPU must be a positive integer in Hz, got '${F_CPU}'")
endif()

# NEWLIB only: newlib-nano's printf leaves out %f/%e/%g unless it is requested at link time. The code
# sees the choice as PRINTF_FLOAT=0/1. scanf with floating point is a separate option: it pulls in
# strtod, another ~10 KiB.
option(PRINTF_FLOAT "NEWLIB programs: printf with floating point (%f, %e, %g)" ON)
option(SCANF_FLOAT  "NEWLIB programs: scanf with floating point (%f, %e, %g)" OFF)

# Build types (presets: rv32im = Debug in build/, rv32im-release = Release in build-release/):
#   Debug       -Og: little optimisation, every line and variable can be followed in the debugger
#   Release     -O2: optimised for speed
#   MinSizeRel  -Os: optimised for size
# All of them keep the debug information (-g3). It stays in the .elf on the PC and is never loaded into
# the SRAM, so it costs nothing on the target and the optimised programs can be debugged as well.
# NDEBUG (assert() off) is set for Release and MinSizeRel.
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release MinSizeRel)
foreach(lang C CXX)
  set(CMAKE_${lang}_FLAGS_DEBUG      "-Og -g3")
  set(CMAKE_${lang}_FLAGS_RELEASE    "-O2 -g3 -DNDEBUG")
  set(CMAKE_${lang}_FLAGS_MINSIZEREL "-Os -g3 -DNDEBUG")
endforeach()
set(CMAKE_ASM_FLAGS_DEBUG      "-g3")
set(CMAKE_ASM_FLAGS_RELEASE    "-g3")
set(CMAKE_ASM_FLAGS_MINSIZEREL "-g3")

function(hazard4edu_firmware target)
  cmake_parse_arguments(PARSE_ARGV 1 arg "NEWLIB" "" "")
  set(linker_script ${HAZARD4EDU_BSP_DIR}/link.ld)
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)

  target_sources(${target} PRIVATE
    ${HAZARD4EDU_BSP_DIR}/crt0.S
    ${HAZARD4EDU_BSP_DIR}/uart16550.c)
  target_include_directories(${target} PRIVATE ${HAZARD4EDU_BSP_DIR})

  if(arg_NEWLIB)
    # ------------------------------------------------------------------------ newlib-nano (+ libstdc++)
    if(NOT RISCV_COMPILER_KIND STREQUAL "gcc")
      message(FATAL_ERROR "${target} needs the C library (newlib) and a RISC-V GCC, e.g. the packages "
        "riscv64-elf-gcc and riscv64-elf-newlib. Found only ${RISCV_COMPILER_KIND}; "
        "the freestanding programs (hello, hello_cpp) build without them.")
    endif()
    # A GCC without newlib (e.g. riscv64-elf-gcc without riscv64-elf-newlib) prints only the file name
    execute_process(
      COMMAND ${CMAKE_C_COMPILER} -march=${RISCV_ARCH} -mabi=${RISCV_ABI} -print-file-name=libc_nano.a
      OUTPUT_VARIABLE libc_nano OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(NOT IS_ABSOLUTE "${libc_nano}")
      message(FATAL_ERROR "${target} needs newlib-nano for ${RISCV_ARCH}/${RISCV_ABI}, but ${CMAKE_C_COMPILER} "
        "has none (e.g. install riscv64-elf-newlib). The freestanding programs (hello, hello_cpp) build without it.")
    endif()
    message(STATUS "${target}: newlib-nano ${libc_nano}")
    target_sources(${target} PRIVATE ${HAZARD4EDU_BSP_DIR}/syscalls.c)
    if(CXX IN_LIST languages)
      # Keeps libstdc++'s exception handling out of the program (see the file)
      target_sources(${target} PRIVATE ${HAZARD4EDU_BSP_DIR}/cxx_newlib.cpp)
    endif()
    # nano.specs also selects newlib-nano's headers, so it is needed when compiling too
    target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C,CXX>:--specs=nano.specs>)
    target_link_options(${target} PRIVATE --specs=nano.specs)
    target_link_libraries(${target} PRIVATE m)
    if(PRINTF_FLOAT)
      target_link_options(${target} PRIVATE -Wl,-u,_printf_float)
      target_compile_definitions(${target} PRIVATE PRINTF_FLOAT=1)
    else()
      target_compile_definitions(${target} PRIVATE PRINTF_FLOAT=0)
    endif()
    if(SCANF_FLOAT)
      target_link_options(${target} PRIVATE -Wl,-u,_scanf_float)
    endif()
    set(mode "newlib-nano, PRINTF_FLOAT=${PRINTF_FLOAT}, SCANF_FLOAT=${SCANF_FLOAT}")
  else()
    # ------------------------------------------------------------------------ freestanding
    target_sources(${target} PRIVATE ${HAZARD4EDU_BSP_DIR}/memfuncs.c)
    # Keep the compiler from turning the loops in memset/memcpy into calls to memset/memcpy
    set_source_files_properties(${HAZARD4EDU_BSP_DIR}/memfuncs.c TARGET_DIRECTORY ${target} PROPERTIES
      COMPILE_OPTIONS "-fno-builtin;$<$<C_COMPILER_ID:GNU>:-fno-tree-loop-distribute-patterns>")
    if(CXX IN_LIST languages)
      target_sources(${target} PRIVATE ${HAZARD4EDU_BSP_DIR}/cxx_support.cpp)
    endif()
    target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C,CXX>:-ffreestanding>)
    target_link_options(${target} PRIVATE -nostdlib)
    if(RISCV_COMPILER_KIND STREQUAL "gcc")
      target_link_libraries(${target} PRIVATE gcc)   # compiler runtime: soft-float, 64-bit division
    endif()
    set(mode "freestanding")
  endif()

  set_target_properties(${target} PROPERTIES
    SUFFIX ".elf"
    LINK_DEPENDS ${linker_script}
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    C_EXTENSIONS OFF)
  target_compile_definitions(${target} PRIVATE F_CPU=${F_CPU}u)
  target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C,CXX>:-Wall -Wextra>)
  target_link_options(${target} PRIVATE -T${linker_script} -Wl,-Map=$<TARGET_FILE_DIR:${target}>/${target}.map)

  add_custom_command(TARGET ${target} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${target}> $<TARGET_FILE_DIR:${target}>/${target}.bin
    COMMAND ${CMAKE_OBJDUMP} -d -S -C $<TARGET_FILE:${target}> > $<TARGET_FILE_DIR:${target}>/${target}.lst
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${target}>
    VERBATIM)

  # Load and start the program over JTAG via the SoC's Makefile (OpenOCD; the bitstream must be loaded)
  add_custom_target(run
    COMMAND make -C ${SOC_DIR} run ELF=$<TARGET_FILE:${target}>
    DEPENDS ${target}
    USES_TERMINAL
    VERBATIM)

  message(STATUS "${target}: ${CMAKE_BUILD_TYPE}, ${RISCV_COMPILER_KIND}, -march=${RISCV_ARCH} -mabi=${RISCV_ABI}, F_CPU=${F_CPU} Hz, ${mode}")
endfunction()
