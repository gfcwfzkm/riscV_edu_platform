# Build and load the hazard4eduMinimal SoC (Hazard3 + JTAG debug + SRAM + UART)
# on the GECKO5Education board (Lattice ECP5 LFE5U-85, CABGA381).
#
#   make            synthesize, place & route and pack the bitstream (build/<HDL>[/<BUS>]/hazard4eduMinimal.bit)
#   make load       load the bitstream into the FPGA's configuration SRAM (lost at power-off)
#   make flash      write the bitstream to the board's SPI flash (persistent)
#   make openocd    start OpenOCD on the board's JTAG port (gdb :3333, telnet :4444)
#   make run ELF=x  load an rv32im ELF into the SRAM over JTAG and start it at the reset vector 0x0
#   make console    open the board's UART in minicom (115200 8N1, quit with Ctrl+A X)
#   make gdb-tdesc  regenerate openocd/hazard4eduMinimal-tdesc.xml (gdb register list without the
#                   CSRs this core does not implement; needs the bitstream loaded, no other OpenOCD)
#   make timing     show the clock frequency and utilisation reached by place & route
#   make clean      remove the build folder
#
# HDL=vhdl (default) builds from vhdl/toplevel.vhdl and the modules' VHDL sources 
# (GHDL synthesizes them to a Verilog netlist for Yosys),
# HDL=verilog builds from verilog/toplevel.v and the modules' Verilog sources
# BUS=crossbar (default) or BUS=shared selects its Wishbone bus
#
# Tools: Yosys, nextpnr-ecp5, ecppack, openFPGALoader and OpenOCD (and GHDL for HDL=vhdl), e.g.
# from the OSS CAD Suite. If OSS_CAD_SUITE points to an installation, its bin/ is put in front of PATH.
#
# The source files are collected like hdl/systems/createScripts does it: scripts/modules.txt lists
# the modules, and each module's scripts/filesVerilog.txt / scripts/filesVhdl.txt lists its
# Verilog / VHDL files in dependency order.

OSS_CAD_SUITE ?= /opt/oss-cad-suite
ifneq ($(wildcard $(OSS_CAD_SUITE)/bin),)
export PATH := $(OSS_CAD_SUITE)/bin:$(PATH)
endif

HDL            ?= vhdl
BUS            ?= crossbar
GHDL           ?= ghdl
YOSYS          ?= yosys
NEXTPNR        ?= nextpnr-ecp5
ECPPACK        ?= ecppack
OPENFPGALOADER ?= openFPGALoader
OPENOCD        ?= openocd
GDB            ?= gdb

TOP      := hazard4eduMinimal
BUILD    := build/$(HDL)
LPF     := scripts/gecko5.lpf
OCD_CFG  := openocd/gecko5-hazard3.cfg
TDESC    := openocd/hazard4eduMinimal-tdesc.xml

# FPGA: LFE5U-85F in the CABGA381 package; the board clock is 50 MHz
DEVICE        ?= --85k --package CABGA381 --speed 6
FREQ_MHZ      ?= 50
NEXTPNR_FLAGS ?= --seed 1
JOBS          ?= $(shell nproc 2>/dev/null || echo 4)

# ---------------------------------------------------------------------------- sources
MODULES_DIR := ../../modules
MODULES     := $(strip $(shell cat scripts/modules.txt))
module_files = $(foreach m,$(MODULES),$(addprefix $(MODULES_DIR)/$(m)/,$(strip $(shell cat $(MODULES_DIR)/$(m)/scripts/$(1)))))

ifeq ($(BUS),crossbar)
BUS_FLAGS   := -D BUS_CROSSBAR
BUS_SRCS    := verilog/wishBoneSlaveArbiter.v verilog/wishBoneCrossbarBusTop.v
BUS_GENERIC := true
else ifeq ($(BUS),shared)
BUS_SRCS    := verilog/wishBoneSharedBusTop.v
BUS_GENERIC := false
else
$(error BUS must be 'crossbar' or 'shared', not '$(BUS)')
endif

