//======================================================================
//
// tb_poly1305.v
// -------------
// Testbench for Poly1305 top level wrapper.
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

module tb_poly1305();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam CLK_HALF_PERIOD = 1;
  localparam CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  // The DUT address map.
  localparam ADDR_NAME0       = 8'h00;
  localparam ADDR_NAME1       = 8'h01;
  localparam ADDR_VERSION     = 8'h02;

  localparam ADDR_CTRL        = 8'h08;
  localparam CTRL_INIT_BIT    = 0;
  localparam CTRL_NEXT_BIT    = 1;
  localparam CTRL_FINISH_BIT  = 2;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_READY_BIT = 0;

  localparam ADDR_BLOCKLEN    = 8'h0a;

  localparam ADDR_KEY0        = 8'h10;
  localparam ADDR_KEY1        = 8'h11;
  localparam ADDR_KEY2        = 8'h12;
  localparam ADDR_KEY3        = 8'h13;
  localparam ADDR_KEY4        = 8'h14;
  localparam ADDR_KEY5        = 8'h15;
  localparam ADDR_KEY6        = 8'h16;
  localparam ADDR_KEY7        = 8'h17;

  localparam ADDR_BLOCK0      = 8'h20;
  localparam ADDR_BLOCK1      = 8'h21;
  localparam ADDR_BLOCK2      = 8'h22;
  localparam ADDR_BLOCK3      = 8'h23;

  localparam ADDR_MAC0        = 8'h30;
  localparam ADDR_MAC1        = 8'h31;
  localparam ADDR_MAC2        = 8'h32;
  localparam ADDR_MAC3        = 8'h33;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;
  reg           tc_correct;

  reg [31 : 0]  read_data;
  reg [127 : 0] result_mac;

  reg           tb_debug;
  reg           tb_core_state;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7  : 0]  tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  poly1305 dut(
               .clk(tb_clk),
               .reset_n(tb_reset_n),
               .cs(tb_cs),
               .we(tb_we),
               .address(tb_address),
               .write_data(tb_write_data),
               .read_data(tb_read_data)
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
      $display("");
      $display("================================================================");
      $display("cycle:  0x%016x", cycle_ctr);
      $display("DUT internals:");
      $display("ctrl:     init_reg = 0x%01x, next_reg = 0x%01x, finish_reg = 0x%01x",
               dut.init_reg, dut.next_reg, dut.finish_reg);
      $display("ready:    0x%01x", dut.core_ready);
      $display("key:      0x%064x", dut.core_key);
      $display("block:    0x%032x", dut.core_block);
      $display("blocklen: 0x%02x", dut.blocklen_reg);
      $display("mac:      0x%032x", dut.core_mac);

      if (tb_core_state)
        begin
          $display("");
          $display("Internal state:");
          $display("---------------");
          $display("r:     0x%08x_%08x_%08x_%08x",
                   dut.core.r_reg[0], dut.core.r_reg[1],
                   dut.core.r_reg[2], dut.core.r_reg[3]);
          $display("h:     0x%08x_%08x_%08x_%08x_%08x",
                   dut.core.h_reg[0], dut.core.h_reg[1], dut.core.h_reg[2],
                   dut.core.h_reg[3], dut.core.h_reg[4]);
          $display("c:     0x%08x_%08x_%08x_%08x_%08x",
                   dut.core.c_reg[0], dut.core.c_reg[1], dut.core.c_reg[2],
                   dut.core.c_reg[3], dut.core.c_reg[4]);
          $display("s:     0x%08x_%08x_%08x_%08x",
                   dut.core.s_reg[0], dut.core.s_reg[1],
                   dut.core.s_reg[2], dut.core.s_reg[3]);
        end

      $display("================================================================");
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
      $display("TB: Resetting dut.");
      tb_reset_n = 0;
      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
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
      cycle_ctr     = 0;
      error_ctr     = 0;
      tc_ctr        = 0;
      tb_debug      = 0;
      tb_core_state = 0;
      tb_clk        = 0;
      tb_reset_n    = 1;

      tb_cs         = 0;
      tb_we         = 0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
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
      read_word(ADDR_STATUS);
      while (read_data == 0)
        read_word(ADDR_STATUS);
    end
  endtask // wait_ready


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (tb_debug)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // read_mac()
  //----------------------------------------------------------------
  task read_mac;
    begin
      read_word(ADDR_MAC0);
      result_mac[127 : 096] = read_data;
      read_word(ADDR_MAC1);
      result_mac[095 : 064] = read_data;
      read_word(ADDR_MAC2);
      result_mac[063 : 032] = read_data;
      read_word(ADDR_MAC3);
      result_mac[031 : 000] = read_data;
    end
  endtask


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (tb_debug)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // write_key()
  //----------------------------------------------------------------
  task write_key(input [255 : 0] key);
    begin
      if (tb_debug)
        begin
          $display("Writing key to the DUT: 0x%064x", key);
        end

      write_word(ADDR_KEY0, key[255  : 224]);
      write_word(ADDR_KEY1, key[223  : 192]);
      write_word(ADDR_KEY2, key[191  : 160]);
      write_word(ADDR_KEY3, key[159  : 128]);
      write_word(ADDR_KEY4, key[127  :  96]);
      write_word(ADDR_KEY5, key[95   :  64]);
      write_word(ADDR_KEY6, key[63   :  32]);
      write_word(ADDR_KEY7, key[31   :   0]);
    end
  endtask // write_key


  //----------------------------------------------------------------
  // write_block()
  //----------------------------------------------------------------
  task write_block(input [127 : 0] block);
    begin
      if (tb_debug)
        begin
          $display("Writing block to the DUT: 0x%032x", block);
        end

      write_word(ADDR_BLOCK0, block[127  :  96]);
      write_word(ADDR_BLOCK1, block[95   :  64]);
      write_word(ADDR_BLOCK2, block[63   :  32]);
      write_word(ADDR_BLOCK3, block[31   :   0]);
    end
  endtask // write_block


  //----------------------------------------------------------------
  // check_mac
  //----------------------------------------------------------------
  task check_mac(input [127 : 0] expected);
    begin
      read_mac();

      if (result_mac == expected)
        $display("*** check_mac: Correct MAC generated.");
      else begin
        $display("*** check_mac: Error. Incorrect MAC generated.");
        $display("*** check_mac: Expected: 0x%032x", expected);
        $display("*** check_mac: Got:      0x%032x", result_mac);
        error_ctr = error_ctr + 1;
      end
    end
  endtask // check_mac


  //----------------------------------------------------------------
  // test_rfc8439;
  //
  // Test case that uses the test vectors from RFC 8439,
  // section 2.5.2:
  // https://tools.ietf.org/html/rfc8439#section-2.5.2
  //----------------------------------------------------------------
  task test_rfc8439;
    begin : test_rfc8439
      $display("*** test_rfc8439 started.");
      inc_tc_ctr();

      tb_debug = 0;

      write_key(256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b);
      write_block(128'h0);

      $display("*** test_rfc8439: Running init() with the RFC key.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_INIT_BIT));
      wait_ready();
      $display("*** test_rfc8439: init() should be completed.");

      $display("*** test_rfc8439: Loading the first 16 bytes of message and running next().");
      write_block(128'h43727970_746f6772_61706869_6320466f);
      write_word(ADDR_BLOCKLEN, 32'h10);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");

      $display("*** test_rfc8439: Loading the second 16 bytes and running next().");
      write_block(128'h72756d20_52657365_61726368_2047726f);
      write_word(ADDR_BLOCKLEN, 32'h10);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");


      $display("*** test_rfc8439: Loading the final 2 bytes and running next().");
      write_block(128'h75700000_00000000_00000000_00000000);
      write_word(ADDR_BLOCKLEN, 32'h2);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();
      $display("*** test_rfc8439: next() should be completed.");


      $display("*** test_rfc8439: running finish() to get the MAC.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_FINISH_BIT));
      wait_ready();
      $display("*** test_rfc8439: finish() should be completed.");

      $display("*** test_rfc8439: Checking the generated MAC.");
      check_mac(128'ha8061dc1_305136c6_c22b8baf_0c0127a9);

      tb_debug = 0;

      $display("*** test_rfc8439 completed.\n");
    end
  endtask // test_rfc8439


  //----------------------------------------------------------------
  // test_bytes0;
  // Zero byte length message testcase.
  //----------------------------------------------------------------
  task test_bytes0;
    begin : test_bytes0
      $display("*** test_bytes0 started.");
      inc_tc_ctr();

      tb_debug = 0;

      write_key(256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b);
      write_block(128'h0);

      $display("*** test_bytes0: Running init() with the RFC key.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_INIT_BIT));
      wait_ready();
      $display("*** test_bytes0: init() should be completed.");

      $display("*** test_bytes0: Loading the zero byte message and running next().");
      write_block(128'h00000000_00000000_00000000_00000000);
      write_word(ADDR_BLOCKLEN, 32'h0);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();
      $display("*** test_bytes1: next() should be completed.");

      $display("*** test_bytes0: running finish() to get the MAC.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_FINISH_BIT));
      wait_ready();
      $display("*** test_bytes0: finish() should be completed.");

      $display("*** test_bytes0: Checking the generated MAC.");
      check_mac(128'h0103808afb0db2fd4abff6af4149f51b);

      tb_debug = 0;

      $display("*** test_bytes0 completed.\n");
    end
  endtask // test_bytes0


  //----------------------------------------------------------------
  // test_bytes1;
  //
  // Single byte message testcase.
  //----------------------------------------------------------------
  task test_bytes1;
    begin : test_bytes1
      $display("*** test_bytes1 started.");
      inc_tc_ctr();

      tb_debug = 0;

      write_key(256'h85d6be78_57556d33_7f4452fe_42d506a8_0103808a_fb0db2fd_4abff6af_4149f51b);
      write_block(128'h0);

      $display("*** test_bytes1: Running init() with the RFC key.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_INIT_BIT));
      wait_ready();
      $display("*** test_bytes1: init() should be completed.");

      $display("*** test_bytes1: Loading the one byte message and running next().");
      write_block(128'h31000000_00000000_00000000_00000000);
      write_word(ADDR_BLOCKLEN, 32'h1);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();
      $display("*** test_bytes1: next() should be completed.");

      $display("*** test_bytes1: running finish() to get the MAC.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_FINISH_BIT));
      wait_ready();
      $display("*** test_bytes1: finish() should be completed.");

      $display("*** test_bytes1: Checking the generated MAC.");
      check_mac(128'h8097ddf5_19b7f412_0b57fabf_925a19ac);

      tb_debug = 0;

      $display("*** test_bytes1 completed.\n");
    end
  endtask // test_bytes1


  //----------------------------------------------------------------
  // test_long;
  //----------------------------------------------------------------
  task test_long;
    begin : test_long
      integer i;

      $display("*** test_long started.");
      inc_tc_ctr();

      tb_debug      = 0;
      tb_core_state = 0;

      write_key(256'hf3000000_00000000_00000000_0000003f_3f000000_00000000_00000000_000000f3);
      write_block(128'h0);

      $display("*** test_long: Running init() with the RFC key.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_INIT_BIT));
      wait_ready();

      $display("*** test_long: Processing 64 complete blocks.");
      write_block(128'hffffffff_ffffffff_ffffffff_ffffffff);
      write_word(ADDR_BLOCKLEN, 32'h10);
      for (i = 0 ; i < 64 ; i = i + 1)
        begin
          $display("*** testcase_long: Processing block %0d", i);
          write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
          wait_ready();
        end

      $display("*** test_long: Processing the final single byte block.");
      write_block(128'h01000000_00000000_00000000_00000000);
      write_word(ADDR_BLOCKLEN, 32'h1);
      write_word(ADDR_CTRL, (32'h1 << CTRL_NEXT_BIT));
      wait_ready();

      $display("*** test_long: running finish() to get the MAC.");
      write_word(ADDR_CTRL, (32'h1 << CTRL_FINISH_BIT));
      wait_ready();

      $display("*** test_long: Checking the generated MAC.");
      check_mac(128'hdc0964e5ce9cd7d9a7571fafa5dc0473);

      tb_debug      = 0;
      tb_core_state = 0;

      $display("*** test_long completed.\n");
    end
  endtask // test_long


  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("*** Testbench for poly1305 started ***");
      $display("");

      init_sim();

      reset_dut();

      test_bytes0();
      test_bytes1();
      test_rfc8439();
      test_long();

      display_test_results();

      $display("*** Testbench for poly1305 done ***");
      $finish;
    end // main

endmodule // tb_poly1305

//======================================================================
// EOF tb_poly1305c.v
//======================================================================
