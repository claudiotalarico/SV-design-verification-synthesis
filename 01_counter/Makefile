# ============================================================
#  Simulator Selection
#  Usage:
#    make              → defaults to icarus
#    make SIM=icarus   → explicit icarus
#    make SIM=questa   → questa (uses questa-compat flow internally)
# ============================================================
SIM ?= icarus

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
    SIM_BUILD  ?= $(PWD)/WAVES
    # vlog compile flags
    COMPILE_ARGS += -sv -O5
    # vsim simulation flags
    SIM_ARGS   += -t 1ns -wlf $(SIM_BUILD)/vsim.wlf
else ifeq ($(SIM),icarus)
    # Icarus defaults
    SIM_BUILD  ?= $(PWD)/WAVES
    COMPILE_ARGS += -g2012
endif

# Custom directory for simulation build files and waveforms
SIM_BUILD ?= $(PWD)/WAVES

# Create the custom directory if it doesn't exist
$(shell mkdir -p $(SIM_BUILD))

# Include cocotb's makefile rules
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean waves signals
waves:
ifeq ($(SIM),questa-compat)
	@echo "Opening Questa waveform..."
	vsim -view $(SIM_BUILD)/vsim.wlf
else
	@echo "Opening GTKWave..."
	gtkwave $(SIM_BUILD)/dump.vcd
endif
 
signals:
ifeq ($(SIM),questa-compat)
	@echo "Opening Questa waveform..."
	vsim -view $(SIM_BUILD)/vsim.wlf -do ./cocotb_signals.do
else
	@echo "Opening GTKWave with signal file..."
	gtkwave $(SIM_BUILD)/dump.vcd ./dump.gtkw
endif


# ============================================================
#  Clean
# ============================================================
clean::
	@echo "Cleaning up..."
	rm -rf WAVES *.vcd *.fst *.xml __pycache__ transcript *.wlf
