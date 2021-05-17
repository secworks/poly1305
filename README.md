# poly1305
Hardware implementation of the Poly1305 [1] message authentication function.


## Status
Core completed. Core works but have not been used in any design. **Use
with caution.**


## Introduction
This is a hardware implementation of the Poly1305 message authentication
code (MAC) function. The core is written in Verilog version 2001. The
core is compatible wih the Poly1305 described in RFC 8439 [2].

The core is functionally based on, and tested against the Poly1305
implementation in Monocypher [3].

## Usage
The core (poly1305_core.v) has a wide interface with 256 bit key,
128 bit blocks and 128 bit MAC tag as output.

To initialize processing of a message, set the key and assert the 'init'
port for one cycle.

To process the message, divide it into 16 byte block. Process each block by
setting the block and asserting the 'next' port for one cycle. For each
block you must also set the blocklength. For all blocks but the last
block, the expected length is 16 bytes (0x10). For the final block set
the final block length (0x01 .. 0x0f).

To complete the message processsing, assert the 'finish' port for one
cycle.

Note that for 'init', 'next', 'finish' the core will deassert and them
reassert ready to signal that each type of processing has been
completed.


The top level wrapper behaves in the same way, but you will have to
write words in the APU to set keys, blocks and control signals. And you
need to read words in the API to get status and the generated MAC tag.

## Performance
The latency for each operation is:

* init: 2 cycles
* next: 15 cycles
* finish: 9 cycles


## Implementation details
There are testbenches for all modules of the implementation.
The pblock processing uses parallel multiply-accumulate cores.
The implementation really benefits from hard multipliers available in
the target technology (FPGAs).


## FuseSoC
This core is supported by the
[FuseSoC](https://github.com/olofk/fusesoc) core package manager and
build system. Some quick  FuseSoC instructions:

install FuseSoC
~~~
pip install fusesoc
~~~

Create and enter a new workspace
~~~
mkdir workspace && cd workspace
~~~

Register aes as a library in the workspace
~~~
fusesoc library add aes /path/to/aes
~~~

...if repo is available locally or...
...to get the upstream repo
~~~
fusesoc library add aes https://github.com/secworks/aes
~~~

To run lint
~~~
fusesoc run --target=lint secworks:crypto:aes
~~~

Run tb_aes testbench
~~~
fusesoc run --target=tb_aes secworks:crypto:aes
~~~

Run with modelsim instead of default tool (icarus)
~~~
fusesoc run --target=tb_aes --tool=modelsim secworks:crypto:aes
~~~

List all targets
~~~
fusesoc core show secworks:crypto:aes
~~~


## Implementation results

### Intel Cyclone IV GX
* Tool:   Quartus Prime 19.1.0
* Device: EP4CGX22CF19C6
* LEs:    7938
* Regs:   2094
* Mults:  0
* Fmax:   64 MHz


### Microchip IGLOO2 ###
- Tool: Libero release v12.4
- Device: M2GL150TS-FCV484
- LUTs: 3057
- SLEs: 2885
- DSPs: 22
- BRAMs: 0
- Fmax: 74.8 MHz


### Microchip PolarFire ###
- Tool: Libero release v12.4
- Device: M2GL090TS-1FG484I
- LUTs: 3001
- SLEs: 2812
- DSPs: 20
- BRAMs: 0
- Fmax: 74.1 MHz


### Xilinx Artix-7
* Tool:       Vivado 19.2
* Device:     xc7a200tsbv484-1
* LUTs:       1644
* FFs:        1987
* DSPs:       28
* Fmax:       94 MHz


## References
[1] https://en.wikipedia.org/wiki/Poly1305

[2] https://tools.ietf.org/html/rfc8439

[3] http://loup-vaillant.fr/tutorials/poly1305-design
