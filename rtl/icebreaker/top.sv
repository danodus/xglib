module top(
    input logic CLK,
    input logic BTN_N,
    output logic P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
    );

    logic reset;
    assign reset = !BTN_N;

    logic [7:0] display;

    always_comb begin
        {P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10} = display;
    end

    processor processor(
        .clk(CLK),
        .reset_i(reset),
        .display_o(display)
    );

endmodule