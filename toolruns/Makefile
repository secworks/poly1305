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

PBLOCK_SRC =../src/rtl/poly1305_pblock.v
TB_PBLOCK_SRC =../src/tb/tb_poly1305_pblock.v

CORE_SRC =../src/rtl/poly1305_core.v $(PBLOCK_SRC)
TB_CORE_SRC =../src/tb/tb_poly1305_core.v


CC=iverilog
CC_FLAGS= -Wall

LINT=verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


all: core.sim pblock.sim


core.sim: $(TB_CORE_SRC) $(CORE_SRC)
	$(CC) $(CC_FLAGS) -o core.sim $(TB_CORE_SRC) $(CORE_SRC)


pblock.sim: $(TB_PBLOCK_SRC) $(PBLOCK_SRC)
	$(CC) $(CC_FLAGS) -o pblock.sim $(TB_PBLOCK_SRC) $(PBLOCK_SRC)


sim-core: core.sim
	./core.sim


sim-pblock: pblock.sim
	./pblock.sim


lint:  $(CORE_SRC)
	$(LINT) $(LINT_FLAGS) $(CORE_SRC)



clean:
	rm -f core.sim
	rm -f pblock.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:        Build all simulation targets."
	@echo "core:       Build Poly1305 core simulation target."
	@echo "pblock:     Build Poly1305 poly block simulation target."
	@echo "sim-core:   Run Poly1305 core simulation."
	@echo "sim-pblock: Run Poly1305 poly block simulation."
	@echo "lint:       Lint the RTL source."
	@echo "clean:      Remove build targets."

#===================================================================
# EOF Makefile
#===================================================================
