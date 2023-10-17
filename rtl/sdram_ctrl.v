// ref.: https://gitlab.com/r1809/rvsoc/-/blob/main/src/mem2.v

/*
 * Matching SDRAM controller, do 256 byte bursts
 * Designed to run at ~100 MHz (i.e. will not work @>110Mhz with grade 7 sdram)
 */

module sdram_ctrl (
  input             clk_in,     // controller clock
  
  // interface to the cache
  input      [15:0] din,        // data input from cpu
  output reg [15:0] dout,       // data output to cpu
  input      [23:0] ad,         // 23 bit upper address
  output reg        get,        // load word from SDR on sdr_clk2
  output reg        put,        // send word to SDR on sdr_clk2
  input  wire       rd,         // SDR start read transaction
  input  wire       wr,         // SDR start write transaction
  input  wire       rst,        // cpu reset
  output wire       calib,      // sdram initialising

  // interface to the chip
  inout      [15:0] sd_data,    // 16 bit databus
  output reg [12:0] sd_addr,    // 12 bit multiplexed address bus
  output reg [1:0]  sd_dqm,     // two byte masks
  output reg [1:0]  sd_ba,      // two banks
  output            sd_cs,      // chip select
  output            sd_we,      // write enable
  output            sd_ras,     // row address select
  output            sd_cas,     // column address select
  output            sd_cke,     // clock enable
  output            sd_clk      // chip clock (inverted from input clk)
);

  localparam BURST_LENGTH   = 3'b111; // 000=1, 001=2, 010=4, 011=8, 111=full page
  localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
  localparam CAS_LATENCY    = 3'd3;   // 3 needed @ >100Mhz
  localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
  localparam WRITE_BURST    = 1'b0;   // 0=write burst enabled, 1=only single access write

  localparam MODE = {3'b000, WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};
  
  // Extend the address bus (31 bits, for 16b words)
  wire [30:0] addr;
  assign addr = { ad, 7'h0 };


  // ---------------------------------------------------------------------
  // --------------------------- startup/reset ---------------------------
  // ---------------------------------------------------------------------

  // make sure reset lasts long enough (recommended 100us)
  reg [12:0] reset;
  always @(posedge clk_in) begin
    reset <= (|reset) ? reset - 13'd1 : 0;
    if(rst)	reset <= 13'd100;
  end
  
  assign calib = |reset;

  // ---------------------------------------------------------------------
  // ------------------ generate ram control signals ---------------------
  // ---------------------------------------------------------------------

  // all possible commands
  localparam CMD_INHIBIT         = 4'b1111;
  localparam CMD_NOP             = 4'b0111;
  localparam CMD_ACTIVE          = 4'b0011;
  localparam CMD_READ            = 4'b0101;
  localparam CMD_WRITE           = 4'b0100;
  localparam CMD_BURST_TERMINATE = 4'b0110;
  localparam CMD_PRECHARGE       = 4'b0010;
  localparam CMD_AUTO_REFRESH    = 4'b0001;
  localparam CMD_LOAD_MODE       = 4'b0000;

  assign sd_clk = !clk_in; // chip clock shifted 180 deg.
  assign sd_cke = ~rst;

  // drive control signals according to current command
  reg  [3:0] sd_cmd; 
  assign sd_cs  = sd_cmd[3];
  assign sd_ras = sd_cmd[2];
  assign sd_cas = sd_cmd[1];
  assign sd_we  = sd_cmd[0];

  // sdram tri-state databus interaction
  reg  sd_rden = 0, sd_wren = 0;

`ifndef SYNTHESIS
  reg   [15:0] i;
  assign sd_data  = sd_wren ? i : 16'hzzzz;
  always @(posedge sd_clk) i <= din;
  always @(posedge sd_clk) if(sd_rden) dout <= sd_data;
`else
  wire  [15:0] o;
  reg   [15:0] i;
  BB           bb[15:0] (.T(~sd_wren), .I(i), .O(o), .B(sd_data));
  always @(posedge clk_in) i <= din;
//  OFS1P3BX dbo_FF[15:0] (.SCLK(sd_clk), .SP(1'b1),    .Q(i),  .D(din), .PD(1'b0));
  IFS1P3BX dbi_FF[15:0] (.SCLK(sd_clk), .SP(sd_rden), .Q(dout), .D(o), .PD(1'b0));
`endif
  
  // ---------------------------------------------------------------------
  // ------------------------ cycle state machine ------------------------
  // ---------------------------------------------------------------------
  
  // The state machine runs at 125Mhz, asynchronous to the CPU.
  // It idles doing refreshes and switches to burst reads and writes
  // as requested.
  
  localparam STBY  =   0;   // start state, do refreshes
  localparam RD    =  50;   // start of read sequence
  localparam WR    = 200;   // start of write sequence

  reg [8:0] t = 0;

  wire mreq =  rd | wr;

  always @(posedge clk_in) begin
    sd_cmd <= CMD_NOP;  // default command
    
    // move to next state
    t <= t + 1;

    if(reset != 0) begin // reset operation
      case(reset)
      99: begin sd_ba   <= 2'b00; sd_dqm  <= 2'b00;
                get     <= 1'b0;  put     <= 1'b0;
                sd_rden <= 1'b0;  sd_wren <= 1'b0;
          end
      41: sd_addr[10] <= 1'b1; // PRECHARGE ALL
      40: sd_cmd  <= CMD_PRECHARGE;
      30: sd_cmd  <= CMD_AUTO_REFRESH;
      20: sd_cmd  <= CMD_AUTO_REFRESH;
      11: sd_addr <= MODE;
      10: sd_cmd  <= CMD_LOAD_MODE;
       1: t <= STBY;
      endcase
    end
    
    else begin // normal operation
      case(t)

      // Idle doing refreshes
      //
      STBY:   begin
                sd_addr <= addr[21: 9];
                sd_ba   <= addr[23:22];
                if (mreq) begin
                  sd_cmd <= CMD_ACTIVE;
                  t <= rd ? RD : WR;
                end
              end

      STBY+1:  sd_cmd <= CMD_AUTO_REFRESH;
      STBY+10: t <= STBY;
      
      // Read burst, set-up for tRCD = 2 clocks and CL = 3 clocks. Possibly the burst
      // terminate could come earlier. The 'get' signal accounts for the dbi_FF delay.
      //
      RD+2:   sd_addr <= { 4'b0010, addr[8:0] }; 
      RD+3:   sd_cmd  <= CMD_READ;
      RD+6:   begin sd_rden <= 1'b1; get <= 1'b1; end                   
      // ... 128 read cycles
      RD+134: begin sd_rden <= 1'b0; get <= 1'b0; end                                   
      RD+136: sd_cmd  <= CMD_BURST_TERMINATE;    
      RD+137: sd_cmd  <= CMD_PRECHARGE; /* ALL */
      RD+140: t       <= STBY+1;
      
      // Write burst, set up for tRCD = 2. Burst terminate has to be exact here, and
      // the 'put' signal accounts for a 3 clock pipeline to fetch data.
      //
      WR+2:   put     <= 1'b1;                   
      WR+3:   sd_addr <= { 4'b0010, addr[8:0] }; 
      WR+4:   sd_wren <= 1'b1;
      WR+5:   sd_cmd  <= CMD_WRITE;              
      // ... 128 write cycles
      WR+130: put     <= 1'b0;                   
      WR+133: sd_cmd  <= CMD_BURST_TERMINATE;    
      WR+134: sd_wren <= 1'b0;                   
      WR+135: sd_cmd  <= CMD_PRECHARGE; /* ALL */
      WR+140: t       <= STBY+1;

      endcase
    end
  end

endmodule

