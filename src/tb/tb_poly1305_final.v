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

`default_nettype none

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

  reg           tb_start;
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

  wire [31 : 0] tb_hres0;
  wire [31 : 0] tb_hres1;
  wire [31 : 0] tb_hres2;
  wire [31 : 0] tb_hres3;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305_final dut(
                     .clk(tb_clk),
                     .reset_n(tb_reset_n),

                     .start(tb_start),
                     .ready(tb_ready),

                     .h0(tb_h0),
                     .h1(tb_h1),
                     .h2(tb_h2),
                     .h3(tb_h3),
                     .h4(tb_h4),

                     .s0(tb_s0),
                     .s1(tb_s1),
                     .s2(tb_s2),
                     .s3(tb_s3),

                     .hres0(tb_hres0),
                     .hres1(tb_hres1),
                     .hres2(tb_hres2),
                     .hres3(tb_hres3)
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
      $display("=====================================================");
      $display("cycle %08d", cycle_ctr);
      $display("State of DUT");
      $display("------------");
      $display("Inputs and outputs:");
      $display("start: 0x%01x, ready: 0x%01x", dut.start, dut.ready);
      $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
               dut.h0, dut.h1, dut.h2, dut.h3, dut.h4);
      $display("s0: 0x%08x  s1: 0x%08x  s2: 0x%08x  s3: 0x%08x",
               dut.s0, dut.s1, dut.s2, dut.s3);
      $display("hres0: 0x%08x  hres1: 0x%08x  hres2: 0x%08x  hres3:0x%08x",
               dut.hres0, dut.hres1, dut.hres2, dut.hres3);
      $display("");

      $display("Control:");
      $display("cycle_ctr: 0x%01x", dut.cycle_ctr_reg);
      $display("ctrl:      0x%01x", dut.final_ctrl_reg);
      $display("");
      $display("Internal values:");
      $display("u0:   0x%016x  u1: 0x%016x  u2: 0x%016x",
               dut.u0_reg, dut.u1_reg, dut.u2_reg);
      $display("u3:   0x%016x  u4: 0x%016x",
               dut.u3_reg, dut.u4_reg);
      $display("uu0:  0x%016x  uu1: 0x%016x", dut.uu0_reg, dut.uu1_reg);
      $display("uu2:  0x%016x  uu3: 0x%016x", dut.uu2_reg, dut.uu3_reg);

      $display("=====================================================");
      $display("\n");
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
  // wait_ready()
  //
  // Wait for the ready flag to be set in dut.
  //----------------------------------------------------------------
  task wait_ready;
    begin : wready
      while (!tb_ready)
        #(CLK_PERIOD);
    end
  endtask // wait_ready


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

      tb_start   = 0;

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

      tc_ctr = tc_ctr + 1;
      incorrect = 0;

      tb_h0 = 32'h369d03a7;
      tb_h1 = 32'hc8844335;
      tb_h2 = 32'hff946c77;
      tb_h3 = 32'h8d31b7ca;
      tb_h4 = 32'h00000002;

      tb_s0 = 32'h8a800301;
      tb_s1 = 32'hfdb20dfb;
      tb_s2 = 32'haff6bf4a;
      tb_s3 = 32'h1bf54941;

      tb_debug = 1;
      tb_start = 1;
      #(1 * CLK_PERIOD);
      tb_start = 0;
      wait_ready();
      $display("DUT should be done.");

      #(2 * CLK_PERIOD);
      tb_debug = 0;

      if (tb_hres0 != 32'hc11d06a8)
        begin
          $display("Error in hres0. Expected: 0xc11d06a8. Got: 0x%08x\n",
                   tb_hres0);
          incorrect = incorrect + 1;
        end

      if (tb_hres1 != 32'hc6365130)
        begin
          $display("Error in hres1. Expected: 0xc6365130. Got: 0x%08x\n",
                   tb_hres1);
          incorrect = incorrect + 1;
        end

      if (tb_hres2 != 32'haf8b2bc2)
        begin
          $display("Error in hres2. Expected: 0xaf8b2bc2. Got: 0x%08x\n",
                   tb_hres2);
          incorrect = incorrect + 1;
        end

      if (tb_hres3 != 32'ha927010c)
        begin
          $display("Error in hres3. Expected: 0xa927010c. Got: 0x%08x\n",
                   tb_hres3);
          incorrect = incorrect + 1;
        end

      if (!incorrect)
        $display("*** test_rfc8349 successfully completed.\n");
      else
        $display("*** test_rfc8349 completed with %d errors.\n", incorrect);
    end
  endtask // test_rfc8349


  //----------------------------------------------------------------
  // test_bytes16;
  //
  // Test case for bytes16.
  //----------------------------------------------------------------
  task test_bytes16;
    begin : test_bytes16
      $display("*** test_bytes16 started.\n");

      tc_ctr = tc_ctr + 1;
      incorrect = 0;

      tb_h0 = 32'ha344603a;
      tb_h1 = 32'hb694ccc5;
      tb_h2 = 32'h94a85081;
      tb_h3 = 32'hd04d254c;
      tb_h4 = 32'h00000003;

      tb_s0 = 32'h8a800301;
      tb_s1 = 32'hfdb20dfb;
      tb_s2 = 32'haff6bf4a;
      tb_s3 = 32'h1bf54941;

      tb_debug = 1;
      #(2 * CLK_PERIOD);

      tb_start = 1;
      #(1 * CLK_PERIOD);
      tb_start = 0;
      wait_ready();
      $display("DUT should be done.");

      #(2 * CLK_PERIOD);
      tb_debug = 0;

      if (tb_hres0 != 32'h2dc4633b)
        begin
          $display("Error in hres0. Expected: 0x2dc4633b. Got: 0x%08x\n",
                   tb_hres0);
          incorrect = incorrect + 1;
        end

      if (tb_hres1 != 32'hb446dac1)
        begin
          $display("Error in hres1. Expected: 0xb446dac1. Got: 0x%08x\n",
                   tb_hres1);
          incorrect = incorrect + 1;
        end

      if (tb_hres2 != 32'h449f0fcc)
        begin
          $display("Error in hres2. Expected: 0x449f0fcc. Got: 0x%08x\n",
                   tb_hres2);
          incorrect = incorrect + 1;
        end

      if (tb_hres3 != 32'hec426e8e)
        begin
          $display("Error in hres3. Expected: 0xec426e8e. Got: 0x%08x\n",
                   tb_hres3);
          incorrect = incorrect + 1;
        end

      if (!incorrect)
        $display("*** test_bytes16 successfully completed.\n");
      else
        $display("*** test_bytes16 completed with %d errors.\n", incorrect);
    end
  endtask // test_bytes16


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
      test_bytes16();

      display_test_result();

      $display("");
      $display("*** Poly1305 final simulation done.\n");
      $finish;
    end // poly1305_final_test
endmodule // tb_tb_poly1305_final

//======================================================================
// EOF tb_tb_poly1305_final.v
//======================================================================
