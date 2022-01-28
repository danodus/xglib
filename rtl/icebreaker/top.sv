module top(
    input logic CLK,
    input logic BTN_N,
    output logic P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10
    );

    // reset
    logic auto_reset;
    logic [5:0] auto_reset_counter = 0;
    logic reset;

    assign auto_reset = auto_reset_counter < 5'b11111;
    assign reset = auto_reset || !BTN_N;

	always @(posedge CLK) begin
		auto_reset_counter <= auto_reset_counter + auto_reset;
	end

    // display
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