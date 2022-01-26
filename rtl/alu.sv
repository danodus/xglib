module alu(
    input  wire logic        clk,
    input  wire logic [31:0] in1_i,
    input  wire logic [31:0] in2_i,
    input  wire logic [2:0]  op_i,
    input                    op_qual_i, // operation qualification (+/-,logical/arithmetic)
    output      logic [31:0] out_o
    );

    // ALU logic
    always_comb begin
        case (op_i)
            3'b000: out_o = op_qual_i ? in1_i - in2_i : in1_i + in2_i;                        // ADD/SUB
            3'b010: out_o = ($signed(in1_i) < $signed(in2_i)) ? 32'b1 : 32'b0;                // SLT
            3'b011: out_o = (in1_i < in2_i) ? 32'b1 : 32'b0;                                  // SLTU
            3'b100: out_o = in1_i ^ in2_i;                                                    // XOR
            3'b110: out_o = in1_i | in2_i;                                                    // OR
            3'b111: out_o = in1_i & in2_i;                                                    // AND
            3'b001: out_o = in1_i << in2_i[4:0];                                              // SLL
            3'b101: out_o = $signed({op_qual_i ? in1_i[31] : 1'b0, in1_i}) >>> in2_i[4:0];    // SRL/SRA
        endcase
    end

endmodule
