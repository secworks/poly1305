//======================================================================
//
// poly1305_core.v
// ---------------
// Core functionality of the poly1305 mac.
//
// Copyright (c) 2017, Secworks Sweden AB
// Joachim Strömbergson
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module poly1305_core(
                     input wire           clk,
                     input wire           reset_n,

                     input wire           init,
                     input wire           next,
                     input wire           finish,

                     output wire          ready,

                     input wire [255 : 0] key,
                     input wire [127 : 0] block,
                     input wire [4 : 0]   blocklen,

                     output wire [127 : 0] mac
                    );

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE  = 2'h0;
  localparam CTRL_INIT  = 2'h1;
  localparam CTRL_NEXT  = 2'h2;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg  [31 : 0] h0_reg;
  wire [31 : 0] h0_new;
  reg  [31 : 0] h1_reg;
  wire [31 : 0] h1_new;
  reg  [31 : 0] h2_reg;
  wire [31 : 0] h2_new;
  reg  [31 : 0] h3_reg;
  wire [31 : 0] h3_new;
  reg  [31 : 0] h4_reg;
  wire [31 : 0] h4_new;
  reg           h_we;

  reg [31 : 0]  c0_reg;
  reg [31 : 0]  c0_new;
  reg [31 : 0]  c1_reg;
  reg [31 : 0]  c1_new;
  reg [31 : 0]  c2_reg;
  reg [31 : 0]  c2_new;
  reg [31 : 0]  c3_reg;
  reg [31 : 0]  c3_new;
  reg [31 : 0]  c4_reg;
  reg [31 : 0]  c4_new;
  reg           c_we;

  reg [31 : 0]  r0_reg;
  reg [31 : 0]  r0_new;
  reg [31 : 0]  r1_reg;
  reg [31 : 0]  r1_new;
  reg [31 : 0]  r2_reg;
  reg [31 : 0]  r2_new;
  reg [31 : 0]  r3_reg;
  reg [31 : 0]  r3_new;
  reg [31 : 0]  r4_reg;
  reg [31 : 0]  r4_new;
  reg           r_we;

  reg [31 : 0]  pad0_reg;
  reg [31 : 0]  pad0_new;
  reg [31 : 0]  pad1_reg;
  reg [31 : 0]  pad1_new;
  reg [31 : 0]  pad2_reg;
  reg [31 : 0]  pad2_new;
  reg [31 : 0]  pad3_reg;
  reg [31 : 0]  pad3_new;
  reg           pad_we;

  reg [31 : 0]  mac0_reg;
  reg [31 : 0]  mac0_new;
  reg [31 : 0]  mac1_reg;
  reg [31 : 0]  mac1_new;
  reg [31 : 0]  mac2_reg;
  reg [31 : 0]  mac2_new;
  reg [31 : 0]  mac3_reg;
  reg [31 : 0]  mac3_new;
  reg           mac_we;

  reg [1 : 0] poly1305_core_ctrl_reg;
  reg [1 : 0] poly1305_core_ctrl_new;
  reg         poly1305_core_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg pblock_next;
  wire pblock_ready;

  reg state_init;
  reg state_update;
  reg state_final;
  reg load_block;
  reg mac_update;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign mac[031 : 000] = mac0_reg;
  assign mac[063 : 032] = mac1_reg;
  assign mac[095 : 064] = mac2_reg;
  assign mac[127 : 096] = mac3_reg;


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  poly1305_pblock pblock(
                         .clk(clk),
                         .reset_n(reset_n),
                         .next(pblock_next),
                         .ready(pblock_ready),
                         .h0(h0_reg),
                         .h1(h1_reg),
                         .h2(h2_reg),
                         .h3(h3_reg),
                         .h4(h4_reg),
                         .c0(c0_reg),
                         .c1(c1_reg),
                         .c2(c2_reg),
                         .c3(c3_reg),
                         .c4(c4_reg),
                         .r0(r0_reg),
                         .r1(r1_reg),
                         .r2(r2_reg),
                         .r3(r3_reg),
                         .h0_new(h0_new),
                         .h1_new(h1_new),
                         .h2_new(h2_new),
                         .h3_new(h3_new),
                         .h4_new(h4_new)
                        );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin : reg_update
      if (!reset_n)
        begin
          h0_reg <= 32'h0;
          h1_reg <= 32'h0;
          h2_reg <= 32'h0;
          h3_reg <= 32'h0;
          h4_reg <= 32'h0;

          c0_reg <= 32'h0;
          c1_reg <= 32'h0;
          c2_reg <= 32'h0;
          c3_reg <= 32'h0;
          c4_reg <= 32'h0;

          r0_reg <= 32'h0;
          r1_reg <= 32'h0;
          r2_reg <= 32'h0;
          r3_reg <= 32'h0;

          pad0_reg <= 32'h0;
          pad1_reg <= 32'h0;
          pad2_reg <= 32'h0;
          pad3_reg <= 32'h0;

          mac0_reg <= 32'h0;
          mac1_reg <= 32'h0;
          mac2_reg <= 32'h0;
          mac3_reg <= 32'h0;

          poly1305_core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (h_we)
            begin
              h0_reg <= h0_new;
              h1_reg <= h1_new;
              h2_reg <= h2_new;
              h3_reg <= h3_new;
              h4_reg <= h4_new;
            end

          if (c_we)
            begin
              c0_reg <= c0_new;
              c1_reg <= c1_new;
              c2_reg <= c2_new;
              c3_reg <= c3_new;
              c4_reg <= c4_new;
            end

          if (r_we)
            begin
              r0_reg <= r0_new;
              r1_reg <= r1_new;
              r2_reg <= r2_new;
              r3_reg <= r3_new;
            end

          if (pad_we)
            begin
              pad0_reg <= pad0_new;
              pad1_reg <= pad1_new;
              pad2_reg <= pad2_new;
              pad3_reg <= pad3_new;
            end

          if (mac_we)
            begin
              mac0_reg <= mac0_new;
              mac1_reg <= mac1_new;
              mac2_reg <= mac2_new;
              mac3_reg <= mac3_new;
            end

          if (poly1305_core_ctrl_we)
            poly1305_core_ctrl_reg <= poly1305_core_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // poly1305_core_logic
  //----------------------------------------------------------------
  always @*
    begin : poly1305_core_logic
      c0_new = 32'h0;
      c1_new = 32'h0;
      c2_new = 32'h0;
      c3_new = 32'h0;
      c4_new = 32'h0;
      c_we   = 1'h0;

      h_we   = 1'h0;

      r0_new = 32'h0;
      r1_new = 32'h0;
      r2_new = 32'h0;
      r3_new = 32'h0;
      r4_new = 32'h0;
      r_we   = 1'h0;

      pad0_new = 32'h0;
      pad1_new = 32'h0;
      pad2_new = 32'h0;
      pad3_new = 32'h0;
      pad_we   = 1'h0;

      mac0_new = 32'h0;
      mac1_new = 32'h0;
      mac2_new = 32'h0;
      mac3_new = 32'h0;
      mac_we   = 1'h0;

      if (state_init)
        begin
          c4_new = 32'h1;
          c_we   = 1'h1;

          r0_new = key[031 : 000];
          r1_new = key[063 : 032] & 32'hfffffffc;
          r2_new = key[095 : 064] & 32'hfffffffc;
          r3_new = key[127 : 096] & 32'hfffffffc;
          r4_new = key[191 : 128] & 32'hfffffffc;
          r_we   = 1'h0;

          pad0_new = key[159 : 128];
          pad1_new = key[191 : 160];
          pad2_new = key[223 : 192];
          pad3_new = key[255 : 224];
          pad_we   = 1'h1;
        end

      if (load_block)
        begin
          c0_new = block[031 : 000];
          c1_new = block[063 : 032];
          c2_new = block[095 : 064];
          c3_new = block[127 : 096];
          c4_new = block[127 : 096];
          c_we = 1'h1;
        end

      if (state_update)
        begin
          c_we = 1'h1;
          h_we = 1'h1;
        end

      if (state_final)
        begin
          c_we = 1'h1;
          r_we = 1'h1;
        end

      if (mac_update)
        begin
          mac0_new = 32'h0;
          mac1_new = 32'h0;
          mac2_new = 32'h0;
          mac3_new = 32'h0;
          mac_we = 1'h1;
        end

    end // poly1305_core_logic


  //----------------------------------------------------------------
  // poly1305_core_ctrl
  //----------------------------------------------------------------
  always @*
    begin : poly1305_core_ctrl
      state_init             = 1'h0;
      load_block             = 1'h0;
      state_update           = 1'h0;
      state_final            = 1'h0;
      mac_update             = 1'h0;
      poly1305_core_ctrl_reg = CTRL_IDLE;


      case (poly1305_core_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                state_init = 1'h1;
              end

            if (next)
              begin
                state_update = 1'h1;
              end

            if (finish)
              begin
                state_final = 1'h1;
              end
          end

        default:
          begin
          end
      endcase // case (poly1305_core_ctrl_reg)
    end

endmodule // poly1305_core

//======================================================================
// EOF poly1305_core.v
//======================================================================
