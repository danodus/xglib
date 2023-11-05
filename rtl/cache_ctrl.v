// ref.: https://gitlab.com/r1809/rvsoc/-/blob/main/src/mem2.v

/*
 * 16KB four way, set associative cache w/ 256 byte cache lines
 *
 * This source code is public domain
 *
 */

module cache_ctrl (

  // CPU interface
  input  wire        cpu_clk,     // CPU clk
  input  wire        ram_clk,     // SDR clk
  input  wire        rst,         // reset

  input  wire [31:0] m_addr,      // address
  input  wire [31:0] m_din,       // data to cache
  output wire [31:0] m_dout,      // data to CPU
  input  wire  [3:0] m_ctrl,      // partial word mask
  input  wire        m_rd,        // request mem RD transaction
  input  wire        m_wr,        // request mem WR transaction
  output wire        m_bsy,       // report mem ready

  // RAM interface
  output wire     [15:0] ram_din_o,
  input wire     [15:0] ram_dout_i,
  output wire     [23:0] ram_addr_o,
  input wire            ram_get_i,
  input wire            ram_put_i,
  output wire            ram_rd_o,
  output wire            ram_wr_o
);

  // ---------------------------------------------------------------------
  // ----------------- bus interface -------------------------------------
  // ---------------------------------------------------------------------
  
  // Latch rd selection lines
  //
  reg  [3:0] ctrl;
  reg [31:0] addr;
  reg [31:0] din;
  reg        rd, wr;
  always @(posedge cpu_clk) begin
    if(rst) begin rd <= 1'b0; wr <= 1'b0; end;
    if(m_rd|m_wr) begin
      addr <= m_addr; ctrl <= m_ctrl; din <= m_din;
      rd <= m_rd; wr <= m_wr;
    end
    if(!m_bsy) begin rd <= m_rd; wr <= m_wr; end
  end
    
  reg mstat, xreq;
  always @(posedge cpu_clk) begin
    if(rst)                     mstat <= 0;
    if((m_rd|m_wr) & mstat==0)  mstat <= 1;
    if(mstat==1 & (valid))      mstat <= 0;
    xreq <= m_req;
  end;
  wire req = xreq;
  
  wire m_req   = (m_rd|m_wr) & !rst;
  wire valid   = m_req & !m_bsy & hit;
  assign m_bsy = !mrdy | (m_req & ((!hit) | mstat==0 | cstat!=0));
  
  // note: does not handle mis-alignment
  //
  wire [31:0] x_dout = c_dout;
  wire [31:0] dout = x_dout >> { addr[1:0], 3'b0 };

  assign m_dout = dout;

  wire [31:0] xin = din;
  wire  [3:0] wmask = ctrl;

  // ---------------------------------------------------------------------
  // ------------------------ cache tag management -----------------------
  // ---------------------------------------------------------------------

  localparam bWAY = 2, WAYS = (1<<bWAY);  // 2 bits,  4 way
  localparam bSET = 4, SETS = (1<<bSET);  // 4 bits, 16 sets

  // { [31:12] tag ; [11:8] set ; [7:0] (byte) cache line }
  //
  wire  [bSET-1:0] set = addr[bSET+7:8];
  wire [23-bSET:0] tag = addr[31:bSET+8];

  // For each way in the cache define a tag table & comparator
  //
  reg  [23-bSET:0] tag0[0:SETS-1], tag1[0:SETS-1], tag2[0:SETS-1], tag3[0:SETS-1];
  
  wire fnd0 = (tag0[set] == tag), fnd1 = (tag1[set] == tag);
  wire fnd2 = (tag2[set] == tag), fnd3 = (tag3[set] == tag);
  wire hit  = fnd0 | fnd1 | fnd2 | fnd3;

  // Init tags to be non-conflicting
  //
  integer j;
  initial begin
      for(j=0; j<SETS; j=j+1) begin
        tag0[j]   = 20'h90000;      tag1[j] = 20'h90001;      tag2[j] = 20'h90002;      tag3[j] = 20'h90003;
        dirty0[j] = 1'b0; dirty1[j] = 1'b0; dirty2[j] = 1'b0; dirty3[j] = 1'b0;
      end
  end

  // Replacement policy: "Random"
  //
  reg [bWAY-1:0] repl = 0;
  always @(posedge cpu_clk) repl <= repl + 1;
  
  // Update tag bits
  //
  reg   [bWAY-1:0]  nidx;  // idx to replace
  reg  [23-bSET:0]  wtag;  // tag to save
  reg  [23-bSET:0]  rtag;  // tag to read
  reg               dirty; // save necessary
  
  reg   [SETS-1:0]  dirty0, dirty1, dirty2, dirty3;   // dirty bits per set
  
  // These three are used to sync the CPU and the RAM clock domains
  //
  reg start, stop, ackn;

  reg [1:0] cstat = 0;
  always @(posedge cpu_clk) begin
    case(cstat)

    0:  begin
          rtag  <= tag;
          nidx  <= repl;
          start <= 1'b0; ackn <= 1'b1;
          if(req & !hit) cstat <= 1;
        end
        
    1:  begin
          if (nidx==0) begin wtag <= tag0[set]; tag0[set] <= rtag; dirty <= dirty0[set]; end
          if (nidx==1) begin wtag <= tag1[set]; tag1[set] <= rtag; dirty <= dirty1[set]; end
          if (nidx==2) begin wtag <= tag2[set]; tag2[set] <= rtag; dirty <= dirty2[set]; end
          if (nidx==3) begin wtag <= tag3[set]; tag3[set] <= rtag; dirty <= dirty3[set]; end
          start <= 1'b1; ackn <= 1'b0;
          cstat <= 2;
        end

    2:  begin
          start <= 1'b0;
          if(stop) cstat <= 0;
        end

    endcase
  end

  // Update dirty bits
  //
  always @(posedge cpu_clk) begin
    if(valid) begin
      if (fnd0) dirty0[set] <= dirty0[set] | wr;
      if (fnd1) dirty1[set] <= dirty1[set] | wr;
      if (fnd2) dirty2[set] <= dirty2[set] | wr;
      if (fnd3) dirty3[set] <= dirty3[set] | wr;
    end
    if(cstat==2) begin
      if (fnd0) dirty0[set] <= 1'b0;
      if (fnd1) dirty1[set] <= 1'b0;
      if (fnd2) dirty2[set] <= 1'b0;
      if (fnd3) dirty3[set] <= 1'b0;
    end
  end

  // ---------------------------------------------------------------------
  // --------------------- cacheline update controller -------------------
  // ---------------------------------------------------------------------

  reg mrdy;
  always @(posedge cpu_clk) begin
    if(rst)         mrdy <= 1'b1;
    if(req & !hit)  mrdy <= 1'b0;
    if(!mrdy)       mrdy <= 1'b1; // FIXME
  end

  localparam STBY = 3'd0, RD = 3'd1, WT1 = 3'd2, WR = 3'd3,
             SW   = 3'd4, WT = 3'd5, WT2 = 3'd6;

  reg   [2:0] rstat;
  reg  [23:0] ram_addr;    // high part of ram address (256 byte line)
  reg         ram_rd, ram_wr;
  
  always @(posedge ram_clk) begin
    if (rst) begin rstat <= STBY; end
    else begin
    case (rstat)

    STBY: begin
            stop <= 1'b0;
            if (start) rstat <= WT;
          end
    
    WT:   begin
            ram_addr <= dirty ? { wtag, set } : { rtag, set };
            rstat    <= dirty ?      WR       :       RD;
          end
            
    // Write cache line
    WR:   if (done) begin
            ram_addr <= { rtag, set };
            rstat <= SW;
          end
    SW:   rstat <= RD;

    // Read cache line
    RD:   if (done) begin
            rstat <= WT1;
          end
    WT1:  begin
            stop <= 1'b1;
            rstat <= WT2;
          end

    WT2:  if (ackn) rstat <= STBY;

    endcase
    end
    ram_rd <= (rstat==RD);
    ram_wr <= (rstat==WR);
  end

  // Mirror SDRAM address: count out 256 bytes (128 sdram words)
  //
  reg [7:0] ram_ctr;  // mirror address
  wire      ram_get;  // signal from SDRAM to store data
  wire      ram_put;  // signal from SDRAM to send data
  wire      zctr = (rstat == WT1) | (rstat == SW);

  always @(posedge ram_clk) begin
    if (ram_get | ram_put) ram_ctr <= ram_ctr + 1;
    else if (zctr|rst)     ram_ctr <= 8'b0;
  end
  wire done = ram_ctr[7];  // full cache line processed
  
  // Cache RAM
  //
  wire     [31:0] c_dout;
  wire            c_write = wr & valid;
  wire      [3:0] c_wmask = {4{c_write}} & wmask;
  wire [bWAY-1:0] c_way = { fnd3|fnd2, fnd3|fnd1 };

  wire     [15:0] ram_dout;
  wire     [31:0] r_din;
  reg      [15:0] ram_din;
  wire      [3:0] r_wmask = {4{ram_get}} & (ram_ctr[0] ? 4'b1100 : 4'b0011);
  
  always @(posedge ram_clk) ram_din <= (!ram_ctr[0]) ? r_din[31:16] : r_din[15:0];

  CRAM cram( .c_clk(cpu_clk),
             .c_addr({ c_way, set,   addr[7:2] }),
             .c_din(xin),
             .c_dout(c_dout),
             .c_re(rd),
             .c_wmask(c_wmask),
             
             .r_clk(ram_clk),
             .r_addr({ nidx, set, ram_ctr[6:1] }),
             .r_din({ ram_dout, ram_dout }),
             .r_dout(r_din),
             .r_re(1'b1),
             .r_wmask(r_wmask)
           );

           assign ram_din_o = ram_din;
           assign ram_dout = ram_dout_i;
           assign ram_addr_o = ram_addr;
           assign ram_get = ram_get_i;
           assign ram_put = ram_put_i;
           assign ram_rd_o = ram_rd;
           assign ram_wr_o = ram_wr;

endmodule

/*
 * Dual ported cache ram
 */

module CRAM (
  input  wire        c_clk,        // cpu side
  input  wire [11:0] c_addr,
  input  wire [31:0] c_din, 
  output reg  [31:0] c_dout,
  input  wire        c_re,  
  input  wire  [3:0] c_wmask,
  
  input  wire        r_clk,        // ram side
  input  wire [11:0] r_addr,
  input  wire [31:0] r_din, 
  output reg  [31:0] r_dout,
  input  wire        r_re,  
  input  wire  [3:0] r_wmask
);

  reg [31:0] mem[0:4095];

  always @(posedge c_clk) begin
    if (c_re) c_dout <= mem[c_addr];
  end
  
  always @(posedge c_clk) begin
    if (c_wmask[3]) mem[c_addr][31:24] <= c_din[31:24];
    if (c_wmask[2]) mem[c_addr][23:16] <= c_din[23:16];
    if (c_wmask[1]) mem[c_addr][15: 8] <= c_din[15: 8];
    if (c_wmask[0]) mem[c_addr][ 7: 0] <= c_din[ 7: 0];
  end

  always @(posedge r_clk) begin
    if (r_re) r_dout <= mem[r_addr];
  end
  
  always @(posedge r_clk) begin
    if (r_wmask[3]) mem[r_addr][31:24] <= r_din[31:24];
    if (r_wmask[2]) mem[r_addr][23:16] <= r_din[23:16];
    if (r_wmask[1]) mem[r_addr][15: 8] <= r_din[15: 8];
    if (r_wmask[0]) mem[r_addr][ 7: 0] <= r_din[ 7: 0];
  end

  integer i;
  initial begin
    for(i=0; i<4096; i=i+1)
      mem[i] = (i<<1 | (((i<<1)+1) << 16));
  end

endmodule
