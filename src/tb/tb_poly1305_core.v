//======================================================================
//
// tb_poly1305_core.v
// ------------------
// Testbench for Poly1305 core.
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

module tb_poly1305_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CLK_HALF_PERIOD = 1;
  localparam CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]   cycle_ctr;
  reg [31 : 0]   error_ctr;
  reg [31 : 0]   tc_ctr;
  reg            tc_correct;

  reg [31 : 0]   read_data;
  reg [127 : 0]  result_data;

  reg            tb_debug;
  reg            tb_pblock;
  reg            tb_final;

  reg            tb_clk;
  reg            tb_reset_n;
  reg            tb_init;
  reg            tb_next;
  reg            tb_finish;
  wire           tb_ready;
  reg [255 : 0]  tb_key;
  reg [127 : 0]  tb_block;
  reg [4: 0]     tb_blocklen;
  wire [127 : 0] tb_mac;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305_core dut(
                    .clk(tb_clk),
                    .reset_n(tb_reset_n),
                    .init(tb_init),
                    .next(tb_next),
                    .finish(tb_finish),
                    .ready(tb_ready),
                    .key(tb_key),
                    .block(tb_block),
                    .blocklen(tb_blocklen),
                    .mac(tb_mac)
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
  always @ (posedge tb_clk)
    begin : sys_monitor
      if (tb_debug)
        begin
          dump_dut_state();
          cycle_ctr = cycle_ctr + 1;
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("====================================================");
      $display("cycle:  0x%016x", cycle_ctr);
      $display("Input and output:");
      $display("-----------------");
      $display("init:  0x%01x, next: 0x%01x, finish: 0x%01x",
               tb_init, tb_next, tb_finish);
      $display("ready: 0x%01x", tb_ready);
      $display("key:   0x%064x", tb_key);
      $display("block: 0x%032x", tb_block);
      $display("mac:   0x%032x", tb_mac);

      $display("");
      $display("Control:");
      $display("--------");
      $display("state_init: 0x%01x, state_update: 0x%01x, mac_update: 0x%01x",
               dut.state_init, dut.state_update, dut.mac_update);
      $display("load_block: 0x%01x, mac_update: 0x%01x",
               dut.load_block, dut.mac_update);
      $display("ctrl_reg: 0x%01x, ctrl_new: 0x%01x, ctrl_we: 0x%01x",
               dut.poly1305_core_ctrl_reg, dut.poly1305_core_ctrl_new,
               dut.poly1305_core_ctrl_we);

      $display("");
      $display("Internal state:");
      $display("---------------");
      $display("r:     0x%08x_%08x_%08x_%08x",
               dut.r_reg[0], dut.r_reg[1], dut.r_reg[2], dut.r_reg[3]);
      $display("h:     0x%08x_%08x_%08x_%08x_%08x",
               dut.h_reg[0], dut.h_reg[1], dut.h_reg[2],
               dut.h_reg[3], dut.h_reg[4]);
      $display("c:     0x%08x_%08x_%08x_%08x_%08x",
               dut.c_reg[0], dut.c_reg[1], dut.c_reg[2],
               dut.c_reg[3], dut.c_reg[4]);
      $display("s:     0x%08x_%08x_%08x_%08x",
               dut.s_reg[0], dut.s_reg[1], dut.s_reg[2], dut.s_reg[3]);


      if (tb_pblock)
        begin
          $display("");
          $display("pblock state:");
          $display("-------------");
          $display("start: 0x%01x, ready: 0x%01x", dut.pblock_inst.start,
                   dut.pblock_inst.ready);
          $display("ctrl: 0x%01x", dut.pblock_inst.pblock_ctrl_reg);
          $display("mulacc_start: 0x%01x  mulacc0_ready: ",
                   dut.pblock_inst.mulacc_start,
                   dut.pblock_inst.mulacc0_ready);
          $display("cycle_ctr: 0x%01x  ctr_rst: 0x%01x  ctr_inc: 0x%01x",
                   dut.pblock_inst.cycle_ctr_reg, dut.pblock_inst.cycle_ctr_rst,
                   dut.pblock_inst.cycle_ctr_inc);
          $display("");

          $display("s0: 0x%016x  s1: 0x%016x  s2: 0x%016x",
                   dut.pblock_inst.s0_reg, dut.pblock_inst.s1_reg,
                   dut.pblock_inst.s2_reg);
          $display("s3: 0x%016x  s4: 0x%016x",
                   dut.pblock_inst.s3_reg, dut.pblock_inst.s4_reg);
          $display("");

          $display("rr0: 0x%08x  rr1: 0x%08x  rr2: 0x%08x  rr3: 0x%08x",
                   dut.pblock_inst.rr0_reg, dut.pblock_inst.rr1_reg,
                   dut.pblock_inst.rr2_reg, dut.pblock_inst.rr3_reg);
          $display("");

          $display("x0:  0x%016x  x1: 0x%016x  x2: 0x%016x",
                   dut.pblock_inst.x0_new, dut.pblock_inst.x1_new,
                   dut.pblock_inst.x2_new);
          $display("x3:  0x%016x  x4: 0x%016x",
                   dut.pblock_inst.x3_new, dut.pblock_inst.x4_reg);
          $display("");

          $display("u0:  0x%016x  u1: 0x%016x u2: 0x%016x",
                   dut.pblock_inst.u0_reg, dut.pblock_inst.u1_reg,
                   dut.pblock_inst.u2_reg);
          $display("u3:  0x%016x  u4: 0x%016x u5: 0x%08x",
                   dut.pblock_inst.u3_reg, dut.pblock_inst.u4_reg,
                   dut.pblock_inst.u5_reg);
          $display("");

          $display("h0: 0x%08x  h1: 0x%08x  h2: 0x%08x  h3: 0x%08x  h4: 0x%08x",
                   dut.pblock_inst.h0_new, dut.pblock_inst.h1_new,
                   dut.pblock_inst.h2_new, dut.pblock_inst.h3_new,
                   dut.pblock_inst.h4_new);
        end


      if (tb_final)
        begin
          $display("");
          $display("final state:");
          $display("------------");
          $display("start: 0x%01x, ready: 0x%01x", dut.final_inst.start,
                   dut.final_inst.ready);
          $display("ctrl: 0x%01x", dut.final_inst.final_ctrl_reg);
          $display("");
          $display("hres0: 0x%08x  hres1: 0x%08x  hres2: 0x%08x  hres3:0x%08x",
                   dut.final_inst.hres0, dut.final_inst.hres1,
                   dut.final_inst.hres2, dut.final_inst.hres3);
          $display("");

          $display("u0:   0x%016x  u1: 0x%016x  u2: 0x%016x",
                   dut.final_inst.u0_reg, dut.final_inst.u1_reg,
                   dut.final_inst.u2_reg);
          $display("u3:   0x%016x  u4: 0x%016x",
                   dut.final_inst.u3_reg, dut.final_inst.u4_reg);
          $display("uu0:  0x%016x  uu1: 0x%016x",
                   dut.final_inst.uu0_reg, dut.final_inst.uu1_reg);
          $display("uu2:  0x%016x  uu3: 0x%016x",
                   dut.final_inst.uu2_reg, dut.final_inst.uu3_reg);
        end

      $display("====================================================");
      $display("\n\n");
    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("TB: Resetting dut.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
      #(2 * CLK_PERIOD);
      $display("TB: Reset done.");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results;
    begin
      $display("");
      if (error_ctr == 0)
        begin
          $display("%02d test completed. All test cases completed successfully.", tc_ctr);
        end
      else
        begin
          $display("%02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr   = 0;
      error_ctr   = 0;
      tc_ctr      = 0;
      tb_clk      = 0;
      tb_debug    = 0;
      tb_pblock   = 0;
      tb_final    = 0;
      tb_reset_n  = 1;
      tb_init     = 0;
      tb_next     = 0;
      tb_finish   = 0;
      tb_key      = 256'h0;
      tb_block    = 128'h0;
      tb_blocklen = 5'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // inc_tc_ctr
  //----------------------------------------------------------------
  task inc_tc_ctr;
    tc_ctr = tc_ctr + 1;
  endtask // inc_tc_ctr


  //----------------------------------------------------------------
  // inc_error_ctr
  //----------------------------------------------------------------
  task inc_error_ctr;
    error_ctr = error_ctr + 1;
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // pause_finish()
  //
  // Pause for a given number of cycles and then finish sim.
  //----------------------------------------------------------------
  task pause_finish(input [31 : 0] num_cycles);
    begin
      $display("Pausing for %04d cycles and then finishing hard.", num_cycles);
      #(num_cycles * CLK_PERIOD);
      $finish;
    end
  endtask // pause_finish


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
  // test_rfc8439;
  //
  // Test case that uses the test vectors from RFC 8439,
  // section 2.5.2:
  // https://tools.ietf.org/html/rfc8439#section-2.5.2
  //----------------------------------------------------------------
  task test_rfc8439;
    begin : test_rfc8439
      $display("*** test_rfc8439 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug = 1;
      #(2 * CLK_PERIOD);

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;

      #(4 * CLK_PERIOD);
      tb_debug = 0;

      $display("*** test_rfc8439 completed.\n");
    end
  endtask // test_rfc8439


  //----------------------------------------------------------------
  // test_p1305_bytes16;
  //
  // Test with 16 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes16;
    begin : test_p1305_bytes16
      $display("*** test_p1305_bytes16 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 1;
      tb_pblock = 1;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes16: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes16: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes16: Loading the 16 byte message and running next().");
      tb_block    = 128'h31323334_35363738_393a3b3c_3d3e3f40;
      tb_blocklen = 5'h10;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes16: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes16: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes16: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes16: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes16: Checking the generated MAC.");
      if (tb_mac == 128'h3b63c42d_c1da46b4_cc0f9f44_8e6e42ec)
        $display("*** test_p1305_bytes16: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes16: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes16: Expected: 0x3b63c42dc1da46b4cc0f9f448e6e42ec");
        $display("*** test_p1305_bytes16: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes16 completed.\n");
    end
  endtask // test_p1305_bytes16


  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("*** Testbench for poly1305_core started ***");
      $display("");

      init_sim();
      reset_dut();

      tb_pblock = 1;

      test_rfc8439();
      test_p1305_bytes16();

      display_test_results();

      $display("*** Testbench for poly1305_core done ***");
      $finish;
    end // main

endmodule // tb_poly1305_core

//======================================================================
// EOF tb_poly1305c_core.v
//======================================================================
