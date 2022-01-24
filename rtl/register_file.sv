module register_file(
    input  wire logic        clk,
    input  wire logic        reset_i,
    input  wire logic [15:0] in_i,       // data for write back register
    input  wire logic [1:0]  in_sel_i,   // register number to write back to
    input  wire logic        in_en_i,    // don't actually write back unless asserted
    input  wire logic [1:0]  out1_sel_i, // register number for out1
    input  wire logic [1:0]  out2_sel_i, // register number for out2
    output      logic [15:0] out1_o,
    output      logic [15:0] out2_o,

    // debug
    output      logic [15:0] dbg_x0,
    output      logic [15:0] dbg_x1,
    output      logic [15:0] dbg_x2,
    output      logic [15:0] dbg_x3
    );

    logic [15:0] regs[3:0];

    always_comb begin
        dbg_x0 = regs[0];
        dbg_x1 = regs[1];
        dbg_x2 = regs[2];
        dbg_x3 = regs[3];
    end

    // actual register file storage
    always_ff @(posedge clk) begin
        if (reset_i) begin
            regs[3] <= 16'd0;
            regs[2] <= 16'd0;
            regs[1] <= 16'd0;
            regs[0] <= 16'd0;
        end
        else begin
            if (in_en_i) begin
                regs[in_sel_i] <= in_i;
            end
        end
    end

    // output registers
    always_comb begin
        out1_o = regs[out1_sel_i];
        out2_o = regs[out2_sel_i];
    end
endmodule