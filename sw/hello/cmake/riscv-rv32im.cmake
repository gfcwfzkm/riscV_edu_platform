# CMake toolchain file: bare-metal RV32IM (no compressed instructions), ilp32 ABI.
#
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/riscv-rv32im.cmake
#
# RISCV_TOOLCHAIN selects the compiler:
#   auto  (default) a RISC-V GCC if one is found on PATH, otherwise clang
#   gcc   riscv*-elf-gcc; RISCV_GCC_PREFIX can name it, e.g. -DRISCV_GCC_PREFIX=riscv64-unknown-elf-
#   clang clang --target=riscv32-unknown-elf with ld.lld and llvm-objcopy (no libc, no runtime library)
#
# The C extension stays off: hazard4eduMinimal is built without it (with C the core does not reach
# 50 MHz, see hdl/systems/hazard4eduMinimal/README.md), so -march must not contain "c".

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)
# Without libc the test programs cannot be linked as executables
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(RISCV_ARCH "rv32im_zicsr" CACHE STRING "RISC-V -march (no 'c': the SoC has no compressed instructions)")
set(RISCV_ABI  "ilp32"        CACHE STRING "RISC-V -mabi")
set(RISCV_TOOLCHAIN "auto"    CACHE STRING "auto, gcc or clang")
set_property(CACHE RISCV_TOOLCHAIN PROPERTY STRINGS auto gcc clang)
# Pass the settings on to the try_compile projects
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES RISCV_ARCH RISCV_ABI RISCV_TOOLCHAIN RISCV_GCC_PREFIX)

if(RISCV_ARCH MATCHES "^rv32[a-z]*c")
  message(FATAL_ERROR "RISCV_ARCH=${RISCV_ARCH} enables compressed instructions, which hazard4eduMinimal does not support")
endif()

# ---------------------------------------------------------------------------- find a GCC
if(NOT RISCV_TOOLCHAIN STREQUAL "clang" AND NOT RISCV_GCC_PREFIX)
  foreach(prefix riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf- riscv64-elf- riscv32-elf-)
    find_program(_riscv_gcc ${prefix}gcc NO_CACHE)
    if(_riscv_gcc)
      set(RISCV_GCC_PREFIX ${prefix})
      break()
    endif()
  endforeach()
endif()

if(RISCV_TOOLCHAIN STREQUAL "gcc" AND NOT RISCV_GCC_PREFIX)
  message(FATAL_ERROR "RISCV_TOOLCHAIN=gcc, but no riscv*-elf-gcc was found on PATH")
endif()

if(RISCV_GCC_PREFIX AND NOT RISCV_TOOLCHAIN STREQUAL "clang")
  # ---------------------------------------------------------------------------- GCC
  set(RISCV_COMPILER_KIND gcc)
  set(CMAKE_C_COMPILER   ${RISCV_GCC_PREFIX}gcc)
  set(CMAKE_ASM_COMPILER ${RISCV_GCC_PREFIX}gcc)
  set(CMAKE_OBJCOPY      ${RISCV_GCC_PREFIX}objcopy CACHE FILEPATH "")
  set(CMAKE_OBJDUMP      ${RISCV_GCC_PREFIX}objdump CACHE FILEPATH "")
  set(CMAKE_SIZE         ${RISCV_GCC_PREFIX}size    CACHE FILEPATH "")
  set(_target_flags "")
  set(_link_flags "-nostartfiles -nostdlib -Wl,--gc-sections")
  set(_libs "-lgcc")
else()
  # ---------------------------------------------------------------------------- clang
  set(RISCV_COMPILER_KIND clang)
  set(CMAKE_C_COMPILER   clang)
  set(CMAKE_ASM_COMPILER clang)
  set(CMAKE_C_COMPILER_TARGET   riscv32-unknown-elf)
  set(CMAKE_ASM_COMPILER_TARGET riscv32-unknown-elf)
  find_program(CMAKE_OBJCOPY llvm-objcopy REQUIRED)
  find_program(CMAKE_OBJDUMP llvm-objdump REQUIRED)
  find_program(CMAKE_SIZE    llvm-size    REQUIRED)
  set(_target_flags "")
  set(_link_flags "-fuse-ld=lld -nostartfiles -nostdlib -Wl,--gc-sections")
  set(_libs "")
endif()

set(CMAKE_C_FLAGS_INIT   "${_target_flags} -march=${RISCV_ARCH} -mabi=${RISCV_ABI} -mcmodel=medlow -ffreestanding -ffunction-sections -fdata-sections")
set(CMAKE_ASM_FLAGS_INIT "${_target_flags} -march=${RISCV_ARCH} -mabi=${RISCV_ABI}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_link_flags}")
set(CMAKE_C_STANDARD_LIBRARIES "${_libs}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
