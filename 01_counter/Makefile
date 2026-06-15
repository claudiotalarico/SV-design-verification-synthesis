# ============================================================
#  Simulator Selection
#  Usage:
#    make              → defaults to icarus
#    make SIM=icarus   → explicit icarus
#    make SIM=questa   → questa (uses questa-compat flow internally)
# ============================================================
SIM ?= icarus

# Make "make" run the copy target by default
.DEFAULT_GOAL := copy_wlf

# Remap 'questa' to the traditional vlog/vsim flow
ifeq ($(SIM),questa)
    override SIM := questa-compat
endif

# HDL Language
TOPLEVEL_LANG := verilog

# Variable(s)
PWD := $(shell pwd)

# RTL source(s)
VERILOG_SOURCES := $(PWD)/RTL/cnt.sv \
		   $(PWD)/RTL/tb_top.sv

# Name of the top-level Verilog module
COCOTB_TOPLEVEL := tb_top

# Name of the Python test module (without .py)
COCOTB_TEST_MODULES := test_cnt

# Enable waveform generation
WAVES ?= 1


# ============================================================
#  Simulator-specific settings
# ============================================================
ifeq ($(SIM),questa-compat)
    SIM_BUILD  := /tmp/WAVES
    # vlog compile flags
    COMPILE_ARGS += -sv -O5
    # vsim simulation flags
    SIM_ARGS   += -t 1ns -wlf $(SIM_BUILD)/vsim.wlf
else ifeq ($(SIM),icarus)
    # Icarus defaults
    SIM_BUILD  ?= $(PWD)/WAVES
    COMPILE_ARGS += -g2012
endif

# Create directories if needed
$(shell mkdir -p $(SIM_BUILD))
$(shell mkdir -p $(PWD)/WAVES)

# Include cocotb's makefile rules
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean waves signals copy_wlf

# Automatic post-run copy for Questa
copy_wlf: sim
ifeq ($(SIM),questa-compat)
	@mkdir -p $(PWD)/WAVES
	@if [ -f /tmp/WAVES/vsim.wlf ]; then \
		cp -f /tmp/WAVES/vsim.wlf $(PWD)/WAVES/vsim.wlf \
		&& echo "Copied vsim.wlf to WAVES/"; \
	fi
endif

waves:
ifeq ($(SIM),questa-compat)
	@echo "Opening Questa waveform..."
	# vsim -view $(SIM_BUILD)/vsim.wlf 
	vsim -view $(SIM_BUILD)/vsim.wlf -do "add wave /tb_top/*; wave zoomfull;"
	# vsim -view $(SIM_BUILD)/vsim.wlf -do "add wave -r /*; wave zoomfull;"
else
	@echo "Opening GTKWave..."
	gtkwave $(SIM_BUILD)/dump.vcd
endif
 
signals:
ifeq ($(SIM),questa-compat)
	@echo "Opening Questa waveform with signal file..."
	vsim -view $(SIM_BUILD)/vsim.wlf -do ./cocotb_signals.do
else
	@echo "Opening GTKWave with signal file..."
	gtkwave $(SIM_BUILD)/dump.vcd ./dump.gtkw
endif


# ============================================================
#  Clean
# ============================================================
clean::
	@echo "Cleaning up build artifacts..."
	@rm -rf $(PWD)/WAVES /tmp/WAVES
	@rm -f *.vcd *.fst *.xml *.wlf transcript
	@rm -rf __pycache__ 
	@echo "Cleaning Done."
