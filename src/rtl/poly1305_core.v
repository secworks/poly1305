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
                     input wire           update,
                     input wire           finish,

                     input wire [255 : 0] key,
                     input wire [255 : 0] chunk,

                     output wire [127 : 0] mac
                    );


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [31 : 0] h0_reg;
  reg [31 : 0] h0_new;
  reg [31 : 0] h1_reg;
  reg [31 : 0] h1_new;
  reg [31 : 0] h2_reg;
  reg [31 : 0] h2_new;
  reg [31 : 0] h3_reg;
  reg [31 : 0] h3_new;
  reg [31 : 0] h4_reg;
  reg [31 : 0] h4_new;
  reg          h_we;

  reg [31 : 0] c0_reg;
  reg [31 : 0] c0_new;
  reg [31 : 0] c1_reg;
  reg [31 : 0] c1_new;
  reg [31 : 0] c2_reg;
  reg [31 : 0] c2_new;
  reg [31 : 0] c3_reg;
  reg [31 : 0] c3_new;
  reg [31 : 0] c4_reg;
  reg [31 : 0] c4_new;
  reg          c_we;

  reg [31 : 0] r0_reg;
  reg [31 : 0] r0_new;
  reg [31 : 0] r1_reg;
  reg [31 : 0] r1_new;
  reg [31 : 0] r2_reg;
  reg [31 : 0] r2_new;
  reg [31 : 0] r3_reg;
  reg [31 : 0] r3_new;
  reg          r_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg pblock_next;
  wire pblock_ready;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  poly1305_block pblock(
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
          r4_reg <= 32'h0;
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
        end
    end // reg_update


  //----------------------------------------------------------------
  // poly1305_core_ctrl
  //----------------------------------------------------------------
  always @*
    begin : poly1305_core_ctrl
      h_we = 1'h0;
      c_we = 1'h0;
      r_we = 1'h0;

    end

endmodule // poly1305_core

//======================================================================
// EOF poly1305_core.v
//======================================================================
