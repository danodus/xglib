`timescale 1ns/1ps

module processor_tb;
    logic clk = 0;
    logic reset;
    logic [7:0] display;

    processor UUT(
        .clk(clk),
        .reset_i(reset),
        .display_o(display)
    );

    initial begin
        $dumpfile("processor_tb.vcd");
        $dumpvars(0, UUT);
        reset = 1'b1;
        #20
        reset = 1'b0;
        #2000
        $finish;
    end

    always #5 clk = !clk;

endmodule