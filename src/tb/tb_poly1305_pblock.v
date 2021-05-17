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

`default_nettype none

//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_poly1305_pblock();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;
  parameter DUMP_WAIT = 0;
  parameter TIMEOUT   = 100;

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

                      .start(tb_start),
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
      #(CLK_PERIOD);

      cycle_ctr = cycle_ctr + 1;
      if (cycle_ctr ==  TIMEOUT)
        begin
          $display("*** Error: Timeout at cycle %08d reached! ***", TIMEOUT);
          $finish;
        end

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
      $display("State of DUT at cycle %08d", cycle_ctr);
      $display("------------------------------");
      $display("Inputs:");
      $display("start: 0x%01x  ready: 0x%01x", dut.start, dut.ready);
      $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
               dut.h0, dut.h1, dut.h2, dut.h3, dut.h4);
      $display("c0: 0x%08x  c1: 0x%08x  c2: 0x%08x  c3: 0x%08x  c4: 0x%08x",
               dut.c0, dut.c1, dut.c2, dut.c3, dut.c4);
      $display("r0: 0x%08x  r1: 0x%08x  r2: 0x%08x  r3: 0x%08x",
               dut.r0, dut.r1, dut.r2, dut.r3);
      $display("");

      $display("Internal values:");
      $display("ctrl: 0x%01x", dut.pblock_ctrl_reg);
      $display("mulacc_start: 0x%01x  mulacc0_ready: ",
               dut.mulacc_start, dut.mulacc0_ready);
      $display("cycle_ctr: 0x%01x  ctr_rst: 0x%01x  ctr_inc: 0x%01x",
               dut.cycle_ctr_reg, dut.cycle_ctr_rst, dut.cycle_ctr_inc);
      $display("");

      $display("s0: 0x%016x  s1: 0x%016x  s2: 0x%016x",
               dut.s0_reg, dut.s1_reg, dut.s2_reg);
      $display("s3: 0x%016x  s4: 0x%016x",
               dut.s3_reg, dut.s4_reg);
      $display("");

      $display("rr0: 0x%08x  rr1: 0x%08x  rr2: 0x%08x  rr3: 0x%08x",
               dut.rr0_reg, dut.rr1_reg,
               dut.rr2_reg, dut.rr3_reg);
      $display("");

      $display("x0:  0x%016x  x1: 0x%016x  x2: 0x%016x",
               dut.x0_new, dut.x1_new, dut.x2_new);
      $display("x3:  0x%016x  x4: 0x%016x",
               dut.x3_new, dut.x4_reg);
      $display("");

      $display("u0:  0x%016x  u1: 0x%016x u2: 0x%016x",
               dut.u0_reg, dut.u1_reg, dut.u2_reg);
      $display("u3:  0x%016x  u4: 0x%016x u5: 0x%08x",
               dut.u3_reg, dut.u4_reg, dut.u5_reg);
      $display("");


      $display("Outputs:");
      $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
               dut.h0_new, dut.h1_new, dut.h2_new, dut.h3_new, dut.h4_new);
      $display("");
    end
  endtask // dump_dut_state


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

      tb_c0      = 32'h0;
      tb_c1      = 32'h0;
      tb_c2      = 32'h0;
      tb_c3      = 32'h0;
      tb_c4      = 32'h0;

      tb_r0      = 32'h0;
      tb_r1      = 32'h0;
      tb_r2      = 32'h0;
      tb_r3      = 32'h0;
    end
  endtask // init_sim


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
      #(2 * CLK_PERIOD);

      tb_start = 1;
      #(1 * CLK_PERIOD);
      tb_start = 0;
      wait_ready();

      #(2 * CLK_PERIOD);
      tb_debug = 0;

      if (tb_h0_new != 32'h369d03a7)
        begin
          $display("Error in h0. Expected: 0x369d03a7. Got: 0x%08x\n", tb_h0_new);
          incorrect = incorrect + 1;
        end

      if (tb_h1_new != 32'hc8844335)
        begin
          $display("Error in h1. Expected: 0xc8844335. Got: 0x%08x\n", tb_h1_new);
          incorrect = incorrect + 1;
        end

      if (tb_h2_new != 32'hff946c77)
        begin
          $display("Error in h2. Expected: 0xff946c77. Got: 0x%08x\n", tb_h2_new);
          incorrect = incorrect + 1;
        end

      if (tb_h3_new != 32'h8d31b7ca)
        begin
          $display("Error in h3. Expected: 0x8d31b7ca. Got: 0x%08x\n", tb_h3_new);
          incorrect = incorrect + 1;
        end

      if (tb_h4_new != 32'h00000002)
        begin
          $display("Error in h4. Expected: 0x00000002. Got: 0x%08x\n", tb_h4_new);
          incorrect = incorrect + 1;
        end

      tb_debug = 0;

      if (!incorrect)
        $display("*** test_rfc8349 successfully completed.\n");
      else
        $display("*** test_rfc8349 completed with %d errors.\n", incorrect);
    end
  endtask // test_rfc8349


  //----------------------------------------------------------------
  // test_p1305_bytes16;
  //
  // Test case that uses the block input from test_p1305_bytes16.
  // section 2.5.2:
  // https://tools.ietf.org/html/rfc8439#section-2.5.2
  //----------------------------------------------------------------
  task test_p1305_bytes16;
    begin : test_p1305_bytes16
      $display("*** test_p1305_bytes16 started.\n");

      tc_ctr = tc_ctr + 1;
      incorrect = 0;

      tb_h0 = 32'h00000000;
      tb_h1 = 32'h00000000;
      tb_h2 = 32'h00000000;
      tb_h3 = 32'h00000000;
      tb_h4 = 32'h00000000;

      tb_c0 = 32'h34333231;
      tb_c1 = 32'h38373635;
      tb_c2 = 32'h3c3b3a39;
      tb_c3 = 32'h403f3e3d;
      tb_c4 = 32'h00000001;

      tb_r0 = 32'h08bed685;
      tb_r1 = 32'h036d5554;
      tb_r2 = 32'h0e52447c;
      tb_r3 = 32'h0806d540;

      tb_debug = 1;
      #(2 * CLK_PERIOD);

      tb_start = 1;
      #(1 * CLK_PERIOD);
      tb_start = 0;
      wait_ready();

      #(2 * CLK_PERIOD);
      tb_debug = 0;

      $display("*** test_p1305_bytes16: DUT should be done.");
      #(2 * CLK_PERIOD);

      if (tb_h0_new != 32'ha344603a)
        begin
          $display("Error in h0. Expected: 0xa344603a. Got: 0x%08x\n", tb_h0_new);
          incorrect = incorrect + 1;
        end

      if (tb_h1_new != 32'hb694ccc5)
        begin
          $display("Error in h1. Expected: 0xb694ccc5. Got: 0x%08x\n", tb_h1_new);
          incorrect = incorrect + 1;
        end

      if (tb_h2_new != 32'h94a85081)
        begin
          $display("Error in h2. Expected: 0x94a85081. Got: 0x%08x\n", tb_h2_new);
          incorrect = incorrect + 1;
        end

      if (tb_h3_new != 32'hd04d254c)
        begin
          $display("Error in h3. Expected: 0xd04d254c. Got: 0x%08x\n", tb_h3_new);
          incorrect = incorrect + 1;
        end

      if (tb_h4_new != 32'h00000003)
        begin
          $display("Error in h4. Expected: 0x00000003. Got: 0x%08x\n", tb_h4_new);
          incorrect = incorrect + 1;
        end

      tb_debug = 0;

      if (!incorrect)
        $display("*** test_p1305_bytes16 successfully completed.\n");
      else
        $display("*** test_p1305_bytes16 completed with %d errors.\n", incorrect);
    end
  endtask // test_p1305_bytes16


  //----------------------------------------------------------------
  // test_long_block;
  //
  // Test case that uses the inputs to the final block in
  // testcase_long (in core) to debug u4.
  //----------------------------------------------------------------
  task test_long_block;
    begin : test_long_block
      $display("*** test_long_block started.\n");

      tc_ctr = tc_ctr + 1;
      incorrect = 0;

      tb_r0 = 32'h000000f3;
      tb_r1 = 32'h00000000;
      tb_r2 = 32'h00000000;
      tb_r3 = 32'h0f000000;

      tb_h0 = 32'h938f36f3;
      tb_h1 = 32'h9ca98eca;
      tb_h2 = 32'h0743b558;
      tb_h3 = 32'hb0851037;
      tb_h4 = 32'h00000002;

      tb_c0 = 32'hffffffff;
      tb_c1 = 32'hffffffff;
      tb_c2 = 32'hffffffff;
      tb_c3 = 32'hffffffff;
      tb_c4 = 32'h00000001;

      tb_debug = 1;
      #(2 * CLK_PERIOD);

      tb_start = 1;
      #(1 * CLK_PERIOD);
      tb_start = 0;
      wait_ready();

      #(2 * CLK_PERIOD);
      tb_debug = 0;

      $display("*** test_long_block: DUT should be done.");
      #(2 * CLK_PERIOD);

      if (tb_h0_new != 32'h673fea88)
        begin
          $display("Error in h0. Expected: 0x673fea88. Got: 0x%08x\n", tb_h0_new);
          incorrect = incorrect + 1;
        end

      if (tb_h1_new != 32'hf26bf57f)
        begin
          $display("Error in h1. Expected: 0xf26bf57f. Got: 0x%08x\n", tb_h1_new);
          incorrect = incorrect + 1;
        end

      if (tb_h2_new != 32'hed0d58a4)
        begin
          $display("Error in h2. Expected: 0xed0d58a4. Got: 0x%08x\n", tb_h2_new);
          incorrect = incorrect + 1;
        end

      if (tb_h3_new != 32'h143c232b)
        begin
          $display("Error in h3. Expected: 0x143c232b. Got: 0x%08x\n", tb_h3_new);
          incorrect = incorrect + 1;
        end

      if (tb_h4_new != 32'h00000004)
        begin
          $display("Error in h4. Expected: 0x00000004. Got: 0x%08x\n", tb_h4_new);
          incorrect = incorrect + 1;
        end

      tb_debug = 0;

      if (!incorrect)
        $display("*** test_long_block successfully completed.\n");
      else
        $display("*** test_long_block completed with %d errors.\n", incorrect);
    end
  endtask // test_long_block


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
      // test_rfc8349();
      // test_p1305_bytes16();
      test_long_block();

      display_test_result();

      $display("");
      $display("*** Poly1305 pblock simulation done.\n");
      $finish;
    end // poly1305_pblock_test
endmodule // tb_tb_poly1305_pblock

//======================================================================
// EOF tb_tb_poly1305_pblock.v
//======================================================================
