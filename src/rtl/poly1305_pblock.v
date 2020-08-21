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
  // Registers (Variables)
  //----------------------------------------------------------------
  reg [63 : 0] u0;
  reg [63 : 0] u1;
  reg [63 : 0] u2;
  reg [63 : 0] u3;
  reg [63 : 0] u4;
  reg [63 : 0] u5;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign h0_new  = u0[31 : 0];
  assign h1_new  = u1[31 : 0];
  assign h2_new  = u2[31 : 0];
  assign h3_new  = u3[31 : 0];
  assign h4_new  = u4[31 : 0];


  //----------------------------------------------------------------
  // pblock_logic
  //----------------------------------------------------------------
  always @*
    begin : pblock_logic
      reg [63 : 0] s0;
      reg [63 : 0] s1;
      reg [63 : 0] s2;
      reg [63 : 0] s3;
      reg [63 : 0] s4;

      reg [31 : 0] rr0;
      reg [31 : 0] rr1;
      reg [31 : 0] rr2;
      reg [31 : 0] rr3;

      reg [63 : 0] x0;
      reg [63 : 0] x1;
      reg [63 : 0] x2;
      reg [63 : 0] x3;
      reg [63 : 0] x4;


      // s = h + c, no carry propagation.
      s0 = h0 + c0;
      s1 = h1 + c1;
      s2 = h2 + c2;
      s3 = h3 + c3;
      s4 = h4 + c4;


      // Multiply r.
      rr0 = {2'h0, r0[31 : 2]} * 32'h5;
      rr1 = {2'h0, r1[31 : 2]} + r1;
      rr2 = {2'h0, r2[31 : 2]} + r2;
      rr3 = {2'h0, r3[31 : 2]} + r3;


      // Big mult-add trees.
      // To be optimized.
      x0 = (s0 * r0)  + (s1 * rr3) + (s2 * rr2) +
           (s3 * rr1) + (s4 * rr0);

      x1 = (s0 * r1)  + (s1 * r0)  + (s2 * rr3) +
           (s3 * rr2) + (s4 * rr1);

      x2 = (s0 * r2)  + (s1 * r1) + (s2 * r0) +
           (s3 * rr3) + (s4 * rr2);

      x3 = (s0 * r3) + (s1 * r2) + (s2 * r1) +
           (s3 * r0) + (s4 * rr3);

      x4 = s4 * {32'h0, (r0 & 32'h3)};


      // partial reduction modulo 2^130 - 5
      u5 = (x4 + {32'h0, x3[63 : 32]});
      u0 = ({2'h0, u5[31 : 2]} * 5) + {32'H0, x0[31 : 0]};
      u1 = u0[63 : 32] + x1[31 : 0] + x0[63 : 32];
      u2 = u1[63 : 32] + x2[31 : 0] + x1[63 : 32];
      u3 = u2[63 : 32] + x3[31 : 0] + x2[63 : 32];
      u4 = u3[63 : 32] + u5 & 32'h3;
    end // pblock_logic

endmodule // poly1305_pblock

//======================================================================
// EOF poly1305_pblock.v
//======================================================================
