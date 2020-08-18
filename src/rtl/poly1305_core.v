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
                     input wire            clk,
                     input wire            reset_n,

                     input wire            init,
                     input wire            next,
                     input wire            finish,

                     output wire           ready,

                     input wire [255 : 0]  key,

                     input wire [127 : 0]  block,
                     input wire [4 : 0]    blocklen,

                     output wire [127 : 0] mac
                    );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CTRL_IDLE  = 3'h0;
  localparam CTRL_INIT  = 3'h1;
  localparam CTRL_NEXT  = 3'h2;
  localparam CTRL_FINAL = 3'h3;
  localparam CTRL_DONE  = 3'h7;


  //----------------------------------------------------------------
  // Internal functions.
  //----------------------------------------------------------------
  function [31 : 0] le(input [31 : 0] w);
    le = {w[7 : 0], w[15 : 8], w[23 : 16], w[31 : 24]};
  endfunction // le


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg  [31 : 0] h_reg [0 : 4];
  wire [31 : 0] h_new [0 : 4];
  reg           h_we;

  reg [31 : 0]  c_reg [0 : 4];
  reg [31 : 0]  c_new [0 : 4];
  reg           c_we;

  reg [31 : 0]  r_reg [0 : 3];
  reg [31 : 0]  r_new [0 : 3];
  reg           r_we;

  reg [31 : 0]  pad_reg [0 : 3];
  reg [31 : 0]  pad_new [0 : 3];
  reg           pad_we;

  reg [31 : 0]  mac_reg [0 : 3];
  reg [31 : 0]  mac_new [0 : 3];
  reg           mac_we;

  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  reg [2 : 0]   poly1305_core_ctrl_reg;
  reg [2 : 0]   poly1305_core_ctrl_new;
  reg           poly1305_core_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg  pblock_next;
  wire pblock_ready;

  reg state_init;
  reg state_update;
  reg state_final;
  reg load_block;
  reg mac_update;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign mac[031 : 000] = mac_reg[0];
  assign mac[063 : 032] = mac_reg[1];
  assign mac[095 : 064] = mac_reg[2];
  assign mac[127 : 096] = mac_reg[3];

  assign ready = ready_reg;


  //----------------------------------------------------------------
  // Module instantiations.
  //----------------------------------------------------------------
  poly1305_pblock pblock(
                         .clk(clk),
                         .reset_n(reset_n),

                         .next(pblock_next),
                         .ready(pblock_ready),

                         .h0(h_reg[0]),
                         .h1(h_reg[1]),
                         .h2(h_reg[2]),
                         .h3(h_reg[3]),
                         .h4(h_reg[4]),

                         .c0(c_reg[0]),
                         .c1(c_reg[1]),
                         .c2(c_reg[2]),
                         .c3(c_reg[3]),
                         .c4(c_reg[4]),

                         .r0(r_reg[0]),
                         .r1(r_reg[1]),
                         .r2(r_reg[2]),
                         .r3(r_reg[3]),

                         .h0_new(h_new[0]),
                         .h1_new(h_new[1]),
                         .h2_new(h_new[2]),
                         .h3_new(h_new[3]),
                         .h4_new(h_new[4])
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
      integer i;
      if (!reset_n)
        begin
          for (i = 0 ; i < 5 ; i = i + 1)
            begin
              h_reg[i] <= 32'h0;
              c_reg[i] <= 32'h0;
            end

          for (i = 0 ; i < 4 ; i = i + 1)
            begin
              r_reg[i]   <= 32'h0;
              pad_reg[i] <= 32'h0;
              mac_reg[i] <= 32'h0;
            end

          ready_reg              <= 1'h1;
          poly1305_core_ctrl_reg <= CTRL_IDLE;
        end
      else
        begin
          if (ready_we)
            ready_reg <= ready_new;

          if (h_we)
            begin
              for (i = 0 ; i < 5 ; i = i + 1)
                h_reg[i] <= h_new[i];
            end

          if (c_we)
            begin
              for (i = 0 ; i < 5 ; i = i + 1)
                c_reg[i] <= c_new[i];
            end

          if (r_we)
            begin
              for (i = 0 ; i < 4 ; i = i + 1)
                r_reg[i] <= r_new[i];
            end

          if (pad_we)
            begin
              for (i = 0 ; i < 4 ; i = i + 1)
                pad_reg[i] <= pad_new[i];
            end

          if (mac_we)
            begin
              for (i = 0 ; i < 4 ; i = i + 1)
                mac_reg[i] <= mac_new[i];
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
      integer i;

      h_we = 1'h0;

      for (i = 0 ; i < 5 ; i = i + 1)
        c_new[i] = 32'h0;
      c_we = 1'h0;

      for (i = 0 ; i < 4 ; i = i + 1)
        r_new[i] = 32'h0;
      r_we = 1'h0;

      for (i = 0 ; i < 4 ; i = i + 1)
        pad_new[i] = 32'h0;
      pad_we = 1'h0;

      for (i = 0 ; i < 4 ; i = i + 1)
        mac_new[i] = 32'h0;
      mac_we = 1'h0;


      if (state_init)
        begin
          c_new[4] = 32'h1;
          c_we     = 1'h1;

          h_we     = 1'h1;

          r_new[0] = le(key[255 : 224]) & 32'h0fffffff;
          r_new[1] = le(key[223 : 192]) & 32'h0ffffffc;
          r_new[2] = le(key[191 : 160]) & 32'h0ffffffc;
          r_new[3] = le(key[159 : 128]) & 32'h0ffffffc;
          r_we     = 1'h1;

          pad_new[0] = le(key[127 : 096]);
          pad_new[1] = le(key[095 : 064]);
          pad_new[2] = le(key[063 : 032]);
          pad_new[3] = le(key[031 : 000]);
          pad_we     = 1'h1;
        end


      if (load_block)
        begin
          c_new[0] = block[031 : 000];
          c_new[1] = block[063 : 032];
          c_new[2] = block[095 : 064];
          c_new[3] = block[127 : 096];
          c_new[4] = block[127 : 096];
          c_we     = 1'h1;
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
          mac_new[0] = 32'h0;
          mac_new[1] = 32'h0;
          mac_new[2] = 32'h0;
          mac_new[3] = 32'h0;
          mac_we     = 1'h1;
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
      ready_new              = 1'h0;
      ready_we               = 1'h0;
      poly1305_core_ctrl_new = CTRL_IDLE;
      poly1305_core_ctrl_we  = 1'h0;


      case (poly1305_core_ctrl_reg)
        CTRL_IDLE:
          begin
            if (init)
              begin
                state_init             = 1'h1;
                ready_new              = 1'h0;
                ready_we               = 1'h1;
                poly1305_core_ctrl_new = CTRL_DONE;
                poly1305_core_ctrl_we  = 1'h1;
              end

            if (next)
              begin
                state_update = 1'h1;
                ready_new              = 1'h0;
                ready_we               = 1'h1;
                poly1305_core_ctrl_new = CTRL_NEXT;
                poly1305_core_ctrl_we  = 1'h1;
              end

            if (finish)
              begin
                state_final = 1'h1;
                ready_new              = 1'h0;
                ready_we               = 1'h1;
                poly1305_core_ctrl_new = CTRL_FINAL;
                poly1305_core_ctrl_we  = 1'h1;
              end
          end


        CTRL_NEXT:
          begin
            poly1305_core_ctrl_new = CTRL_DONE;
            poly1305_core_ctrl_we  = 1'h1;
          end


        CTRL_FINAL:
          begin
            poly1305_core_ctrl_new = CTRL_DONE;
            poly1305_core_ctrl_we  = 1'h1;
          end


        CTRL_DONE:
          begin
            ready_new              = 1'h1;
            ready_we               = 1'h1;
            poly1305_core_ctrl_new = CTRL_IDLE;
            poly1305_core_ctrl_we  = 1'h1;
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
