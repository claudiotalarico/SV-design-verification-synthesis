## RTL Design (SystemVerilog) | Verification (Questa & cocotb) | Synthesis (Quartus Lite)

### CAD tools eco-system

**1.** Set up `qtqs_tools` (see the following [link](https://github.com/claudiotalarico/qtqs_tools) for detailed instructions) <br>
**2.** `qtqs_tools` is a docker container that allows you to run Quartus Lite (version 25.1) and Quartus FSE.


### Modulo-10 Up-Counter with validated Load and async active low reset
```
mkdir -p /fpga-designs/01_counter
mkdir -p /fpga-designs/01_counter/RTL
mkdir -p /fpga-designs/01_counter/TB
cd /fpga-designs/01_counter
```

### SystemVerilog RTL Design
The design follows a two-block coding style: an `always_comb` block for the combinational logic and an `always_ff` block for the sequential logic.

- [`cnt.sv`](./01_counter/RTL/cnt.sv)

### Verification Using a Traditional SystemVerilog (SV) Testbench Approach

The input patterns in `cnt_tb.sv` are driven on the rising of a virtual clock `tb_clk` running at period `T`.<br>
The physical `clk` is phase‑shifted by `TB_SKEW` w.r.t. the virtual clock.<br>
The testbench is self-checking. Outputs are sampled `TSKEW` ns before the end of the clock cycle.

- [`cnt_tb.sv`](./01_counter/TB/cnt_tb.sv)
- [`config.txt`](./01_counter/config.txt)

The SV testbench parses an external configuration file (`config.txt`), allowing you to enable/disable specific regression tests and change key simulation parameters without modifying or recompiling the SV source.

To compile the design and the testbench run:
```
bash Comp.scr
```

To run the simulation and generate waveforms in both VCD and WLF formats use:
```
bash Sim.scr
```
Depending on which `vsim` line you leave uncommented, the simulation runs in one of four modes:
- **Interactive GUI** <br>
  The Questa GUI opens with the simulation paused at time 0.
    - Open the Wave window and drag the signals you want to monitor from the Objects pane.
    - Run the simulation from the console with `run -all` or use the toolbar.
- **Automatic with `waves.do`**<br>
  The GUI opens with predefined signals loaded and then closes automatically
    - VCD generation is handled inside the testbench.
- **Automatic with `waves_vcd.do`**<br>
   The GUI opens with predefined signals loaded and then closes automatically
    - VCD generation is driven explicitly by `waves_vcd.do` rather than the testbench
- **Batch (headless) with `waves_batch.do`**
    - no GUI is opened; the simulation runs to completion non-interactively.
    - VCD generation is handled inside the testbench.
      
Compilation and simulation can also be combined into a single script (`CompAndSim.scr`).

The scripts and the Questa `.do` files are:
- [`Comp.scr`](./01_counter/Comp.scr)
- [`Sim.scr`](./01_counter/Sim.scr)
- [`CompAndSim.scr`](./01_counter/CompAndSim.scr)
- [`waves.do`](./01_counter/waves.do)
- [`waves_vcd.do`](./01_counter/waves_vcd.do)
- [`waves_batch.do`](./01_counter/waves_batch.do)

## Analyzing the simulation waveforms

To analyze the simulation waveforms, open your generated waveform trace file (`.vcd` or `.fst` format) in GTKWave using the following command:
```
gtkwave waveforms.vcd
```

<p align="center">
       <img src="./01_counter/IMG/waveforms-vcd.png" width="1000" />
</p>

By default, launching GTKWave with only a `.vcd` file opens an empty workspace, requiring you to manually navigate the Signal Search Tree (SST) to locate and add your desired signals.

To preserve your current waveform layout, including selected signals, zoom levels, and color configurations, you can save a GTKWave configuration file (`.gtkw`). To do this, execute the following sequence in the main menu:

<pre>File > Write Save File As > waveforms.gtkw </pre>

The next time you launch GTKWave, provide the configuration file `.gtkw` alongside the `.vcd` file to instantly restore your exact layout and avoid having to add the signals again:
  
```
gtkwave waveforms.vcd waveforms.gtkw
```

An alternative to GTKWave is to use Questa with its default generated Wave Log Format (`.wlf`) trace file:
```
vsim -gui vsim.wlf -do signals.do
```

The [`signals.do`](./01_counter/signals.do) file is a macro script used to automatically load, format, and arrange your desired signals in the waveform window.

<p align="center">
       <img src="./01_counter/IMG/waveforms-wlf.png" width="1000" />
</p>

### Verification using cocotb
The input patterns (in `test_cnt.py`) are driven on the rising of a virtual clock `v_clk` running at `period_ns`. <br>
The virtual clock starts in the low state.<br>
The physical `clk` is phase‑shifted by `phase_ns` w.r.t. the virtual clock.<br>
To create a visible virtual clock we need to add a SV Testbench wrapper (`tb_top.sv`)


The verification environment incorporates an external configuration file (`config.yaml`), that allows to enable/disable specific regression tests and to change key simulation parameters without modifying the Python source code.
<!--
The cocoTB required files are:
- [`tb_top.sv`](./01_counter/RTL/tb_top.sv)
- [`test_cnt.py`](./01_counter/test_cnt.py)
- [`config.yaml`](./01_counter/config.yaml)
- [`Makefile`](./01_counter/Makefile)

To generate the test run the commands:
```
cd /fpga-designs/01_counter	
make
```
-->
