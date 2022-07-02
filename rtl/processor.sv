// processor.sv
// Copyright (c) 2022 Daniel Cliche
// SPDX-License-Identifier: MIT

module processor(
    input wire logic       clk,
    input wire logic       reset_i,

    // memory
    output      logic        sel_o,
    output      logic [31:0] addr_o,
    output      logic        we_o,
    output      logic [3:0]  wr_mask_o,
    input  wire logic [31:0] data_in_i,
    output      logic [31:0] data_out_o,
    input  wire logic        ack_i
    );

    logic [31:0] d_addr;
    logic [31:0] d_data_out;
    logic        d_we;
    logic        addr_valid;

    logic [31:0] addr;

    logic [31:0] reg_in;
    logic [4:0]  reg_in_sel;
    logic        reg_in_en;
    logic [1:0]  reg_in_source;
    logic [4:0]  reg_out1_sel;
    logic [4:0]  reg_out2_sel;
    logic [31:0] reg_out1;
    logic [31:0] reg_out2;
    logic [31:0] alu_in1;
    logic [31:0] alu_in2;

    logic [2:0]  alu_op;
    logic        alu_op_qual;
    logic [31:0] alu_out;

    logic [31:0] imm;
    logic        alu_in1_sel;
    logic        alu_in2_sel;

    logic [1:0]  next_pc_sel;
    logic [31:0] pc;
    logic [31:0] next_pc;

    logic [31:0] instruction;

    logic [3:0]  mask;
    logic        sext;

    logic [31:0] d_data_out_ext;

    enum {
        FETCH,
        DECODE,
        DECODE2,
        DECODE3,
        WAIT_ACK,
        WRITE,
        WRITE2
    } state;

    register_file register_file(
        .clk(clk),
        .in_i(reg_in),
        .in_sel_i(reg_in_sel),
        .in_en_i(reg_in_en && state == WRITE),
        .out1_sel_i(reg_out1_sel),
        .out2_sel_i(reg_out2_sel),
        .out1_o(reg_out1),
        .out2_o(reg_out2)
    );

    alu alu(
        .clk(clk),
        .in1_i(alu_in1),
        .in2_i(alu_in2),
        .op_i(alu_op),
        .out_o(alu_out),
        .op_qual_i(alu_op_qual)
    );

    decoder decoder(
        .en_i(state == DECODE || state == DECODE2 || state == DECODE3 || state == WAIT_ACK || state == WRITE),
        .instr_i(instruction),
        .reg_out1_i(reg_out1),
        .reg_out2_i(reg_out2),
        .next_pc_sel_o(next_pc_sel),
        .reg_in_source_o(reg_in_source),
        .reg_in_sel_o(reg_in_sel),
        .reg_in_en_o(reg_in_en),
        .reg_out1_sel_o(reg_out1_sel),
        .reg_out2_sel_o(reg_out2_sel),
        .alu_op_o(alu_op),
        .alu_op_qual_o(alu_op_qual),
        .d_we_o(d_we),
        .addr_valid_o(addr_valid),
        .addr_o(addr),
        .imm_o(imm),
        .alu_in1_sel_o(alu_in1_sel),
        .alu_in2_sel_o(alu_in2_sel),
        .mask_o(mask),
        .sext_o(sext)
    );

    // memory
    always_comb begin
        d_data_out = data_in_i;
    end

    // PC logic
    always_comb begin
        next_pc = 32'd0;

        case (next_pc_sel)
            // from register file
            2'b10: begin
                next_pc = reg_out1;
            end

            // from instruction relative
            2'b01: begin
                next_pc = pc + addr;
            end

            // from instruction absolute
            2'b11: begin
                next_pc = addr;
            end

            // regular operation, increment
            default: begin
                next_pc = pc + 32'd4;
            end
        endcase
    end

    // extra logic

    always_comb begin
        d_data_out_ext = d_data_out >> (8 * (d_addr & 2'b11));

        case (mask)
            // LB or LBU
            4'b0001:
                if (sext) begin
                    d_data_out_ext = {{24{d_data_out_ext[7]}}, d_data_out_ext[7:0]};
                end else begin
                    d_data_out_ext = d_data_out_ext & 32'h000000FF;
                end
            // LH or LHU
            4'b0011:
                if (sext) begin
                    d_data_out_ext = {{16{d_data_out_ext[15]}}, d_data_out_ext[15:0]};
                end else begin
                    d_data_out_ext = d_data_out_ext & 32'h0000FFFF;
                end
        endcase
    end

    always_comb begin
        d_addr = (state == DECODE || state == DECODE2 || state == DECODE3 || state == WAIT_ACK || state == WRITE) ? addr : pc;
        reg_in = reg_in_source == 2'b01 ? d_data_out_ext : reg_in_source == 2'b10 ? pc + 4 : alu_out;
        alu_in1 = alu_in1_sel ? pc : reg_out1;
        alu_in2 = alu_in2_sel ? imm : reg_out2;
    end

    always_ff @(posedge clk) begin

        case (state)
            FETCH: begin
                addr_o     <= pc;
                we_o       <= 1'b0;
                sel_o      <= 1'b1;
                if (ack_i) begin
                    sel_o <= 1'b0;
                    instruction <= d_data_out;
                    //$display("PC: %x, Instruction: %x", pc, d_data_out);
                    state <= DECODE;
                end
            end
            DECODE: begin
                state <= DECODE2;
            end
            DECODE2: begin
                addr_o     <= d_addr;
                state <= DECODE3;
            end
            DECODE3: begin
                // in all instructions, only source register 2 is ever written to memory
                data_out_o <= reg_out2 << (8 * (d_addr & 2'b11));
                wr_mask_o  <= mask << (d_addr & 2'b11);
                if (addr_valid) begin
                    we_o       <= d_we;
                    sel_o <= 1'b1;
                    state <= WAIT_ACK;
                end else begin
                    state <= WRITE;
                end
            end
            WAIT_ACK: begin
                if (ack_i) begin
                    //$display("reg_in_source: %d, addr: %h, we: %d, data_in: %x, data_out: %x", reg_in_source, addr_o, we_o, data_in_i, data_out_o);
                    sel_o <= 1'b0;
                    we_o  <= 1'b0;
                    state <= WRITE;
                end
            end
            WRITE: begin
                pc <= next_pc;
                state <= WRITE2;
            end
            WRITE2: begin
                state <= FETCH;
            end
        endcase

        if (reset_i) begin
            addr_o     <= 32'd0;
            we_o       <= 1'b0;
            wr_mask_o  <= 4'b1111;
            data_out_o <= 32'd0;
            sel_o <= 1'b0;
            state <= FETCH;
            pc    <= 32'd0;
        end
    end

endmodule