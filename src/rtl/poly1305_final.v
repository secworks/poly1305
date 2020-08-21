//======================================================================
//
// poly1305_final.v
// ----------------
// Implementation of the final processing.
//
// Copyright (c) 2020, Assured AB
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

module poly1305_final(
                      input wire [31 : 0] h0,
                      input wire [31 : 0] h1,
                      input wire [31 : 0] h2,
                      input wire [31 : 0] h3,
                      input wire [31 : 0] h4,

                      input wire [31 : 0] s0,
                      input wire [31 : 0] s1,
                      input wire [31 : 0] s2,
                      input wire [31 : 0] s3,

                      output wire [31 : 0] uu0_new,
                      output wire [31 : 0] uu1_new,
                      output wire [31 : 0] uu2_new,
                      output wire [31 : 0] uu3_new
                      );

  //----------------------------------------------------------------
  // Registers (Variables)
  //----------------------------------------------------------------
  reg [63 : 0] uu0;
  reg [63 : 0] uu1;
  reg [63 : 0] uu2;
  reg [63 : 0] uu3;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign uu0_new  = uu0[31 : 0];
  assign uu1_new  = uu1[31 : 0];
  assign uu2_new  = uu2[31 : 0];
  assign uu3_new  = uu3[31 : 0];


  //----------------------------------------------------------------
  // final_logic
  //----------------------------------------------------------------
  always @*
    begin : final_logic
      reg [63 : 0] u0;
      reg [63 : 0] u1;
      reg [63 : 0] u2;
      reg [63 : 0] u3;
      reg [63 : 0] u4;

      u0 = 64'h5       + h0; // <= 1_00000004
      u1 = u0[63 : 32] + h1; // <= 1_00000000
      u2 = u1[63 : 32] + h2; // <= 1_00000000
      u3 = u2[63 : 32] + h3; // <= 1_00000000
      u4 = u3[63 : 32] + h4; // <=          5

      uu0 = (u4[63 : 2] * 5) + h0 + s0; // <= 2_00000003
      uu1 = uu0[63 : 32]     + h1 + s1; // <= 2_00000000
      uu2 = uu1[63 : 32]     + h2 + s2; // <= 2_00000000
      uu3 = uu2[63 : 32]     + h3 + s3; // <= 2_00000000
    end

endmodule // poly1305_final

//======================================================================
// EOF poly1305_final.v
//======================================================================
