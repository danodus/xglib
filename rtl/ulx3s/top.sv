// top.sv
// Copyright (c) 2022 Daniel Cliche
// SPDX-License-Identifier: MIT

module top(
    input  wire logic       clk_25mhz,

    output      logic [3:0] gpdi_dp,
    output      logic [3:0] gpdi_dn,

    input  wire logic [6:0] btn,
    output      logic [7:0] led,

    input  wire logic       ftdi_txd,
    output      logic       ftdi_rxd,

    // SDRAM
    output      logic        sdram_clk,
    output      logic        sdram_cke,
    output      logic        sdram_csn,
    output      logic        sdram_wen,
    output      logic        sdram_rasn,
    output      logic        sdram_casn,
    output      logic [12:0] sdram_a,
    output      logic [1:0]  sdram_ba,
    output      logic [1:0]  sdram_dqm,
    inout       logic [15:0] sdram_d
);

    localparam FB_WIDTH = 640;
    localparam FB_HEIGHT = 480;

    logic clk_pix, clk_pix_x5, clk_sdram;
    logic clk_locked;

    // reset
    logic auto_reset;
    logic [5:0] auto_reset_counter = 0;
    logic reset;

    // reset
    assign auto_reset = auto_reset_counter < 5'b11111;
    assign reset = auto_reset || !btn[0];


	always @(posedge clk_pix) begin
        if (clk_locked)
		    auto_reset_counter <= auto_reset_counter + auto_reset;
	end

    pll pll (
        .clkin(clk_25mhz),
        .locked(clk_locked),
        .clkout0(clk_pix_x5),
        .clkout2(clk_pix),
        .clkout3(clk_sdram)
    );

    // display timings
    localparam CORDW = 16;
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync, de, frame, line;
    
    display_timings_480p #(.CORDW(CORDW)) display_timings_480p(
        .clk_pix(clk_pix),
        .rst(reset),
        .sx(sx),
        .sy(sy),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .frame(frame),
        .line(line)
    );

    logic [3:0] vga_r;                      // vga red (4-bit)
    logic [3:0] vga_g;                      // vga green (4-bits)
    logic [3:0] vga_b;                      // vga blue (4-bits)
    logic       vga_hsync;                  // vga hsync
    logic       vga_vsync;                  // vga vsync
    logic       vga_de;                     // vga data enable


    hdmi_encoder hdmi(
        .pixel_clk(clk_pix),
        .pixel_clk_x5(clk_pix_x5),

        .red({2{vga_r}}),
        .green({2{vga_g}}),
        .blue({2{vga_b}}),

        .vde(vga_de),
        .hsync(vga_hsync),
        .vsync(vga_vsync),

        .gpdi_dp(gpdi_dp),
        .gpdi_dn(gpdi_dn)
    );

    logic [15:0] vram_data, stream_data;
    logic stream_preloading;
    logic stream_err_underflow;

    assign led[7:4] = 3'd0;

    framebuffer #(
        .SDRAM_CLK_FREQ_MHZ(78),
        .FB_WIDTH(FB_WIDTH),
        .FB_HEIGHT(FB_HEIGHT)
    ) framebuffer(
        .clk_pix(clk_pix),
        .reset_i(reset),

        // SDRAM interface
        .sdram_rst(reset),
        .sdram_clk(clk_sdram),
        .sdram_ba_o(sdram_ba),
        .sdram_a_o(sdram_a),
        .sdram_cs_n_o(sdram_csn),
        .sdram_ras_n_o(sdram_rasn),
        .sdram_cas_n_o(sdram_casn),
        .sdram_we_n_o(sdram_wen),
        .sdram_dq_io(sdram_d),
        .sdram_dqm_o(sdram_dqm),
        .sdram_cke_o(sdram_cke),

        // Framebuffer access
        .ack_o(vram_ack),
        .sel_i(vram_sel),
        .wr_i(vram_wr),
        .mask_i(vram_mask),
        .address_i(vram_address[23:0]),
        .data_in_i(vram_data_out),
        .data_out_o(vram_data),

        // Framebuffer output data stream
        .stream_start_frame_i(frame),
        .stream_base_address_i(24'h0),
        .stream_ena_i(de && inside_fb),
        .stream_data_o(stream_data),
        .stream_preloading_o(stream_preloading),
        .stream_err_underflow_o(stream_err_underflow),
        .dbg_state_o(led[3:0])
    );

    assign sdram_clk = clk_sdram;
    
    // VGA output
    
    logic [11:0] line_counter, col_counter;

    logic inside_fb;
    assign inside_fb = col_counter < 12'(FB_WIDTH) && line_counter <= 12'(FB_HEIGHT);

    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_de    <= de;

        if (frame) begin
            col_counter <= 12'd0;
            line_counter <= 12'd0;
        end else begin
            if (line) begin
                col_counter  <= 12'd0;
                line_counter <= line_counter + 1;
            end
        end

        if (de) begin
            col_counter <= col_counter + 1;
            if (inside_fb) begin
                if (stream_err_underflow) begin
                    vga_r <= 4'hF;
                    vga_g <= 4'h0;
                    vga_b <= 4'h0;
                end else begin
                    vga_r <= stream_data[11:8];
                    vga_g <= stream_data[7:4];
                    vga_b <= stream_data[3:0];
                end
            end else begin
                vga_r <= 4'h2;
                vga_g <= 4'h2;
                vga_b <= 4'h2;
            end
        end else begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end

        if (reset) begin
            line_counter  <= 12'd0;
            col_counter   <= 12'd0;
        end
    end

    logic        vram_ack;
    logic        vram_sel;
    logic        vram_wr;
    logic [3:0]  vram_mask;
    logic [31:0] vram_address;
    logic [15:0] vram_data_out;

    //
    // test pattern
    //

    test_pattern #(
        .FB_WIDTH(FB_WIDTH),
        .FB_HEIGHT(FB_HEIGHT)
    ) test_pattern (
        .clk(clk_pix),
        .reset_i(reset),

        .vram_ack_i(vram_ack),
        .vram_sel_o(vram_sel),
        .vram_wr_o(vram_wr),
        .vram_mask_o(vram_mask),
        .vram_addr_o(vram_address),
        .vram_data_out_o(vram_data_out),

        .fill_i(btn[1]),
        .fill_square_i(btn[2])
    );

endmodule