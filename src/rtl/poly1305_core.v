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
  reg [31 : 0] s0_reg;
  reg [31 : 0] s0_new;
  reg [31 : 0] s1_reg;
  reg [31 : 0] s1_new;
  reg [31 : 0] s2_reg;
  reg [31 : 0] s2_new;
  reg [31 : 0] s3_reg;
  reg [31 : 0] s3_new;
  reg [31 : 0] s4_reg;
  reg [31 : 0] s4_new;
  reg [31 : 0] s5_reg;
  reg [31 : 0] s5_new;
  reg          s_we;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------


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
          s0_reg <= 32'h0;
          s1_reg <= 32'h0;
          s2_reg <= 32'h0;
          s3_reg <= 32'h0;
          s4_reg <= 32'h0;
        end
      else
        begin
          if (s_we)
            begin
              s0_reg <= s0_new;
              s1_reg <= s1_new;
              s2_reg <= s2_new;
              s3_reg <= s3_new;
              s4_reg <= s4_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // poly_block
  //
  // Perform acc = (acc + c) * r
  //----------------------------------------------------------------
  always @*
    begin : poly_block
      reg [31 : 0] rr0;
      reg [31 : 0] rr1;
      reg [31 : 0] rr2;
      reg [31 : 0] rr3;

      s0_new = h0_reg + c0_reg;
      s1_new = h1_reg + c1_reg;
      s2_new = h2_reg + c2_reg;
      s3_new = h3_reg + c3_reg;
      s4_new = h4_reg + c4_reg;

      rr0 = {2'b0, r0_reg[31 : 2]} * 5;
      rr1 = {2'b0, r1_reg[31 : 2]} + r1;
      rr2 = {2'b0, r2_reg[31 : 2]} + r2;
      rr3 = {2'b0, r3_reg[31 : 2]} + r3;





    end // poly_block


endmodule // poly1305_core

//======================================================================
// EOF poly1305_core.v
//======================================================================
