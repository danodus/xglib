// scan_doubler.sv
// Copyright (c) 2022 Daniel Cliche
// SPDX-License-Identifier: MIT

module scan_doubler #(
    parameter VGA_WIDTH = 640
) (
    input wire logic        clk,
    input wire logic        reset_i,

    input wire logic        vga_vsync_i,
    input wire logic        vga_de_i,

    input wire logic [15:0] fb_stream_data_i,
    output     logic        fb_stream_ena_o,

    output     logic [15:0] stream_data_o
);

    logic [15:0] line_buffer[VGA_WIDTH / 2];
    logic [11:0] col_counter;
    logic        line_dup;

    always_ff @(posedge clk) begin
        if (reset_i) begin
            col_counter <= 12'd0;
            line_dup <= 1'b0;
            fb_stream_ena_o <= 1'b0;
        end else begin
            if (!vga_vsync_i)
                line_dup <= 1'b0;
            if (vga_de_i) begin
                col_counter <= col_counter + 12'd1;

                if (col_counter == VGA_WIDTH - 1) begin
                    col_counter <= 12'd0;
                    line_dup <= !line_dup;
                end

                if (line_dup) begin
                    stream_data_o <= line_buffer[col_counter >> 1];
                    fb_stream_ena_o <= 1'b0;
                end else begin
                    stream_data_o <= fb_stream_data_i;
                    if (!col_counter[0])
                        line_buffer[col_counter >> 1] <= fb_stream_data_i;
                    fb_stream_ena_o <= !col_counter[0];
                end
            end else begin
                col_counter <= 12'd0;
                fb_stream_ena_o <= 1'b0;
            end
        end
    end

endmodule
