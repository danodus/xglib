module memory(
    input  wire logic        clk,
    input  wire logic [31:0] addr_i,
    input  wire logic        we_i,
    input  wire logic [31:0] data_in_i,
    output      logic [31:0] data_out_o
    );

    logic [31:0] mem_array[1023:0];

    initial begin
        $readmemh("program.hex", mem_array);
    end

    always_ff @(posedge clk) begin
        if (we_i) begin
            mem_array[addr_i[9:0]] <= data_in_i;
        end
        data_out_o = mem_array[addr_i[9:0]];
    end

endmodule