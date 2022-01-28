module memory(
    input  wire logic        clk,
    input  wire logic [31:0] addr_i,     // data port
    input  wire logic        we_i,
    input  wire logic [31:0] data_in_i,
    output      logic [31:0] data_out_o,
    output      logic [7:0]  display_o
    );

    logic [31:0] mem_array[1023:0];

    initial begin
        $readmemh("program.hex", mem_array);
    end

    always_ff @(posedge clk) begin
        if (we_i) begin
            if (addr_i[10]) begin
                display_o <= data_in_i[7:0];
            end else begin
                mem_array[addr_i[9:0]] <= data_in_i;
            end
        end
        data_out_o = mem_array[addr_i[9:0]];
    end

endmodule