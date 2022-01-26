module decoder(
    input  wire logic [31:0] instr_i,
    input  wire logic [31:0] reg_out1_i,
    input  wire logic [31:0] reg_out2_i,
    output      logic [1:0]  next_pc_sel_o,
    output      logic        reg_in_source_o,   // 0: ALU out, 1: memory data out
    output      logic [4:0]  reg_in_sel_o,
    output      logic        reg_in_en_o,
    output      logic [4:0]  reg_out1_sel_o,
    output      logic [4:0]  reg_out2_sel_o,
    output      logic [2:0]  alu_op_o,
    output      logic        alu_op_qual_o,
    output      logic        d_we_o,
    output      logic        d_addr_sel_o,
    output      logic [31:0] addr_o,
    output      logic [31:0] imm_o,
    output      logic        alu_in2_sel_o    // 0: RF out2, 1: immediate
    );

    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;

    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    //logic [31:0] j_imm = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

    logic [2:0] branch_predicate;
    logic is_branch_taken;
    
    always_comb begin
        rd   = instr_i[11:7];
        rs1 = instr_i[19:15];
        rs2 = instr_i[24:20];

        i_imm = {{21{instr_i[31]}}, instr_i[30:20]};
        s_imm = {{21{instr_i[31]}}, instr_i[30:25], instr_i[11:7]};
        b_imm = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
        u_imm = {instr_i[31:12], {12{1'b0}}};
    end

    always_comb begin
        next_pc_sel_o   = 2'b00;
        
        reg_in_source_o = 1'b0;
        reg_in_en_o     = 1'b0;

        alu_op_o        = 3'b000;
        alu_op_qual_o   = 1'b0;

        d_addr_sel_o    = 1'b0;
        d_we_o          = 1'b0;

        addr_o          = 32'd0;

        imm_o           = 32'd0;
        alu_in2_sel_o   = 1'b0;

        is_branch_taken = 1'b0;

        reg_in_sel_o    = 5'b00000;
        reg_out1_sel_o  = 5'b00000;
        reg_out2_sel_o  = 5'b00000;

        // decode the instruction and assert the relevent control signals
        case (instr_i[6:0])

            // LUI
            7'b0110111: begin
                reg_in_sel_o    = rd;
                reg_out1_sel_o  = 5'b00000; // zero in ALU in1
                imm_o           = u_imm;
                alu_in2_sel_o   = 1'b1;     // immediate value in ALU in2
                alu_op_o        = 3'b000;   // ALU add operation
                reg_in_source_o = 1'b0;     // write ALU result to RF
                reg_in_en_o     = 1'b1;     // enable write to RF
            end

            // AUIPC
            7'b0010111: begin
                // TODO
            end

            // JAL
            7'b1101111: begin
                // TODO
            end

            // JALR
            7'b1100111: begin
                // TODO
            end

            // BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                reg_out1_sel_o = rs1;
                reg_out2_sel_o = rs2;

                addr_o = $signed(b_imm) >>> 2;
                case (instr_i[14:12])
                    // BEQ
                    3'b000:
                        if (reg_out1_i == reg_out2_i)
                            is_branch_taken = 1'b1;
                            
                    // BNE
                    3'b001:
                        if (reg_out1_i != reg_out2_i)
                            is_branch_taken = 1'b1;
                    
                    // BLT
                    3'b100:
                        if ($signed(reg_out1_i) < $signed(reg_out2_i))
                            is_branch_taken = 1'b1;

                    // BGE
                    3'b101:
                        if ($signed(reg_out1_i) >= $signed(reg_out2_i))
                            is_branch_taken = 1'b1;

                    // BLTU
                    3'b110:
                        if (reg_out1_i < reg_out2_i)
                            is_branch_taken = 1'b1;
                    
                    // BGEU
                    3'b111:
                        if (reg_out1_i >= reg_out2_i)
                            is_branch_taken = 1'b1;
                endcase

                if (is_branch_taken)
                    next_pc_sel_o = 2'b01; // add the addr field to PC
            end

            // LB, LH, LW, LBU, LHU
            7'b0000011: begin
                reg_in_sel_o = rd;                
                reg_out1_sel_o = rs1;

                addr_o = ($signed(reg_out1_i) + $signed(i_imm)) >>> 2;
                case (instr_i[14:12])
                    // LB
                    3'b000: begin
                        // TODO
                    end

                    // LH
                    3'b001: begin
                        // TODO
                    end

                    // LW
                    3'b010: begin
                        d_addr_sel_o    = 1'b0; // use addr as d_addr
                        d_we_o          = 1'b0; // do not write to memory
                        reg_in_source_o = 1'b1; // write memory data to RF
                        reg_in_en_o     = 1'b1; // enable RF write
                    end

                    // LBU
                    3'b100: begin
                        // TODO
                    end

                    // LHU
                    3'b101: begin
                        // TODO
                    end
                endcase                
            end

            // SB, SH, SW
            7'b0100011: begin
                reg_out1_sel_o = rs1;
                reg_out2_sel_o = rs2;
                addr_o = ($signed(reg_out1_i) + $signed(s_imm)) >>> 2;
                case (instr_i[14:12])
                    // SB
                    3'b000: begin
                        // TODO
                    end

                    // SH
                    3'b001: begin
                        // TODO
                    end

                    // SW
                    3'b010: begin
                        d_addr_sel_o    = 1'b0; // use addr as d_addr
                        d_we_o          = 1'b1; // write to memory
                    end
                endcase
            end

            // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            7'b0010011: begin
                reg_in_sel_o    = rd;
                reg_out1_sel_o  = rs1;
                alu_op_o        = instr_i[14:12];
                reg_in_source_o = 1'b0; // write ALU result to RF
                reg_in_en_o     = 1'b1; // write to RF
                imm_o           = i_imm;
                alu_in2_sel_o   = 1'b1; // immediate value in ALU in2
                // Set opcode qualifier for SRLI and SRAI only
                if (instr_i[14:12] == 3'b101) begin
                    alu_op_qual_o   = instr_i[30];
                end
            end

            // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            7'b0110011: begin
                reg_in_sel_o    = rd;
                reg_out1_sel_o  = rs1;
                reg_out2_sel_o  = rs2;
                alu_op_o        = instr_i[14:12];
                alu_op_qual_o   = instr_i[30];
                reg_in_source_o = 1'b0; // write ALU result to RF
                reg_in_en_o     = 1'b1; // write to RF
                alu_in2_sel_o   = 1'b0; // register out2 in ALU in2
            end

            // FENCE
            7'b0001111: begin
                // TODO
            end

            // ECALL, EBREAK
            7'b1110011: begin
                // TODO
            end
            
        endcase
    end

endmodule