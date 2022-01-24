module alu(
    input  wire logic        clk,
    input  wire logic        reset_i,
    input  wire logic [15:0] in1_i,
    input  wire logic [15:0] in2_i,
    input  wire logic        op_i,
    output      logic [15:0] out_o,
    output      logic        z_flag_o
    );

    logic z_flag_next;

    // Z flag register
    always_ff @(posedge clk) begin
        if (reset_i) begin
            z_flag_o <= 1'b0;
        end else begin
            z_flag_o <= z_flag_next;
        end
    end

    // ALU logic
    always_comb begin
        out_o = 16'd0;
        z_flag_next = z_flag_o;   // z flag only change when ADD is performed

        case (op_i)
            // op_i == 0 is not mapped
            1: begin
                out_o = in1_i + in2_i;
                z_flag_next = (out_o == 16'd0);
            end
        endcase
    end

endmodule
