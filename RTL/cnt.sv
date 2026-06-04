// author:  C. Talarico
// file:    cnt.sv
// module:  cnt
// comment: Module-10 up counter with validated load and async active low reset 
//

module cnt #(
    parameter WIDTH = 4
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              load,    
    input  logic [WIDTH-1:0]  data_in, 
    output logic [WIDTH-1:0]  count
);

    logic [WIDTH-1:0] next_count;

    // 1. Combinational Logic: Priority Load with Validation
    always_comb begin
        if (load) begin
            // Check if load data is within valid BCD range (0-9)
            if (data_in > 9)
                next_count = '0;     // Load 0 if data_in is out of bounds
            else
                next_count = data_in;
        end else begin
            // Increment logic
            if (count >= 9)
                next_count = '0;
            else
                next_count = count + 1;
        end
    end

    // 2. Sequential Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= '0;
        else
            count <= next_count;
    end

endmodule
