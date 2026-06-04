## RTL Design (SystemVerilog) | Verification (Questa & cocotb) | Synthesis (Quartus Lite)

### CAD tools eco-system

**1.** Set up `qtqs_tools` (see the following [link](https://github.com/claudiotalarico/qtqs_tools) for detailed instructions) <br>
**2.** `qtqs_tools` is a docker container that allows you to run Quartus Lite (version 25.1) and Quartus FSE.


### Modulo-10 Up-Counter with validated Load and async active low reset
```
mkdir -p /fpga-designs/01_counter
mkdir -p /fpga-designs/01_counter/RTL
```

### Design and Testbench wrapper to create a visible virtual clock
The design follows a two-block coding style: an `always_comb` block for the combinational logic and an `always_ff` block for the sequential logic.

- [`cnt.sv`](./01_counter/RTL/cnt.sv)
- [`tb_top.sv`](./01_counter/RTL/tb_top.sv)

### Testing using cocotb
The input patterns (in `test_cnt.py`) are driven on the rising of a virtual clock `v_clk` running at `period_ns`. <br>
The virtual clock starts in the low state.<br>
The physical `clk` is phase‑shifted by `phase_ns` w.r.t. the virtual clock.<br>

The verification environment incorporates an external configuration file (`config.yaml`), that allows to enable/disable specific regression tests and to change key simulation parameters without modifying the Python source code.

The cocoTB required files are:
- [`test_cnt.py`](./01_counter/test_cnt.py)
- [`config.yaml`](./01_counter/config.yaml)
- [`Makefile`](./01_counter/Makefile)

To generate the test run the commands:
```
cd /fpga-designs/01_counter	
make
```
