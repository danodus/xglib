module soc(
    input  wire logic       clk,
    input  wire logic       reset_i,
    output      logic [7:0] display_o,
    input  wire logic       rx_i,
    output      logic       tx_o
    );

    // bus
    logic [31:0] addr;
    logic        mem_we, cpu_we;
    logic [31:0] mem_data_in, cpu_data_in;
    logic [31:0] mem_data_out, cpu_data_out;

    // display
    logic [7:0] display;
    logic display_we;

    // UART
    logic [7:0] uart_tx_data;
    logic [7:0] uart_rx_data;
    logic [7:0] uart_ctrl_rd;
    logic [7:0] uart_ctrl_wr;

    memory memory(
        .clk(clk),
        .addr_i(addr),
        .we_i(mem_we),
        .data_in_i(mem_data_in), 
        .data_out_o(mem_data_out)
    );

    processor processor(
        .clk(clk),
        .reset_i(reset_i),
        .addr_o(addr),
        .we_o(cpu_we),
        .data_in_i(cpu_data_in),
        .data_out_o(cpu_data_out)
    );

    uart uart(
        .clk(clk),
        .reset_i(reset_i),
        .tx_o(tx_o),
        .rx_i(rx_i),
        .wr_i(uart_ctrl_wr[0]),
        .rd_i(uart_ctrl_wr[1]),
        .tx_data_i(uart_tx_data),
        .rx_data_o(uart_rx_data),
        .busy_o(uart_ctrl_rd[0]),
        .valid_o(uart_ctrl_rd[1])
    );

    // address decoding
    always_comb begin
        mem_we = 1'b0;
        display_we = 1'b0;
        mem_data_in = cpu_data_out;
        display = 8'd0;
        cpu_data_in = mem_data_out;
        if (cpu_we) begin
            if (addr[10]) begin
                display = cpu_data_out[7:0];
                display_we = 1'b1;
            end else begin
                mem_we = 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (display_we)
            display_o <= display; 
    end

endmodule