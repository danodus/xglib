`timescale 1ns/1ps

module processor_tb;
    logic clk = 0;
    logic reset;

    processor UUT(
        .clk(clk),
        .reset_i(reset)
    );

    initial begin
        $dumpfile("processor_tb.vcd");
        $dumpvars(0, UUT);
        $dumpvars(0, UUT.memory.mem_array[256]);
        reset = 1'b1;
        #20
        reset = 1'b0;
        #2000
        $finish;
    end

    always #5 clk = !clk;

endmodule