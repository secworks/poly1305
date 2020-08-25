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

# Source files.
MULACC_SRC =../src/rtl/poly1305_mulacc.v
TB_MULACC_SRC =../src/tb/tb_poly1305_mulacc.v

PBLOCK_SRC =../src/rtl/poly1305_pblock.v $(MULACC_SRC)
TB_PBLOCK_SRC =../src/tb/tb_poly1305_pblock.v

FINAL_SRC =../src/rtl/poly1305_final.v
TB_FINAL_SRC =../src/tb/tb_poly1305_final.v

CORE_SRC =../src/rtl/poly1305_core.v $(PBLOCK_SRC) $(FINAL_SRC)
TB_CORE_SRC =../src/tb/tb_poly1305_core.v

TOP_SRC =../src/rtl/poly1305.v $(CORE_SRC)
TB_TOP_SRC =../src/tb/tb_poly1305.v


# Tools and flags.
CC=iverilog
CC_FLAGS= -Wall

LINT=verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


# Targets abd build rules.
all: top.sim core.sim pblock.sim final.sim mulacc.sim


top.sim: $(TB_TOP_SRC) $(TOP_SRC)
	$(CC) $(CC_FLAGS) -o top.sim $(TB_TOP_SRC) $(TOP_SRC)


core.sim: $(TB_CORE_SRC) $(CORE_SRC)
	$(CC) $(CC_FLAGS) -o core.sim $(TB_CORE_SRC) $(CORE_SRC)


pblock.sim: $(TB_PBLOCK_SRC) $(PBLOCK_SRC)
	$(CC) $(CC_FLAGS) -o pblock.sim $(TB_PBLOCK_SRC) $(PBLOCK_SRC)


final.sim: $(TB_FINAL_SRC) $(FINAL_SRC)
	$(CC) $(CC_FLAGS) -o final.sim $(TB_FINAL_SRC) $(FINAL_SRC)


mulacc.sim: $(TB_MULACC_SRC) $(MULACC_SRC)
	$(CC) $(CC_FLAGS) -o mulacc.sim $(TB_MULACC_SRC) $(MULACC_SRC)


sim-top: top.sim
	./top.sim


sim-core: core.sim
	./core.sim


sim-pblock: pblock.sim
	./pblock.sim


sim-final: final.sim
	./final.sim


sim-mulacc: mulaccsim
	./mulaccsim


lint:  $(TOP_SRC)
	$(LINT) $(LINT_FLAGS) $(TOP_SRC)



clean:
	rm -f top.sim
	rm -f core.sim
	rm -f pblock.sim
	rm -f final.sim
	rm -f mulacc.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:        Build all simulation targets."
	@echo "top.sim:    Build Poly1305 top level simulation target."
	@echo "core.sim:   Build Poly1305 core simulation target."
	@echo "pblock.sim: Build Poly1305 poly block simulation target."
	@echo "final.sim:  Build Poly1305 final logic simulation target."
	@echo "mulacc.sim: Build Poly1305 mulacc logic simulation target."
	@echo "sim-top:    Run Poly1305 top level simulation."
	@echo "sim-core:   Run Poly1305 core simulation."
	@echo "sim-pblock: Run Poly1305 poly block simulation."
	@echo "sim-final:  Run Poly1305 final logic simulation."
	@echo "sim-mulacc: Run Poly1305 mulacc logic simulation."
	@echo "lint:       Lint the RTL source."
	@echo "clean:      Remove build targets."

#===================================================================
# EOF Makefile
#===================================================================
