// tb_top.sv 

// wrapper for creating a virtual clock
module tb_top(
  output logic v_clk // make it a port: 
                     // simplest, most reliable way 
                     // to make sure it's not optimized away
);

    //instantiate DUT
    logic clk, rst_n, load;
    logic [3:0] data_in;
    logic [3:0] count;

    cnt dut(
        .load(load),
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .count(count)
    );

    // Enable waveform dumping 
    initial begin
      v_clk = 0; // don't forget to initialize
      $dumpfile("WAVES/dump.vcd");
      $dumpvars(0, tb_top); 
    end

endmodule
