//======================================================================
//
// poly1305_pblock.v
// -----------------
// Implementation of the polynomial processing of a block.
//
// Copyright (c) 2017, Assured AB
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

module poly1305_pblock(
                       input wire          clk,
                       input wire          reset_n,

                       input wire          next,
                       output wire         ready,

                       input wire [31 : 0] h0,
                       input wire [31 : 0] h1,
                       input wire [31 : 0] h2,
                       input wire [31 : 0] h3,
                       input wire [31 : 0] h4,

                       input wire [31 : 0] c0,
                       input wire [31 : 0] c1,
                       input wire [31 : 0] c2,
                       input wire [31 : 0] c3,
                       input wire [31 : 0] c4,

                       input wire [31 : 0] r0,
                       input wire [31 : 0] r1,
                       input wire [31 : 0] r2,
                       input wire [31 : 0] r3,

                       output wire [31 : 0] h0_new,
                       output wire [31 : 0] h1_new,
                       output wire [31 : 0] h2_new,
                       output wire [31 : 0] h3_new,
                       output wire [31 : 0] h4_new
                      );

  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [32 : 0] s0_reg;
  reg [32 : 0] s0_new;

  reg [32 : 0] s1_reg;
  reg [32 : 0] s1_new;

  reg [32 : 0] s2_reg;
  reg [32 : 0] s2_new;

  reg [32 : 0] s3_reg;
  reg [32 : 0] s3_new;

  reg [32 : 0] s4_reg;
  reg [32 : 0] s4_new;

  reg [31 : 0] rr0_reg;
  reg [31 : 0] rr0_new;

  reg [31 : 0] rr1_reg;
  reg [31 : 0] rr1_new;

  reg [31 : 0] rr2_reg;
  reg [31 : 0] rr2_new;

  reg [31 : 0] rr3_reg;
  reg [31 : 0] rr3_new;

  reg [63 : 0] x0_reg;
  reg [63 : 0] x0_new;

  reg [63 : 0] x1_reg;
  reg [63 : 0] x1_new;

  reg [63 : 0] x2_reg;
  reg [63 : 0] x2_new;

  reg [63 : 0] x3_reg;
  reg [63 : 0] x3_new;

  reg [63 : 0] x4_reg;
  reg [63 : 0] x4_new;

  reg [63 : 0] u0_reg;
  reg [63 : 0] u0_new;

  reg [63 : 0] u1_reg;
  reg [63 : 0] u1_new;

  reg [63 : 0] u2_reg;
  reg [63 : 0] u2_new;

  reg [63 : 0] u3_reg;
  reg [63 : 0] u3_new;

  reg [63 : 0] u4_reg;
  reg [63 : 0] u4_new;

  reg [31 : 0] u5_reg;
  reg [31 : 0] u5_new;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign h0_new  = u0_reg[31 : 0];
  assign h1_new  = u1_reg[31 : 0];
  assign h2_new  = u2_reg[31 : 0];
  assign h3_new  = u3_reg[31 : 0];
  assign h4_new  = u4_reg[31 : 0];


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
          s0_reg  <= 33'h0;
          s1_reg  <= 33'h0;
          s2_reg  <= 33'h0;
          s3_reg  <= 33'h0;
          s4_reg  <= 33'h0;

          rr0_reg <= 32'h0;
          rr1_reg <= 32'h0;
          rr2_reg <= 32'h0;
          rr3_reg <= 32'h0;

          x0_reg  <= 64'h0;
          x1_reg  <= 64'h0;
          x2_reg  <= 64'h0;
          x3_reg  <= 64'h0;
          x4_reg  <= 64'h0;

          u0_reg  <= 64'h0;
          u1_reg  <= 64'h0;
          u2_reg  <= 64'h0;
          u3_reg  <= 64'h0;
          u4_reg  <= 64'h0;
          u5_reg  <= 32'h0;
        end
      else
        begin
          s0_reg <= s0_new;
          s1_reg <= s1_new;
          s2_reg <= s2_new;
          s3_reg <= s3_new;
          s4_reg <= s4_new;

          rr0_reg <= rr0_new;
          rr1_reg <= rr1_new;
          rr2_reg <= rr2_new;
          rr3_reg <= rr3_new;

          x0_reg <= x0_new;
          x1_reg <= x1_new;
          x2_reg <= x2_new;
          x3_reg <= x3_new;
          x4_reg <= x4_new;

          u0_reg <= u0_new;
          u1_reg <= u1_new;
          u2_reg <= u2_new;
          u3_reg <= u3_new;
          u4_reg <= u4_new;
          u5_reg <= u5_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // pblock_logic
  //----------------------------------------------------------------
  always @*
    begin : pblock_logic
      // s = h + c, no carry propagation.
      s0_new = h0 + c0;
      s1_new = h1 + c1;
      s2_new = h2 + c2;
      s3_new = h3 + c3;
      s4_new = h4 + c4;


      // Multiply r.
      rr0_new = {2'h0, r0[31 : 2]} * 32'h5;
      rr1_new = {2'h0, r1[31 : 2]} + r1;
      rr2_new = {2'h0, r2[31 : 2]} + r2;
      rr3_new = {2'h0, r3[31 : 2]} + r3;


      // Big mult-add trees.
      // To be optimized.
      x0_new = (s0_reg * r0) + (s1_reg * rr3_reg) + (s2_reg * rr2_reg) +
               (s3_reg * rr1_reg) + (s4_reg * rr0_reg);

      x1_new = (s0_reg * r1) + (s1_reg * r0)  + (s2_reg * rr3_reg) +
               (s3_reg * rr2_reg) + (s4_reg * rr1_reg);

      x2_new = (s0_reg * r2) + (s1_reg * r1) + (s2_reg * r0) +
               (s3_reg * rr3_reg) + (s4_reg * rr2_reg);

      x3_new = (s0_reg * r3) + (s1_reg * r2) + (s2_reg * r1) +
               (s3_reg * r0)  + (s4_reg * rr3_reg);

      x4_new = s4_reg * {32'h0, (r0 & 32'h3)};


      // partial reduction modulo 2^130 - 5
      u5_new = (x4_reg + {32'h0, x3_reg[63 : 32]});
      u0_new = ({2'h0, u5_reg[31 : 2]} * 5) + {32'H0, x0_reg[31 : 0]};
      u1_new = u0_reg[63 : 32] + x1_reg[31 : 0] + x0_reg[63 : 32];
      u2_new = u1_reg[63 : 32] + x2_reg[31 : 0] + x1_reg[63 : 32];
      u3_new = u2_reg[63 : 32] + x3_reg[31 : 0] + x2_reg[63 : 32];
      u4_new = u3_reg[63 : 32] + u5_reg & 32'h3;
    end // pblock_logic

endmodule // poly1305_pblock

//======================================================================
// EOF poly1305_pblock.v
//======================================================================
