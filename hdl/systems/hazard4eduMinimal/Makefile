# Build and load the hazard4eduMinimal SoC (Hazard3 + JTAG debug + SRAM + UART)
# on the GECKO5Education board (Lattice ECP5 LFE5U-85, CABGA381).
#
#   make            synthesize, place & route and pack the bitstream (build/hazard4eduMinimal.bit)
#   make load       load the bitstream into the FPGA's configuration SRAM (lost at power-off)
#   make flash      write the bitstream to the board's SPI flash (persistent)
#   make openocd    start OpenOCD on the board's JTAG port (gdb :3333, telnet :4444)
#   make run ELF=x  load an rv32im ELF into the SRAM over JTAG and start it at the reset vector 0x0
#   make timing     show the clock frequency and utilisation reached by place & route
#   make clean      remove the build folder
#
# Tools: Yosys, nextpnr-ecp5, ecppack, openFPGALoader and OpenOCD, e.g. from the OSS CAD Suite.
# If OSS_CAD_SUITE points to an installation, its bin/ is put in front of PATH.
#
# The source files are collected like hdl/systems/createScripts does it: scripts/modules.txt lists
# the modules, and each module's scripts/filesVerilog.txt lists its Verilog files.

OSS_CAD_SUITE ?= /opt/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE)/bin),)
export PATH := $(OSS_CAD_SUITE)/bin:$(PATH)
endif

YOSYS          ?= yosys
NEXTPNR        ?= nextpnr-ecp5
ECPPACK        ?= ecppack
OPENFPGALOADER ?= openFPGALoader
OPENOCD        ?= openocd

TOP      := hazard4eduMinimal
BUILD    := build
LPF      := scripts/gecko5.lpf
OCD_CFG  := openocd/gecko5-hazard3.cfg

# FPGA: LFE5U-85F in the CABGA381 package; the board clock is 50 MHz
DEVICE        ?= --85k --package CABGA381 --speed 6
FREQ_MHZ      ?= 50
NEXTPNR_FLAGS ?= --seed 1
JOBS          ?= $(shell nproc 2>/dev/null || echo 4)

# ---------------------------------------------------------------------------- sources
MODULES_DIR := ../../modules
MODULES     := $(strip $(shell cat scripts/modules.txt))
MODULE_SRCS := $(foreach m,$(MODULES),$(addprefix $(MODULES_DIR)/$(m)/,$(strip $(shell cat $(MODULES_DIR)/$(m)/scripts/filesVerilog.txt))))
SYSTEM_SRCS := verilog/wishBoneSharedBusTop.v verilog/toplevel.v
SRCS        := $(MODULE_SRCS) $(SYSTEM_SRCS)
# Hazard3 includes its configuration headers (*.vh) from its verilog folder
INCLUDES    := $(foreach m,$(MODULES),-I$(MODULES_DIR)/$(m)/verilog)

# ---------------------------------------------------------------------------- programmer
# Several FT2232 probes may be connected. The GECKO5Education's FT2232H reports the product string
# "Dual RS232-HS"; the first such device selects the board. Override with e.g. GECKO_BUSDEV=3:4
# (USB bus:device, see 'openFPGALoader --scan-usb' or 'lsusb'), or set it empty to let
# openFPGALoader pick the first FT2232.
GECKO_USB_PRODUCT ?= Dual RS232-HS
GECKO_BUSDEV ?= $(shell for d in /sys/bus/usb/devices/*; do \
	  [ "$$(cat $$d/idVendor 2>/dev/null):$$(cat $$d/idProduct 2>/dev/null)" = "0403:6010" ] && \
	  [ "$$(cat $$d/product 2>/dev/null)" = "$(GECKO_USB_PRODUCT)" ] && \
	  echo "$$(cat $$d/busnum):$$(cat $$d/devnum)" && break; done)
LOADER_FLAGS := -c ft2232 $(if $(GECKO_BUSDEV),--busdev-num $(GECKO_BUSDEV))

# ---------------------------------------------------------------------------- rules
.PHONY: all bit load flash openocd run timing clean help
.DELETE_ON_ERROR:

all: bit
bit: $(BUILD)/$(TOP).bit

$(BUILD):
	mkdir -p $@

$(BUILD)/$(TOP).json: $(SRCS) scripts/modules.txt | $(BUILD)
	$(YOSYS) -l $(BUILD)/yosys.log -q -p "read_verilog -sv $(INCLUDES) $(SRCS); synth_ecp5 -top $(TOP) -json $@"

$(BUILD)/$(TOP).config: $(BUILD)/$(TOP).json $(LPF)
	$(NEXTPNR) $(DEVICE) --freq $(FREQ_MHZ) --threads $(JOBS) $(NEXTPNR_FLAGS) \
	  --json $< --lpf $(LPF) --textcfg $@ --log $(BUILD)/nextpnr.log --quiet
	@$(MAKE) --no-print-directory timing

$(BUILD)/$(TOP).bit: $(BUILD)/$(TOP).config
	$(ECPPACK) --compress --input $< --bit $@

load: $(BUILD)/$(TOP).bit
	$(OPENFPGALOADER) $(LOADER_FLAGS) $<

flash: $(BUILD)/$(TOP).bit
	$(OPENFPGALOADER) $(LOADER_FLAGS) -f $<

openocd:
	$(OPENOCD) -f $(OCD_CFG)

run:
	@test -n "$(ELF)" || { echo "usage: make run ELF=path/to/program.elf"; exit 2; }
	$(OPENOCD) -f $(OCD_CFG) -c init -c halt -c "load_image $(ELF)" -c "verify_image $(ELF)" \
	  -c "reg pc 0" -c resume -c shutdown

timing:
	@grep -E 'Max frequency for clock' $(BUILD)/nextpnr.log | tail -n 1 || echo "run 'make' first"
	@grep -E 'Total LUT4s:|Total DFFs:|DP16KD:|MULT18X18D:' $(BUILD)/nextpnr.log | head -n 4 | sed 's/^Info: *//' || true

clean:
	rm -rf $(BUILD)

help:
	@sed -n '1,/^$$/p' Makefile
