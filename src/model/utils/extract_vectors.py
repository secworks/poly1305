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
    print("Loading vectors from '%s'" % filename)
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
# main()
#-------------------------------------------------------------------
def main():
    print("Generating tests cases.")
    my_vectors = load_vectors("poly1305_vectors.txt")
    my_set = parse_vectors(my_vectors)
    print(my_set)

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
