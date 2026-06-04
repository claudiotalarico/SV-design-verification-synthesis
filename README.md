## RTL Design (SystemVerilog) | Verification (Questa & cocotb) | Synthesis (Quartus Lite)

### Modulo-10 Up-Counter with validated Load and async active low reset
```
mkdir -p /fpga-designs/01_counter
mkdir -p /fpga-design/01_counter/RTL
mkdir -p /fpga-designs01_counter/SYN
```

### Design and Testbench wrapper to create a visible virtual clock
The design follows a two-block coding style: an `always_comb` block for the combinational logic and an `always_ff` block for the sequential logic.

- [cnt.sv](./RTL/cnt.sv)
- [tb_top.sv](./RTL/tb_top.sv)


