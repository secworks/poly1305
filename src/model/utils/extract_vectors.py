#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#=======================================================================
#
# extract_vectors.py
# ------------------
# Extract vectors from text file. Convert to C test cases or Verilog.
#
#
# Author: Joachim Strömbergson
# Copyright (c) 2020, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=======================================================================

#-------------------------------------------------------------------
# Python module imports.
#-------------------------------------------------------------------
import sys


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def load_vectors(filename):
    l = []
    with open(filename,'r') as f:
        for line in f:
            l.append(line.strip())
    return l


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def parse_vectors(vlist):
    s = []
    i = 0
    l = len(vlist)
    while i < l:
        k = (vlist[i])[:-1]
        d = (vlist[i + 1])[:-1]
        m = (vlist[i + 2])[:-1]
        dl = int(len(d) / 2)
        s.append((k, dl, d, m))
        i += 4
    return s


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def gen_c_code(vset):
    for i in range(len(vset)):
        gen_c_structs(i, vset[i])


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def print_hexbytes(disp, data):
    disp_str = " " * disp

    print("{", end='')
    i = 0
    while i < len(data):
        print("0x%c%c, " % (data[i], data[i + 1]), end='')
        i += 2
        if (i > 0) and (i % 16 == 0):
            print("")
            print(disp_str + " ", end='')
    print("};")


#-------------------------------------------------------------------
#-------------------------------------------------------------------
def gen_c_structs(i, v):
    k, dl, d, m = v

    # We don't handle zero length messages at the moment.
#    if dl == 0:
#        return

    print("int testcase_%d() {" % i)
    print("  const uint8_t my_key[32] = ", end='')
    print_hexbytes(29, k)
    print("")
    print("  const uint8_t my_message[%d] = " % dl, end='')
    print_hexbytes(33, d)
    print("")
    print("  uint8_t my_expected[16] = ", end='')
    print_hexbytes(28, m)
    print("")

    print("  uint8_t my_tag[16];")
    print("  crypto_poly1305_ctx my_ctx;")
    print("")

    print("  crypto_poly1305_init(&my_ctx, &my_key[0]);")
    print("  crypto_poly1305_update(&my_ctx, &my_message[0], %d);" % dl)
    print("  crypto_poly1305_final(&my_ctx, &my_tag[0]);")
    print("  return check_tag(&my_tag[0], &my_expected[0]);")
    print("}")
    print("")
    print("")

#-------------------------------------------------------------------
# Main()
#-------------------------------------------------------------------
def main():
    my_file = "poly1305_vectors.txt"
    print("// Generated test vectors from the file %s." % my_file)
    my_vectors = load_vectors(my_file)
    my_set = parse_vectors(my_vectors)
    gen_c_code(my_set)

#-------------------------------------------------------------------
# __name__
# Python thingy which allows the file to be run standalone as
# well as parsed from within a Python interpreter.
#-------------------------------------------------------------------
if __name__=="__main__":
    main()
    sys.exit(0)


#=======================================================================
# EOF extract_vectors.py
#=======================================================================