ifeq ($(HDL),verilog)
BUILD    := build/$(HDL)/$(BUS)
SRCS     := $(call module_files,filesVerilog.txt) $(BUS_SRCS) verilog/toplevel.v
# Hazard3 includes its configuration headers (*.vh) from its verilog folder
INCLUDES := $(foreach m,$(MODULES),-I$(MODULES_DIR)/$(m)/verilog)
else ifeq ($(HDL),vhdl)
BUILD    := build/$(HDL)/$(BUS)
SRCS     := $(call module_files,filesVhdl.txt) vhdl/wishBoneSlaveArbiter.vhdl vhdl/wishBoneCrossbarBusTop.vhdl vhdl/wishBoneSharedBusTop.vhdl vhdl/toplevel.vhdl
GHDL_WORK := $(BUILD)/ghdl-work
else
$(error HDL must be 'verilog' or 'vhdl', not '$(HDL)')
endif

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
# The UART is the FT2232H's second channel (interface 1). The by-id name stays the same however many
# USB serial adapters are connected; override with e.g. UART_DEV=/dev/ttyUSB3.
MINICOM   ?= minicom
UART_DEV  ?= /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0
UART_BAUD ?= 115200

LOADER_FLAGS := -c ft2232 $(if $(GECKO_BUSDEV),--busdev-num $(GECKO_BUSDEV))

# ---------------------------------------------------------------------------- rules
.PHONY: all bit load flash openocd run console gdb-tdesc timing clean help
.DELETE_ON_ERROR:

all: bit
bit: $(BUILD)/$(TOP).bit

$(BUILD):
	mkdir -p $@

ifeq ($(HDL),verilog)
$(BUILD)/$(TOP).json: $(SRCS) scripts/modules.txt | $(BUILD)
	$(YOSYS) -l $(BUILD)/yosys.log -q -p "read_verilog -sv $(BUS_FLAGS) $(INCLUDES) $(SRCS); synth_ecp5 -top $(TOP) -json $@"
else
# GHDL analyses the VHDL sources in order and writes a Verilog netlist of the design, which Yosys
# then maps to the ECP5 (the JTAGG primitive stays a black box until synth_ecp5 maps it).
$(BUILD)/$(TOP).json: $(SRCS) scripts/modules.txt | $(BUILD)
	mkdir -p $(GHDL_WORK)
	$(GHDL) -a --std=08 --workdir=$(GHDL_WORK) $(SRCS)
	$(GHDL) --synth --std=08 --workdir=$(GHDL_WORK) -gUSE_CROSSBAR=$(BUS_GENERIC) --out=verilog $(TOP) > $(BUILD)/$(TOP).ghdl.v 2> $(BUILD)/ghdl.log \
	  || { cat $(BUILD)/ghdl.log; exit 1; }
	$(YOSYS) -l $(BUILD)/yosys.log -q -p "read_verilog $(BUILD)/$(TOP).ghdl.v; synth_ecp5 -top $(TOP) -json $@"
endif

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

# scripts/minirc.gecko5 sets 8N1 without flow control; -D and -b override its port and baud rate
console:
	@test -e $(UART_DEV) || { echo "UART $(UART_DEV) not found: is the board connected? Set UART_DEV=/dev/ttyUSBn to choose another port."; exit 1; }
	$(MINICOM) -D $(UART_DEV) -b $(UART_BAUD) $(CURDIR)/scripts/minirc.gecko5

# Asks the running SoC which registers can be read and writes gdb's target description without the
# others (see scripts/gdb_tdesc.py). Regenerate it when the CPU configuration changes.
gdb-tdesc:
	python3 scripts/gdb_tdesc.py --openocd "$(OPENOCD)" --config $(OCD_CFG) --gdb "$(GDB)" --output $(TDESC)

timing:
	@grep -E 'Max frequency for clock' $(BUILD)/nextpnr.log | tail -n 1 || echo "run 'make' first"
	@grep -E 'Total LUT4s:|Total DFFs:|DP16KD:|MULT18X18D:' $(BUILD)/nextpnr.log | head -n 4 | sed 's/^Info: *//' || true

clean:
	rm -rf $(BUILD)

help:
	@sed -n '1,/^$$/p' Makefile
