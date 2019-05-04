#===================================================================
#
# Makefile
# --------
# Makefile for building running the Poly1305 core and
# top simulation targets. There is also support for linting.
#
#
# Copyright (c) 2016, Secworks Sweden AB
# Joachim Strömbergson
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
#===================================================================

BLOCK_SRC =../src/rtl/poly1305_block.v

TB_BLOCK_SRC =../src/tb/tb_poly1305_block.v

CC=iverilog
CC_FLAGS= -Wall

LINT=verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


all: block.sim


block.sim: $(TB_BLOCK_SRC) $(BLOCK_SRC)
	$(CC) $(CC_FLAGS) -o block.sim $(TB_BLOCK_SRC) $(BLOCK_SRC)


sim-block: block.sim
	./block.sim


lint:  $(BLOCK_SRC)
	$(LINT) $(LINT_FLAGS) $(BLOCK_SRC)



clean:
	rm -f block.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:        Build all simulation targets."
	@echo "block:      Build Poly1305 block simulation target."
	@echo "sim-block:  Run Poly1305 block simulation."
	@echo "lint:       Lint the RTL source."
	@echo "clean:      Remove build targets."

#===================================================================
# EOF Makefile
#===================================================================
