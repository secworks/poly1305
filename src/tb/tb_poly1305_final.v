//======================================================================
//
// tb_poly1305_final.v
// -------------------
// Testbench for the Poly1305 final module.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2020, Assured AB
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
module tb_poly1305_final();

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
  integer      incorrect;

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

  reg [31 : 0]  tb_s0;
  reg [31 : 0]  tb_s1;
  reg [31 : 0]  tb_s2;
  reg [31 : 0]  tb_s3;

  wire [31 : 0] tb_uu0_new;
  wire [31 : 0] tb_uu1_new;
  wire [31 : 0] tb_uu2_new;
  wire [31 : 0] tb_uu3_new;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305_final dut(
                     .h0(tb_h0),
                     .h1(tb_h1),
                     .h2(tb_h2),
                     .h3(tb_h3),
                     .h4(tb_h4),

                     .s0(tb_s0),
                     .s1(tb_s1),
                     .s2(tb_s2),
                     .s3(tb_s3),

                     .uu0_new(tb_uu0_new),
                     .uu1_new(tb_uu1_new),
                     .uu2_new(tb_uu2_new),
                     .uu3_new(tb_uu3_new)
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
      $display("s0: 0x%08x  s1: 0x%08x  s2: 0x%08x  s3: 0x%08x",
               dut.s0, dut.s1, dut.s2, dut.s3);
      $display("");

      $display("Internal values:");
      $display("u0:  0x%016x  u1: 0x%016x  u2: 0x%016x",
               dut.final_logic.u0, dut.final_logic.u1, dut.final_logic.u2);
      $display("u3:  0x%016x  u4: 0x%016x",
               dut.final_logic.u3, dut.final_logic.u4);
      $display("");

      $display("uu0:  0x%016x  uu1: 0x%016x", dut.uu0, dut.uu1);
      $display("uu2:  0x%016x  uu3: 0x%016x", dut.uu2, dut.uu3);
      $display("");

      $display("Outputs:");
      $display("uu0: 0x%08x  uu1: 0x%08x  uu2: 0x%08x  uu3: 0x%08x",
               dut.uu0_new, dut.uu1_new, dut.uu2_new, dut.uu3_new);
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
      cycle_ctr  = 0;
      error_ctr  = 0;
      tc_ctr     = 0;
      tb_debug   = 0;

      tb_clk     = 0;
      tb_reset_n = 1;

      tb_h0      = 32'h0;
      tb_h1      = 32'h0;
      tb_h2      = 32'h0;
      tb_h3      = 32'h0;
      tb_h4      = 32'h0;

      tb_s0      = 32'h0;
      tb_s1      = 32'h0;
      tb_s2      = 32'h0;
      tb_s3      = 32'h0;
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
  // test_rfc8349;
  //
  // Test case that uses the test vectors from RFC 8349,
  // section 2.5.2:
  // https://tools.ietf.org/html/rfc8439#section-2.5.2
  //----------------------------------------------------------------
  task test_rfc8349;
    begin : test_rfc8349
      $display("*** test_rfc8349 started.\n");

      incorrect = 0;

      tb_h0 = 32'h344b30de;
      tb_h1 = 32'hcccfb4ea;
      tb_h2 = 32'hb0337fa7;
      tb_h3 = 32'hd8adaf23;
      tb_h4 = 32'h00000002;

      tb_s0 = 32'h00017075;
      tb_s1 = 32'h00000000;
      tb_s2 = 32'h00000000;
      tb_s3 = 32'h00000000;

      tb_debug = 1;
      #(30 * CLK_PERIOD);
      tb_debug = 0;

      if (tb_uu0_new != 32'h369d03a7)
        begin
          $display("Error in uu00. Expected: 0x369d03a7. Got: 0x%08x\n",
                   tb_uu0_new);
          incorrect = incorrect + 1;
        end

      if (tb_uu1_new != 32'hc8844335)
        begin
          $display("Error in uu1. Expected: 0xc8844335. Got: 0x%08x\n",
                   tb_uu1_new);
          incorrect = incorrect + 1;
        end

      if (tb_uu2_new != 32'hff946c77)
        begin
          $display("Error in uu2. Expected: 0xff946c77. Got: 0x%08x\n",
                   tb_uu2_new);
          incorrect = incorrect + 1;
        end

      if (tb_uu3_new != 32'h8d31b7ca)
        begin
          $display("Error in uu3. Expected: 0x8d31b7ca. Got: 0x%08x\n",
                   tb_uu3_new);
          incorrect = incorrect + 1;
        end

      if (!incorrect)
        $display("*** test_rfc8349 successfully completed.\n");
      else
        $display("*** test_rfc8349 completed with %d errors.\n", incorrect);
    end
  endtask // test_rfc8349


  //----------------------------------------------------------------
  // poly1305_final_test
  //----------------------------------------------------------------
  initial
    begin : poly1305_final_test
      $display("*** Poly1305 final simulation started.\n");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

      // test_aa();
      test_rfc8349();

      display_test_result();

      $display("");
      $display("*** Poly1305 final simulation done.\n");
      $finish;
    end // poly1305_final_test
endmodule // tb_tb_poly1305_final

//======================================================================
// EOF tb_tb_poly1305_final.v
//======================================================================
