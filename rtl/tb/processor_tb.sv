`timescale 1ns/1ps

module processor_tb;
    logic clk = 0;
    logic reset;
    logic [7:0] display;

    logic [31:0] addr;
    logic        we;
    logic [31:0] data_in;
    logic [31:0] data_out;

    memory memory(
        .clk(clk),
        .addr_i(addr),
        .we_i(we),
        .data_in_i(data_out), 
        .data_out_o(data_in),
        .display_o(display)
    );

    processor UUT(
        .clk(clk),
        .reset_i(reset),
        .addr_o(addr),
        .we_o(we),
        .data_in_i(data_in),
        .data_out_o(data_out)
    );

    initial begin
        $dumpfile("processor_tb.vcd");
        $dumpvars(0, UUT);
        $dumpvars(0, memory);
        reset = 1'b1;
        #20
        reset = 1'b0;
        #2000
        $finish;
    end

    always #5 clk = !clk;

endmodule