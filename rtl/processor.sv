module processor(
    input wire logic clk,
    input wire logic reset_i
    );

    logic [15:0] d_addr;
    logic [15:0] d_data_out;
    logic        d_we;
    logic        d_addr_sel;

    logic [15:0] addr;

    logic [15:0] reg_in;
    logic [1:0]  reg_in_sel;
    logic        reg_in_en;
    logic        reg_in_source;
    logic [1:0]  reg_out1_sel;
    logic [1:0]  reg_out2_sel;
    logic [15:0] reg_out1;
    logic [15:0] reg_out2;

    logic        alu_op;
    logic        z_flag;
    logic [15:0] alu_out;

    logic [1:0]  next_pc_sel;
    logic [15:0] pc;
    logic [15:0] next_pc;

    logic [15:0] instruction;

    memory memory(
        .clk(clk),
        .i_addr_i(pc),
        .i_data_out_o(instruction),
        .d_addr_i(d_addr),
        .d_we_i(d_we),
        .d_data_in_i(reg_out2), // in all instructions, only source register 2 is ever written to memory
        .d_data_out_o(d_data_out)
    );

    register_file register_file(
        .clk(clk),
        .reset_i(reset_i),
        .in_i(reg_in),
        .in_sel_i(reg_in_sel),
        .in_en_i(reg_in_en),
        .out1_sel_i(reg_out1_sel),
        .out2_sel_i(reg_out2_sel),
        .out1_o(reg_out1),
        .out2_o(reg_out2)
    );

    alu alu(
        .clk(clk),
        .reset_i(reset_i),
        .in1_i(reg_out1),
        .in2_i(reg_out2),
        .op_i(alu_op),
        .out_o(alu_out),
        .z_flag_o(z_flag)
    );

    decoder decoder(
        .instruction_i(instruction),
        .z_flag_i(z_flag),
        .next_pc_sel_o(next_pc_sel),
        .reg_in_source_o(reg_in_source),
        .reg_in_sel_o(reg_in_sel),
        .reg_in_en_o(reg_in_en),
        .reg_out1_sel_o(reg_out1_sel),
        .reg_out2_sel_o(reg_out2_sel),
        .alu_op_o(alu_op),
        .d_we_o(d_we),
        .d_addr_sel_o(d_addr_sel),
        .addr_o(addr)
    );

    // PC logic
    always_comb begin
        next_pc = 16'd0;

        case (next_pc_sel)
            // from register file
            2'b1x: begin
                next_pc = reg_out1;
            end

            // from instruction relative
            2'b01: begin
                next_pc = pc + addr;
            end

            // regular operation, increment
            default: begin
                next_pc = pc + 16'd1;
            end
        endcase
    end

    // PC register
    always_ff @(posedge clk) begin
        if (reset_i) begin
            pc <= 16'd0;
        end else begin
            pc <= next_pc;
        end
    end

    // extra logic

    always_comb begin
        reg_in = reg_in_source ? d_data_out : alu_out;
        d_addr = d_addr_sel ? reg_out1 : addr;
    end

endmodule