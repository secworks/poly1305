//======================================================================
//
// tb_poly1305_mulacc.v
// --------------------
// Testbench for the Poly1305 multiply-accumulate module.
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
module tb_poly1305_mulacc();

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

  reg [31 : 0]  tb_opa0;
  reg [63 : 0]  tb_opb0;

  reg [31 : 0]  tb_opa1;
  reg [63 : 0]  tb_opb1;

  reg [31 : 0]  tb_opa2;
  reg [63 : 0]  tb_opb2;

  reg [31 : 0]  tb_opa3;
  reg [63 : 0]  tb_opb3;

  reg [31 : 0]  tb_opa4;
  reg [63 : 0]  tb_opb4;

  wire [63 : 0] tb_sum;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305_mulacc dut(
                      .clk(tb_clk),
                      .reset_n(tb_reset_n),

                      .start(tb_start),
                      .ready(tb_ready),

                      .opa0(tb_opa0),
                      .opb0(tb_opb0),

                      .opa1(tb_opa1),
                      .opb1(tb_opb1),

                      .opa2(tb_opa2),
                      .opb2(tb_opb2),

                      .opa3(tb_opa3),
                      .opb3(tb_opb3),

                      .opa4(tb_opa4),
                      .opb4(tb_opb4),

                      .sum(tb_sum)
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
      $display("cycle: %08d", cycle_ctr);
      $display("start: 0x%01x, ready: 0x%01x", tb_start, tb_ready);
      $display("");

      $display("Inputs:");
      $display("opa0: 0x%08x, opb0: 0x%016x", tb_opa0, tb_opb0);
      $display("opa1: 0x%08x, opb1: 0x%016x", tb_opa1, tb_opb1);
      $display("opa2: 0x%08x, opb2: 0x%016x", tb_opa2, tb_opb2);
      $display("opa3: 0x%08x, opb3: 0x%016x", tb_opa3, tb_opb3);
      $display("opa4: 0x%08x, opb4: 0x%016x", tb_opa4, tb_opb4);
      $display("");

      $display("Internal values:");
      $display("mulacc_ctrl_new: 0x%01x, mulacc_ctrl_reg: 0x%01x",
               dut.mulacc_ctrl_new, dut.mulacc_ctrl_reg);
      $display("");
      $display("update_mul: 0x%01x, mulop_select: 0x%01x",
               dut.update_mul, dut.mulop_select);
      $display("mul_opa: 0x%08x, mul_opb: 0x%016x",
               dut.mulacc_logic.mul_opa, dut.mulacc_logic.mul_opb);
      $display("mul_we: 0x%01x, mul_new: 0x%016x, mul_reg: 0x%016x",
               dut.mul_we, dut.mul_new, dut.mul_reg);
      $display("");
      $display("clear_sum: 0x%01x, update_sum: 0x%01x",
               dut.clear_sum, dut.update_sum);
      $display("sum_we: 0x%01x, sum_new: 0x%016x, sum_reg: 0x%016x",
               dut.sum_we, dut.sum_new, dut.sum_reg);
      $display("");

      $display("Outputs:");
      $display("sum: 0x%016x", tb_sum);
      $display("\n");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // inc_tc_ctr()
  //----------------------------------------------------------------
  task inc_tc_ctr;
    begin
      tc_ctr = tc_ctr + 1;
    end
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // inc_error_ctr()
  //----------------------------------------------------------------
  task inc_error_ctr;
    begin
      error_ctr = error_ctr + 1;
    end
  endtask // inc_error_ctr


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

      tb_start   = 1'h0;
      tb_opa0    = 32'h0;
      tb_opb0    = 64'h0;
      tb_opa1    = 32'h0;
      tb_opb1    = 64'h0;
      tb_opa2    = 32'h0;
      tb_opb2    = 64'h0;
      tb_opa3    = 32'h0;
      tb_opb3    = 64'h0;
      tb_opa4    = 32'h0;
      tb_opb4    = 64'h0;
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
  // tc1
  // A very simple testcase that just checks that everything
  // responds and that the control FSM walks the states.
  //----------------------------------------------------------------
  task tc1;
    begin : tc1;
      $display("*** TC1 started.");

      tb_debug = 1;
      inc_tc_ctr();

      tb_opa0    = 32'h0;
      tb_opb0    = 64'h0;
      tb_opa1    = 32'h1;
      tb_opb1    = 64'h1;
      tb_opa2    = 32'h2;
      tb_opb2    = 64'h2;
      tb_opa3    = 32'h4;
      tb_opb3    = 64'h4;
      tb_opa4    = 32'h8;
      tb_opb4    = 64'h8;

      tb_start   = 1'h1;
      #(CLK_PERIOD);
      tb_start   = 1'h0;

      while (!tb_ready)
        #(CLK_PERIOD);


      #(2 * CLK_PERIOD);

      if (tb_sum == 64'h55)
        $display("*** TC1: Correct sum received.\n");
      else
        begin
          $display("*** TC1: Expected sum: 0x55. Received sum: 0x%016x.\n", tb_sum);
          inc_error_ctr();
        end

      #(CLK_PERIOD);
      tb_debug = 0;

      $display("*** TC1 completed.\n");
    end
  endtask // tc1


  //----------------------------------------------------------------
  // tc2_rfc_x0
  // Testcase that uses inputs from the RFC testcase.
  // This corresponds to calculation of x0.
  //----------------------------------------------------------------
  task tc2_rfc_x0;
    begin : tc2_rfc_x0;
      $display("*** TC_rfc_x0 started.");

      tb_debug = 1;
      inc_tc_ctr();

      tb_opa0    = 32'h08bed685;
      tb_opb0    = 64'h00000000344ca153;

      tb_opa1    = 32'h0a088a90;
      tb_opb1    = 64'h00000000cccfb4ea;

      tb_opa2    = 32'h11e6d59b;
      tb_opb2    = 64'h00000000b0337fa7;

      tb_opa3    = 32'h0448aaa9;
      tb_opb3    = 64'h00000000d8adaf23;

      tb_opa4    = 32'h0aee8c25;
      tb_opb4    = 64'h0000000000000002;

      tb_start   = 1'h1;
      #(CLK_PERIOD);
      tb_start   = 1'h0;

      while (!tb_ready)
        #(CLK_PERIOD);


      #(2 * CLK_PERIOD);

      if (tb_sum == 64'h19c2d8f41a0a4b41)
        $display("*** TC2_rfc_x0: Correct sum received.\n");
      else
        begin
          $display("*** TC2_rfc_x0: Expected sum: 0x19c2d8f41a0a4b41. Received sum: 0x%016x.\n", tb_sum);
          inc_error_ctr();
        end

      #(CLK_PERIOD);
      tb_debug = 0;

      $display("*** TC2_rfc_x0 completed.");
    end
  endtask // tc2_rfc_x0


  //----------------------------------------------------------------
  // tc2_rfc_x1
  // Testcase that uses inputs from the RFC testcase.
  // This corresponds to calculation of x1.
  //----------------------------------------------------------------
  task tc2_rfc_x1;
    begin : tc2_rfc_x1;
      $display("*** TC_rfc_x1 started.");

      tb_debug = 1;
      inc_tc_ctr();

      tb_opa0    = 32'h036d5554;
      tb_opb0    = 64'h00000000344ca153;

      tb_opa1    = 32'h08bed685;
      tb_opb1    = 64'h00000000cccfb4ea;

      tb_opa2    = 32'h0a088a90;
      tb_opb2    = 64'h00000000b0337fa7;

      tb_opa3    = 32'h11e6d59b;
      tb_opb3    = 64'h00000000d8adaf23;

      tb_opa4    = 32'h0448aaa9;
      tb_opb4    = 64'h0000000000000002;

      tb_start   = 1'h1;
      #(CLK_PERIOD);
      tb_start   = 1'h0;

      while (!tb_ready)
        #(CLK_PERIOD);


      #(2 * CLK_PERIOD);

      if (tb_sum == 64'h1dc134d2aec16a41)
        $display("*** TC2_rfc_x1: Correct sum received.\n");
      else
        begin
          $display("*** TC2_rfc_x1: Expected sum: 0x1dc134d2aec16a41. Received sum: 0x%016x.\n", tb_sum);
          inc_error_ctr();
        end

      #(CLK_PERIOD);
      tb_debug = 0;

      $display("*** TC2_rfc_x1 completed.");
    end
  endtask // tc2_rfc_x1



  //----------------------------------------------------------------
  // tc2_rfc_x1
  // Testcase that uses inputs from the RFC testcase.
  // This corresponds to calculation of x2.
  //----------------------------------------------------------------
  task tc2_rfc_x2;
    begin : tc2_rfc_x2;
      $display("*** TC_rfc_x2 started.");

      tb_debug = 1;
      inc_tc_ctr();

      tb_opa0    = 32'h0e52447c;
      tb_opb0    = 64'h00000000344ca153;

      tb_opa1    = 32'h036d5554;
      tb_opb1    = 64'h00000000cccfb4ea;

      tb_opa2    = 32'h08bed685;
      tb_opb2    = 64'h00000000b0337fa7;

      tb_opa3    = 32'h0a088a90;
      tb_opb3    = 64'h00000000d8adaf23;

      tb_opa4    = 32'h11e6d59b;
      tb_opb4    = 64'h0000000000000002;

      tb_start   = 1'h1;
      #(CLK_PERIOD);
      tb_start   = 1'h0;

      while (!tb_ready)
        #(CLK_PERIOD);


      #(2 * CLK_PERIOD);

      if (tb_sum == 64'h142de097e1d337a5)
        $display("*** TC2_rfc_x2: Correct sum received.\n");
      else
        begin
          $display("*** TC2_rfc_x2: Expected sum: 0x142de097e1d337a5. Received sum: 0x%016x.\n", tb_sum);
          inc_error_ctr();
        end

      #(CLK_PERIOD);
      tb_debug = 0;

      $display("*** TC2_rfc_x2 completed.");
    end
  endtask // tc2_rfc_x2


  //----------------------------------------------------------------
  // tc2_rfc_x1
  // Testcase that uses inputs from the RFC testcase.
  // This corresponds to calculation of x3.
  //----------------------------------------------------------------
  task tc2_rfc_x3;
    begin : tc2_rfc_x3;
      $display("*** TC_rfc_x3 started.");

      tb_debug = 1;
      inc_tc_ctr();

      tb_opa0    = 32'h0806d540;
      tb_opb0    = 64'h00000000344ca153;

      tb_opa1    = 32'h0e52447c;
      tb_opb1    = 64'h00000000cccfb4ea;

      tb_opa2    = 32'h036d5554;
      tb_opb2    = 64'h00000000b0337fa7;

      tb_opa3    = 32'h08bed685;
      tb_opb3    = 64'h00000000d8adaf23;

      tb_opa4    = 32'h0a088a90;
      tb_opb4    = 64'h0000000000000002;

      tb_start   = 1'h1;
      #(CLK_PERIOD);
      tb_start   = 1'h0;

      while (!tb_ready)
        #(CLK_PERIOD);


      #(2 * CLK_PERIOD);

      if (tb_sum == 64'h16dbc6b87903d733)
        $display("*** TC2_rfc_x3: Correct sum received.\n");
      else
        begin
          $display("*** TC2_rfc_x3: Expected sum: 0x16dbc6b87903d733. Received sum: 0x%016x.\n", tb_sum);
          inc_error_ctr();
        end

      #(CLK_PERIOD);
      tb_debug = 0;

      $display("*** TC2_rfc_x3 completed.");
    end
  endtask // tc2_rfc_x3


  //----------------------------------------------------------------
  // poly1305_mulacc_test
  //----------------------------------------------------------------
  initial
    begin : poly1305_mulacc_test
      $display("*** Poly1305 mulacc simulation started.\n");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

      tc1();
      tc2_rfc_x0();
      tc2_rfc_x1();
      tc2_rfc_x2();
      tc2_rfc_x3();

      display_test_result();

      $display("");
      $display("*** Poly1305 mulacc simulation completed.\n");
      $finish;
    end // poly1305_mulacc_test
endmodule // tb_poly1305_mulacc

//======================================================================
// EOF tb_poly1305_mulacc.v
//======================================================================
