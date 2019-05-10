//======================================================================
//
// tb_poly1305_pblock.v
// -------------------
// Testbench for the Poly1305 pblock module.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2019, Assured AB
// All rights reserved.
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

//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_poly1305_pblock();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] error_ctr;
  reg [31 : 0] tc_ctr;

  reg           tb_debug;

  reg           tb_clk;
  reg           tb_reset_n;

  reg           tb_next;
  wire          tb_ready;

  reg [31 : 0]  tb_h0;
  reg [31 : 0]  tb_h1;
  reg [31 : 0]  tb_h2;
  reg [31 : 0]  tb_h3;
  reg [31 : 0]  tb_h4;

  reg [31 : 0]  tb_c0;
  reg [31 : 0]  tb_c1;
  reg [31 : 0]  tb_c2;
  reg [31 : 0]  tb_c3;
  reg [31 : 0]  tb_c4;

  reg [31 : 0]  tb_r0;
  reg [31 : 0]  tb_r1;
  reg [31 : 0]  tb_r2;
  reg [31 : 0]  tb_r3;

  wire [31 : 0] tb_h0_new;
  wire [31 : 0] tb_h1_new;
  wire [31 : 0] tb_h2_new;
  wire [31 : 0] tb_h3_new;
  wire [31 : 0] tb_h4_new;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305_pblock dut(
                      .clk(tb_clk),
                      .reset_n(tb_reset_n),

                      .next(tb_next),
                      .ready(tb_ready),

                      .h0(tb_h0),
                      .h1(tb_h1),
                      .h2(tb_h2),
                      .h3(tb_h3),
                      .h4(tb_h4),

                      .c0(tb_c0),
                      .c1(tb_c1),
                      .c2(tb_c2),
                      .c3(tb_c3),
                      .c4(tb_c4),

                      .r0(tb_r0),
                      .r1(tb_r1),
                      .r2(tb_r2),
                      .r3(tb_r3),

                      .h0_new(tb_h0_new),
                      .h1_new(tb_h1_new),
                      .h2_new(tb_h2_new),
                      .h3_new(tb_h3_new),
                      .h4_new(tb_h4_new)
                     );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;
      #(CLK_PERIOD);
      if (tb_debug)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("State of DUT");
      $display("------------");
      $display("Inputs:");
      $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
               dut.h0, dut.h1, dut.h2, dut.h3, dut.h4);
      $display("c0: 0x%08x  c1: 0x%08x  c2: 0x%08x  c3: 0x%08x  c4: 0x%08x",
               dut.c0, dut.c1, dut.c2, dut.c3, dut.c4);
      $display("r0: 0x%08x  r1: 0x%08x  r2: 0x%08x  r3: 0x%08x",
               dut.r0, dut.r1, dut.r2, dut.r3);
      $display("");

      $display("Intermediate results:");
      $display("s0:  0x%09x  s1: 0x%09x  s2: 0x%09x  s3: 0x%09x  s4: 0x%9x",
               dut.s0_reg, dut.s1_reg, dut.s2_reg, dut.s3_reg, dut.s4_reg);
      $display("rr0: 0x%08x  rr1: 0x%08x  rr2: 0x%08x  rr3: 0x%08x",
               dut.rr0_reg, dut.rr1_reg, dut.rr2_reg, dut.rr3_reg);
      $display("x0:  0x%016x  x1:  0x%016x  x2:  0x%016x  x3:  0x%016x  x4: 0x%016x",
               dut.x0_reg, dut.x1_reg, dut.x2_reg, dut.x3_reg, dut.x4_reg);
      $display("u0:  0x%016x  u1:  0x%016x  u2:  0x%016x  u3:  0x%016x  u4: 0x%016x  u5: 0x%08x",
               dut.u0_reg, dut.u1_reg, dut.u2_reg, dut.u3_reg, dut.u4_reg, dut.u5_reg);
      $display("");


      $display("Outputs:");
      $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
               dut.h0_new, dut.h1_new, dut.h2_new, dut.h3_new, dut.h4_new);
      $display("");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      $display("*** Initializing the simulation.");
      cycle_ctr = 0;
      error_ctr = 0;
      tc_ctr    = 0;
      tb_debug  = 0;

      tb_clk     = 0;
      tb_reset_n = 1;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // display_test_result()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_result;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_result


  //----------------------------------------------------------------
  // test_aa;
  //
  // A very simple test case that sets all inputs to a known,
  // not all zero or not all one bit pattern.
  //----------------------------------------------------------------
  task test_aa;
    begin : test_aa
      tb_h0 = 32'haaaaaaaa;
      tb_h1 = 32'haaaaaaaa;
      tb_h2 = 32'haaaaaaaa;
      tb_h3 = 32'haaaaaaaa;
      tb_h4 = 32'haaaaaaaa;

      tb_c0 = 32'haaaaaaaa;
      tb_c1 = 32'haaaaaaaa;
      tb_c2 = 32'haaaaaaaa;
      tb_c3 = 32'haaaaaaaa;
      tb_c4 = 32'haaaaaaaa;

      tb_r0 = 32'haaaaaaaa;
      tb_r1 = 32'haaaaaaaa;
      tb_r2 = 32'haaaaaaaa;
      tb_r3 = 32'haaaaaaaa;

      tb_debug = 1;
      #(100 * CLK_PERIOD);
      tb_debug = 0;
    end
  endtask // test_aa


  //----------------------------------------------------------------
  // test_rfc8349;
  //
  // Test case that uses the test vectors from RFC 8349,
  // section 2.5.2:
  // https://tools.ietf.org/html/rfc8439#section-2.5.2
  //----------------------------------------------------------------
  task test_rfc8349;
    begin : test_rfc8349
      tb_h0 = 32'h344b30de;
      tb_h1 = 32'hcccfb4ea;
      tb_h2 = 32'hb0337fa7;
      tb_h3 = 32'hd8adaf23;
      tb_h4 = 32'h00000002;

      tb_c0 = 32'h00017075;
      tb_c1 = 32'h00000000;
      tb_c2 = 32'h00000000;
      tb_c3 = 32'h00000000;
      tb_c4 = 32'h00000000;

      tb_r0 = 32'h08bed685;
      tb_r1 = 32'h036d5554;
      tb_r2 = 32'h0e52447c;
      tb_r3 = 32'h0806d540;

      tb_debug = 1;
      #(30 * CLK_PERIOD);
      tb_debug = 0;
    end
  endtask // test_rfc8349


  //----------------------------------------------------------------
  // poly1305_pblock_test
  //----------------------------------------------------------------
  initial
    begin : poly1305_pblock_test
      $display("*** Poly1305 pblock simulation started.\n");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

      // test_aa();
      test_rfc8349();

      display_test_result();

      $display("");
      $display("*** Poly1305 pblock simulation done.\n");
      $finish;
    end // poly1305_pblock_test
endmodule // tb_tb_poly1305_pblock

//======================================================================
// EOF tb_tb_poly1305_pblock.v
//======================================================================
