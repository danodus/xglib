/*
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

 // October 2019, Matthias Koch: Renamed wires
 // December 2020, Bruno Levy: parameterization with freq and bauds
 // January 2022, Daniel Cliche: Conversion to SV

module uart #(
  parameter FREQ_HZ = 12 * 1000000,
  parameter BAUDS    = 115200	       
) (
    input  wire logic       clk,
    input  wire logic       reset_i,

    output      logic       tx_o,
    input  wire logic       rx_i,

    input  wire logic       wr_i,
    input  wire logic       rd_i,
    input  wire logic [7:0] tx_data_i,
    output      logic [7:0] rx_data_o,

    output      logic       busy_o,
    output      logic       valid_o
);
    logic rx_rdy, tx_rdy;
    assign busy_o = !tx_rdy;
    assign valid_o = rx_rdy;

    uart_rx #(
        .FREQ_HZ(FREQ_HZ),
        .BAUD_RATE(BAUDS)
    ) uart_rx(
        .clk(clk),
        .rst(!reset_i),
        .RxD(rx_i),
        .fsel(1'b0),
        .done(rd_i),
        .rdy(rx_rdy),
        .data(rx_data_o)
    );

    uart_tx #(
        .FREQ_HZ(FREQ_HZ),
        .BAUD_RATE(BAUDS)
    ) uart_tx(
        .clk(clk),
        .rst(!reset_i),
        .start(wr_i),
        .fsel(1'b0),
        .data(tx_data_i),
        .rdy(tx_rdy),
        .TxD(tx_o)
    );

endmodule

