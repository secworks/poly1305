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

`default_nettype none

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

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_rfc8439: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_rfc8439: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_rfc8439: Loading the first 16 bytes of message and running next().");
      tb_block    = 128'h43727970_746f6772_61706869_6320466f;
      tb_blocklen = 5'h10;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_rfc8439: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_rfc8439: Loading the second 16 bytes and running next().");
      tb_block    = 128'h72756d20_52657365_61726368_2047726f;
      tb_blocklen = 5'h10;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_rfc8439: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_rfc8439: Loading the final 2 bytes and running next().");
      tb_block    = 128'h75700000_00000000_00000000_00000000;
      tb_blocklen = 5'h02;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_rfc8439: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;


      $display("*** test_rfc8439: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_rfc8439: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_rfc8439: Checking the generated MAC.");
      if (tb_mac == 128'ha8061dc1_305136c6_c22b8baf_0c0127a9)
        $display("*** test_rfc8439: Correct MAC generated.");
      else begin
        $display("*** test_rfc8439: Error. Incorrect MAC generated.");
        $display("*** test_rfc8439: Expected: 0xa8061dc1_305136c6_c22b8baf_0c0127a9");
        $display("*** test_rfc8439: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_rfc8439 completed.\n");
    end
  endtask // test_rfc8439


  //----------------------------------------------------------------
  // test_p1305_bytes0;
  //
  // Test with 0 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes0;
    begin : test_p1305_bytes0
      $display("*** test_p1305_bytes0 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes0: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes0: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes0: Loading the 0 byte message and running next().");
      tb_block    = 128'h00000000_00000000_00000000_00000000;
      tb_blocklen = 5'h00;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes0: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes0: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes0: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes0: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes0: Checking the generated MAC.");
      if (tb_mac == 128'h0103808afb0db2fd4abff6af4149f51b)
        $display("*** test_p1305_bytes0: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes0: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes0: Expected: 0x0103808afb0db2fd4abff6af4149f51b");
        $display("*** test_p1305_bytes0: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes0 completed.\n");
    end
  endtask // test_p1305_bytes0


  //----------------------------------------------------------------
  // test_p1305_bytes1;
  //
  // Test with 1 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes1;
    begin : test_p1305_bytes1
      $display("*** test_p1305_bytes1 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes1: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes1: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes1: Loading the 1 byte message and running next().");
      tb_block    = 128'h31000000_00000000_00000000_00000000;
      tb_blocklen = 5'h01;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes1: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes1: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes1: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes1: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes1: Checking the generated MAC.");
      if (tb_mac == 128'h8097ddf5_19b7f412_0b57fabf_925a19ac)
        $display("*** test_p1305_bytes1: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes1: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes1: Expected: 0x8097ddf5_19b7f412_0b57fabf_925a19ac");
        $display("*** test_p1305_bytes1: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes1 completed.\n");
    end
  endtask // test_p1305_bytes1


  //----------------------------------------------------------------
  // test_p1305_bytes2;
  //
  // Test with 6 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes2;
    begin : test_p1305_bytes2
      $display("*** test_p1305_bytes2 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes2: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes2: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes2: Loading the 2 byte message and running next().");
      tb_block    = 128'h31320000_00000000_00000000_00000000;
      tb_blocklen = 5'h02;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes2: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes2: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes2: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes2: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes2: Checking the generated MAC.");
      if (tb_mac == 128'h74187253_85d59d55_201792c3_a2ab2ad0)
        $display("*** test_p1305_bytes2: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes2: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes2: Expected: 0x74187253_85d59d55_201792c3_a2ab2ad0");
        $display("*** test_p1305_bytes2: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes2 completed.\n");
    end
  endtask // test_p1305_bytes2


  //----------------------------------------------------------------
  // test_p1305_bytes6;
  //
  // Test with 6 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes6;
    begin : test_p1305_bytes6
      $display("*** test_p1305_bytes6 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes6: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes6: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes6: Loading the 6 byte message and running next().");
      tb_block    = 128'h31323334_35360000_00000000_00000000;
      tb_blocklen = 5'h06;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes6: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes6: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes6: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes6: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes6: Checking the generated MAC.");
      if (tb_mac == 128'hc4ef06ab_0fd215f9_cc64736f_70878c0f)
        $display("*** test_p1305_bytes6: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes6: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes6: Expected: 0xc4ef06ab_0fd215f9_cc64736f_70878c0f");
        $display("*** test_p1305_bytes6: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes6 completed.\n");
    end
  endtask // test_p1305_bytes6


  //----------------------------------------------------------------
  // test_p1305_bytes9;
  //
  // Test with 9 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes9;
    begin : test_p1305_bytes9
      $display("*** test_p1305_bytes9 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes9: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes9: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes9: Loading the 9 byte message and running next().");
      tb_block    = 128'h31323334_35363738_39000000_00000000;
      tb_blocklen = 5'h09;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes9: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes9: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes9: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes9: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes9: Checking the generated MAC.");
      if (tb_mac == 128'hba5f904c_5238c997_a4446b82_e97e22d3)
        $display("*** test_p1305_bytes9: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes9: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes9: Expected: 0xba5f904c_5238c997_a4446b82_e97e22d3");
        $display("*** test_p1305_bytes9: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes9 completed.\n");
    end
  endtask // test_p1305_bytes9


  //----------------------------------------------------------------
  // test_p1305_bytes12;
  //
  // Test with 12 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes12;
    begin : test_p1305_bytes12
      $display("*** test_p1305_bytes12 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes12: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes12: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes12: Loading the 12 byte message and running next().");
      tb_block    = 128'h31323334_35363738_393a3b3c_00000000;
      tb_blocklen = 5'h0c;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes12: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes12: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes12: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes12: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes12: Checking the generated MAC.");
      if (tb_mac == 128'h14932346_2d5cf043_e2be3aa9_a3c94b90)
        $display("*** test_p1305_bytes12: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes12: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes12: Expected: 0x14932346_2d5cf043_e2be3aa9_a3c94b90");
        $display("*** test_p1305_bytes12: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes12 completed.\n");
    end
  endtask // test_p1305_bytes12


  //----------------------------------------------------------------
  // test_p1305_bytes15;
  //
  // Test with 15 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes15;
    begin : test_p1305_bytes15
      $display("*** test_p1305_bytes15 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 0;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes15: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes15: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes15: Loading the 16 byte message and running next().");
      tb_block    = 128'h31323334_35363738_393a3b3c_3d3e3f00;
      tb_blocklen = 5'h0f;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes15: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes15: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes15: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes15: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes15: Checking the generated MAC.");
      if (tb_mac == 128'h9c222589_184ef089_a06b50be_e4c9c124)
        $display("*** test_p1305_bytes15: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes15: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes15: Expected: 0x9c222589_184ef089_a06b50be_e4c9c124");
        $display("*** test_p1305_bytes15: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes15 completed.\n");
    end
  endtask // test_p1305_bytes15


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

      tb_debug  = 0;
      tb_pblock = 0;
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
  // test_p1305_bytes32;
  //
  // Test with 16 byte message. Key is from the RFC.
  //----------------------------------------------------------------
  task test_p1305_bytes32;
    begin : test_p1305_bytes32
      $display("*** test_p1305_bytes32 started.\n");
      inc_tc_ctr();

      tb_key   = 256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b;
      tb_block = 128'h0;

      tb_debug  = 0;
      tb_pblock = 1;
      #(2 * CLK_PERIOD);

      $display("*** test_p1305_bytes32: Running init() with the RFC key.");
      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();
      $display("*** test_p1305_bytes32: init() should be completed.");
      #(CLK_PERIOD);

      $display("*** test_p1305_bytes32: Loading the first 16 bytes and running next().");
      tb_block    = 128'h31323334_35363738_393a3b3c_3d3e3f40;
      tb_blocklen = 5'h10;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes32: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes32: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes32: Loading the final 16 bytes and running next().");
      tb_block    = 128'h41424344_45464748_494a4b4c_4d4e4f50;
      tb_blocklen = 5'h10;
      tb_pblock   = 1;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();
      $display("*** test_p1305_bytes32: next() should be completed.");
      #(CLK_PERIOD);
      $display("*** test_p1305_bytes32: Dumping state after next().");
      dump_dut_state();
      #(CLK_PERIOD);
      tb_pblock = 0;

      $display("*** test_p1305_bytes32: running finish() to get the MAC.");
      tb_final  = 1;
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();
      $display("*** test_p1305_bytes32: finish() should be completed.");
      #(CLK_PERIOD);
      tb_final = 0;
      tb_debug = 0;

      $display("*** test_p1305_bytes32: Checking the generated MAC.");
      if (tb_mac == 128'hd76301a8_d0b1ef2b_60ca65f7_c565189d)
        $display("*** test_p1305_bytes32: Correct MAC generated.");
      else begin
        $display("*** test_p1305_bytes32: Error. Incorrect MAC generated.");
        $display("*** test_p1305_bytes32: Expected: 0xd76301a8_d0b1ef2b_60ca65f7_c565189d");
        $display("*** test_p1305_bytes32: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** test_p1305_bytes32 completed.\n");
    end
  endtask // test_p1305_bytes32


  //----------------------------------------------------------------
  // testcase_0;
  //
  // Monocypher testcase 0. An all zero zero length testcase.
  //----------------------------------------------------------------
  task testcase_0;
    begin : testcase_0
      $display("*** testcase_0 started.");
      inc_tc_ctr();

      tb_key   = 256'h0;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'h00000000_00000000_00000000_00000000;
      tb_blocklen = 5'h00;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_0: Checking the generated MAC.");
      if (tb_mac == 128'h0)
        $display("*** testcase_0: Correct MAC generated.");
      else begin
        $display("*** testcase_0: Error. Incorrect MAC generated.");
        $display("*** testcase_0: Expected: 0x00000000_00000000_00000000_00000000");
        $display("*** testcase_0: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_0 completed.\n");
    end
  endtask // testcase_0


  //----------------------------------------------------------------
  // testcase_1;
  //
  // Monocypher testcase 1. A zero length message with upper
  // part of key non zero.
  //----------------------------------------------------------------
  task testcase_1;
    begin : testcase_1
      $display("*** testcase_1 started.");
      inc_tc_ctr();

      tb_key   = 256'h36e5f6b5_c5e06070_f0efca96_227a863e_00000000_00000000_00000000_00000000;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'h00000000_00000000_00000000_00000000;
      tb_blocklen = 5'h00;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_1: Checking the generated MAC.");
      if (tb_mac == 128'h0)
        $display("*** testcase_1: Correct MAC generated.");
      else begin
        $display("*** testcase_1: Error. Incorrect MAC generated.");
        $display("*** testcase_1: Expected: 0x00000000_00000000_00000000_00000000");
        $display("*** testcase_1: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_1 completed.\n");
    end
  endtask // testcase_1


  //----------------------------------------------------------------
  // testcase_2;
  //
  // Monocypher testcase 2. A zero length message with lower
  // part of key non zero.
  //----------------------------------------------------------------
  task testcase_2;
    begin : testcase_2
      $display("*** testcase_2 started.");
      inc_tc_ctr();

      tb_key   = 256'h00000000_00000000_00000000_00000000_36e5f6b5_c5e06070_f0efca96_227a863e;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'h00000000_00000000_00000000_00000000;
      tb_blocklen = 5'h00;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_2: Checking the generated MAC.");
      if (tb_mac == 128'h36e5f6b5_c5e06070_f0efca96_227a863e)
        $display("*** testcase_2: Correct MAC generated.");
      else begin
        $display("*** testcase_2: Error. Incorrect MAC generated.");
        $display("*** testcase_2: Expected: 0x36e5f6b5_c5e06070_f0efca96_227a863e");
        $display("*** testcase_2: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_2 completed.\n");
    end
  endtask // testcase_2


  //----------------------------------------------------------------
  // testcase_8;
  //
  // Monocypher testcase 8. A full single block message that
  // test overflow in final caclulations.
  //----------------------------------------------------------------
  task testcase_8;
    begin : testcase_8
      $display("*** testcase_8 started.");
      inc_tc_ctr();

      tb_key   = 256'h02000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'hffffffff_ffffffff_ffffffff_ffffffff;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_8: Checking the generated MAC.");
      if (tb_mac == 128'h03000000_00000000_00000000_00000000)
        $display("*** testcase_8: Correct MAC generated.");
      else begin
        $display("*** testcase_8: Error. Incorrect MAC generated.");
        $display("*** testcase_8: Expected: 0x03000000_00000000_00000000_00000000");
        $display("*** testcase_8: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_8 completed.\n");
    end
  endtask // testcase_8


  //----------------------------------------------------------------
  // testcase_9;
  //
  // Monocypher testcase 9. A full single block message that
  // test overflow in caclulations in pblock.
  //----------------------------------------------------------------
  task testcase_9;
    begin : testcase_9
      $display("*** testcase_9 started.");
      inc_tc_ctr();

      tb_key   = 256'h02000000_00000000_00000000_00000000_ffffffff_ffffffff_ffffffff_ffffffff;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'h02000000_00000000_00000000_00000000;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_9: Checking the generated MAC.");
      if (tb_mac == 128'h03000000_00000000_00000000_00000000)
        $display("*** testcase_9: Correct MAC generated.");
      else begin
        $display("*** testcase_9: Error. Incorrect MAC generated.");
        $display("*** testcase_9: Expected: 0x03000000_00000000_00000000_00000000");
        $display("*** testcase_9: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_9 completed.\n");
    end
  endtask // testcase_9


  //----------------------------------------------------------------
  // testcase_10;
  //
  // Monocypher testcase 10. Three full blocks that trigger lots
  // of carry handling in calculations.
  //----------------------------------------------------------------
  task testcase_10;
    begin : testcase_10
      $display("*** testcase_10 started.");
      inc_tc_ctr();

      tb_key   = 256'h01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'hffffffff_ffffffff_ffffffff_ffffffff;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_block    = 128'hf0ffffff_ffffffff_ffffffff_ffffffff;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_block    = 128'h11000000_00000000_00000000_00000000;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_10: Checking the generated MAC.");
      if (tb_mac == 128'h05000000_00000000_00000000_00000000)
        $display("*** testcase_10: Correct MAC generated.");
      else begin
        $display("*** testcase_10: Error. Incorrect MAC generated.");
        $display("*** testcase_10: Expected: 0x03000000_00000000_00000000_00000000");
        $display("*** testcase_10: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_10 completed.\n");
    end
  endtask // testcase_10


  //----------------------------------------------------------------
  // testcase_11;
  //
  // Monocypher testcase 11. Three full blocks that trigger lots
  // of carry handling in calculations.
  //----------------------------------------------------------------
  task testcase_11;
    begin : testcase_11
      $display("*** testcase_11 started.");
      inc_tc_ctr();

      tb_key   = 256'h01000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'hffffffff_ffffffff_ffffffff_ffffffff;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_block    = 128'hfbfefefe_fefefefe_fefefefe_fefefefe;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_block    = 128'h01010101_01010101_01010101_01010101;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_11: Checking the generated MAC.");
      if (tb_mac == 128'h00000000_00000000_00000000_00000000)
        $display("*** testcase_11: Correct MAC generated.");
      else begin
        $display("*** testcase_11: Error. Incorrect MAC generated.");
        $display("*** testcase_11: Expected: 0x03000000_00000000_00000000_00000000");
        $display("*** testcase_11: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_11 completed.\n");
    end
  endtask // testcase_11


  //----------------------------------------------------------------
  // testcase_12;
  //
  // Monocypher testcase 12. A single block that triggers
  // corner cases in calculations.
  //----------------------------------------------------------------
  task testcase_12;
    begin : testcase_12
      $display("*** testcase_12 started.");
      inc_tc_ctr();

      tb_key   = 256'h02000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      tb_block    = 128'hfdffffff_ffffffff_ffffffff_ffffffff;
      tb_blocklen = 5'h10;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_12: Checking the generated MAC.");
      if (tb_mac == 128'hfaffffff_ffffffff_ffffffff_ffffffff)
        $display("*** testcase_12: Correct MAC generated.");
      else begin
        $display("*** testcase_12: Error. Incorrect MAC generated.");
        $display("*** testcase_12: Expected: 0xfaffffff_ffffffff_ffffffff_ffffffff");
        $display("*** testcase_12: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      $display("*** testcase_12 completed.\n");
    end
  endtask // testcase_12


  //----------------------------------------------------------------
  // testcase_long;
  //
  // A testcase with a 1025 byte long message.
  //----------------------------------------------------------------
  task testcase_long;
    begin : testcase_long
      integer i;

      tb_debug  = 0;
      tb_pblock = 0;
      tb_final  = 0;

      $display("*** testcase_long started.");
      inc_tc_ctr();

      tb_key   = 256'hf3000000_00000000_00000000_0000003f_3f000000_00000000_00000000_000000f3;
      tb_block = 128'h0;

      tb_init = 1;
      #(CLK_PERIOD);
      tb_init = 0;
      wait_ready();

      for (i = 0 ; i < 64 ; i = i + 1)
        begin
          $display("*** testcase_long: Processing block %0d", i);
          tb_block    = 128'hffffffff_ffffffff_ffffffff_ffffffff;
          tb_blocklen = 5'h10;
          tb_next     = 1;
          #(CLK_PERIOD);
          tb_next = 0;
          wait_ready();
        end

      $display("*** testcase_long: Processing final block");
      tb_block    = 128'h01000000_00000000_00000000_00000000;
      tb_blocklen = 5'h01;
      tb_next     = 1;
      #(CLK_PERIOD);
      tb_next = 0;
      wait_ready();

      $display("*** testcase_long: Running finish()");
      tb_finish = 1;
      #(CLK_PERIOD);
      tb_finish = 0;
      wait_ready();

      $display("*** testcase_long: Checking the generated MAC.");
      if (tb_mac == 128'hdc0964e5ce9cd7d9a7571fafa5dc0473)
        $display("*** testcase_long: Correct MAC generated.");
      else begin
        $display("*** testcase_long: Error. Incorrect MAC generated.");
        $display("*** testcase_long: Expected: 0xfaffffff_ffffffff_ffffffff_ffffffff");
        $display("*** testcase_long: Got:      0x%032x", tb_mac);
        error_ctr = error_ctr + 1;
      end

      tb_debug  = 0;
      tb_pblock = 0;
      tb_final  = 0;

      $display("*** testcase_long completed.\n");
    end
  endtask // testcase_long


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
      test_p1305_bytes0();
      test_p1305_bytes1();
      test_p1305_bytes2();
      test_p1305_bytes6();
      test_p1305_bytes9();
      test_p1305_bytes12();
      test_p1305_bytes15();
      test_p1305_bytes16();
      test_p1305_bytes32();
      testcase_0();
      testcase_1();
      testcase_2();
      testcase_8();
      testcase_9();
      testcase_10();
      testcase_11();
      testcase_12();
      testcase_long();

      display_test_results();

      $display("*** Testbench for poly1305_core done ***");
      $finish;
    end // main

endmodule // tb_poly1305_core

//======================================================================
// EOF tb_poly1305c_core.v
//======================================================================
