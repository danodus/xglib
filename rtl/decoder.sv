module decoder(
    input  wire logic [15:0] instruction_i,
    input  wire logic        z_flag_i,
    output      logic [1:0]  next_pc_sel_o,
    output      logic        reg_in_source_o,
    output      logic [1:0]  reg_in_sel_o,
    output      logic        reg_in_en_o,
    output      logic [1:0]  reg_out1_sel_o,
    output      logic [1:0]  reg_out2_sel_o,
    output      logic        alu_op_o,
    output      logic        d_we_o,
    output      logic        d_addr_sel_o,
    output      logic [15:0] addr_o
    );

    always_comb begin
        reg_in_sel_o   = instruction_i[13:12];
        reg_out1_sel_o = instruction_i[11:10];
        reg_out2_sel_o = instruction_i[9:8];
    end

    always_comb begin
        next_pc_sel_o   = 2'b0;
        
        reg_in_source_o = 1'b0;
        reg_in_en_o     = 1'b0;

        alu_op_o        = 1'b0;

        d_addr_sel_o    = 1'b0;
        d_we_o          = 1'b0;

        addr_o          = 16'd0;

        // decode the instruction and assert the relevent control signals
        case (instruction_i[15:14])
            // ADD
            2'b00: begin
                alu_op_o        = 1'b1;
                reg_in_source_o = 1'b0; // source the write back register data to the ALU
                reg_in_en_o     = 1'b1; // assert write back enabled
            end

            // LD
            2'b01: begin
                // 2 versions: register addressing and absolute addressing
                case (instruction_i[0])
                    // absolute
                    1'b0: begin
                        d_addr_sel_o    = 1'b0; // use addr as d_addr
                        d_we_o          = 1'b0; // read from memory
                        reg_in_source_o = 1'b1; // source the write back register from memory
                        reg_in_en_o     = 1'b1; // assert write back enabled
                        addr_o          = {6'b0, instruction_i[11:1]};
                    end

                    // register
                    1'b1: begin
                        d_addr_sel_o    = 1'b1; // use value from register file as d_addr
                        d_we_o          = 1'b0; // read from memory
                        reg_in_source_o = 1'b1; // source the write back register from memory
                        reg_in_en_o     = 1'b1; // assert write back enabled
                    end
                endcase
            end

            // ST
            2'b10: begin
                // 2 versions: register addressing and absolute addressing
                case (instruction_i[0])
                    // absolute
                    1'b0: begin
                        d_addr_sel_o    = 1'b0; // use addr as d_addr
                        d_we_o          = 1'b1; // write to memory
                        addr_o          = {6'b0, instruction_i[13:10], instruction_i[7:1]};
                    end

                    // register
                    1'b1: begin
                        d_addr_sel_o = 1'b1; // use value from register file as d_addr
                        d_we_o       = 1'b1; // write to memory
                    end
                endcase
            end

            // BRZ
            2'b11: begin
                // instruction does nothing if z flag is not set
                if (z_flag_i) begin
                    // 2 versions: register addressing and relative addressing
                    case (instruction_i[0])
                        // relative
                        1'b0: begin
                            next_pc_sel_o = 2'b01; // add the addr field to PC
                            addr_o        = {{6{instruction_i[11]}}, instruction_i[11:1]}; // sign extend
                        end

                        // register
                        1'b1: begin
                            next_pc_sel_o = 2'b1x; // use register value
                        end
                    endcase
                end
            end
        endcase
    end

endmodule