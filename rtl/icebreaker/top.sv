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

    // memory
    logic [31:0] addr;
    logic        we;
    logic [31:0] data_in;
    logic [31:0] data_out;

    // display
    logic [7:0] display;

    always_comb begin
        {P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10} = display;
    end

    memory memory(
        .clk(CLK),
        .addr_i(addr),
        .we_i(we),
        .data_in_i(data_out), 
        .data_out_o(data_in),
        .display_o(display)
    );

    processor processor(
        .clk(CLK),
        .reset_i(reset),
        .addr_o(addr),
        .we_o(we),
        .data_in_i(data_in),
        .data_out_o(data_out)
    );

endmodule