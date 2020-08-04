//======================================================================
// experiment.c
// -------------
// A simple experiment to test the Monocypher Poly 1305 implementation.
//
// (c) 2020 Joachim Strombergson.
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
//======================================================================

#include <stdio.h>
#include <stdint.h>
#include "monocypher.h"


//------------------------------------------------------------------
// print_hexdata()
// Dump hex data
//------------------------------------------------------------------
void print_hexdata(uint8_t *data, uint32_t len) {
  uint32_t num_lines = len / 8;

  for (int i = 0 ; i < num_lines * 8 ; i += 8)
    printf("0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x\n",
           data[i], data[i + 1], data[i + 2], data[i + 3],
           data[i + 4], data[i + 5], data[i + 6], data[i + 7]);
}


//------------------------------------------------------------------
// p1305_rfc8439()
//
// Test with the test vectors from RFC 8439.
// Se Section 2.5.2.
//------------------------------------------------------------------
void p1305_rfc8439() {

  const uint8_t my_key[32] = {0x85, 0xd6, 0xbe, 0x78, 0x57, 0x55, 0x6d, 0x33,
                              0x7f, 0x44, 0x52, 0xfe, 0x42, 0xd5, 0x06, 0xa8,
                              0x01, 0x03, 0x80, 0x8a, 0xfb, 0x0d, 0xb2, 0xfd,
                              0x4a, 0xbf, 0xf6, 0xaf, 0x41, 0x49, 0xf5, 0x1b};


  const uint8_t my_message[34] = {0x43, 0x72, 0x79, 0x70, 0x74, 0x6f, 0x67, 0x72,
                                  0x61, 0x70, 0x68, 0x69, 0x63, 0x20, 0x46, 0x6f,
                                  0x72, 0x75, 0x6d, 0x20, 0x52, 0x65, 0x73, 0x65,
                                  0x61, 0x72, 0x63, 0x68, 0x20, 0x47, 0x72, 0x6f,
                                  0x75, 0x70};

  uint8_t my_tag[16];
  crypto_poly1305_ctx my_ctx;

  printf("p1305_rfc8439. Check that the RFC test vectors work.\n");

  crypto_poly1305_init(&my_ctx, &my_key[0]);
  crypto_poly1305_update(&my_ctx, &my_message[0], 34);
  crypto_poly1305_final(&my_ctx, &my_tag[0]);

  printf("Generated tag, \n");
  print_hexdata(&my_tag[0], 16);
  printf("\n");

}


//------------------------------------------------------------------
// p1305_test2()
//
// Test that we can get a mac for a message with multiple blocks.
//------------------------------------------------------------------
void p1305_test2() {
  const uint8_t my_key[32] = {0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                              0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                              0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                              0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde};

  const uint8_t my_indata[32] = {0xab, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                                 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                                 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                                 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55};

  uint8_t my_tag[16];

  crypto_poly1305_ctx my_ctx;

  printf("p1305_test2. A multiblock message.\n");

  crypto_poly1305_init(&my_ctx, &my_key[0]);

  crypto_poly1305_update(&my_ctx, &my_indata[0], 32);
  crypto_poly1305_update(&my_ctx, &my_indata[0], 32);
  crypto_poly1305_update(&my_ctx, &my_indata[0], 32);

  crypto_poly1305_final(&my_ctx, &my_tag[0]);

  printf("Generated tag:\n");
  print_hexdata(&my_tag[0], 16);
  printf("\n");
}


//------------------------------------------------------------------
// p1305_test1()
//
// A first simple test that we get a non-zero tag for a block.
//------------------------------------------------------------------
void p1305_test1() {
  uint8_t key[32] = {0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                     0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                     0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde,
                     0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde, 0xde};

  uint8_t indata[32] = {0xab, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                        0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                        0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
                        0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55};

  uint8_t tag[16];

  printf("p1305_test1. A simple one block message.\n");
  crypto_poly1305(tag, &indata[0], 32, &key[0]);

  printf("Generated tag:\n");
  print_hexdata(&tag[0], 16);
  printf("\n");
}


//------------------------------------------------------------------
// int main()
//------------------------------------------------------------------
int main(void) {
  printf("Test of Monocypher Poly1305 function.\n");
  p1305_test1();
  p1305_test2();
  p1305_rfc8439();

  return 0;
}

//======================================================================
// EOF test_poly1305.c
//======================================================================
