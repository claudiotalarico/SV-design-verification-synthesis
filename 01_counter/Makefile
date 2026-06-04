# Simulator
SIM := icarus

# HDL Language
TOP_LEVEL_LANG := verilog

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

# Custom directory for simulation build files and waveforms
SIM_BUILD ?= $(PWD)/WAVES

# Create the custom directory if it doesn't exist
$(shell mkdir -p $(SIM_BUILD))

# Include cocotb's makefile rules
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean waves
waves:
	@echo "Opening up gtkwave..."
	gtkwave ./WAVES/dump.fst

clean::
	@echo "Cleaning up..."
	rm -rf WAVES *.vcd *.fst *.xml __pycache__
