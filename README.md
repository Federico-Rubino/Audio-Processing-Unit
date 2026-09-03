# Audio Processing Unit

A custom SoC on a Zynq-7000 (Zedboard): a from-scratch RV32I RISC-V core plus a proprietary
Audio Processing Unit (APU), both implemented entirely in programmable logic — no dependency on
the Zynq's hard ARM cores. The RV32I core handles control-plane orchestration; the APU is a
fixed-function accelerator that runs small, purpose-built "shader" programs to process the
board's audio codec in real time.

## Architecture

The RV32I core and the APU communicate over a single memory-mapped AXI4-Lite bus, with the CPU
as the sole bus master. The CPU never touches audio data directly — it drives the APU purely as
a peripheral: writing a status/control register pair, staging values into two parameter tables
(one per stereo channel), and loading shader programs into a dedicated instruction memory.

Inside the APU, audio is processed in fixed-size grains and lives in one shared memory (a-ram),
arbitrated so that exactly one "Unit" has access at a time:

- **Audio I/O Unit** — captures/emits real-time audio from the on-board ADAU1761 codec, decoupled
  from the CPU's own timing.
- **Vector Processing Unit** — a pipelined datapath of eight parallel DSP48 cores doing elementwise
  vector/scalar arithmetic (add, subtract, multiply, complex multiply) across a-ram.
- **FFT Unit** — frequency-domain transforms.

A control unit (`AudioCU`) fetches shader instructions, resolves every buffer/scalar reference
through the parameter tables, and dispatches each instruction to the Unit it targets.

On reset, the CPU boots from an on-chip ROM bootloader, which receives firmware, data, and an
optional shader image over UART and jumps to the loaded firmware once the transfer completes —
no JTAG reflash needed to iterate on software.

A full write-up (ISA encoding, control-unit FSMs, per-unit design detail, verification notes)
lives in the project report.

## Repository Layout

```
hardware/
  src/            VHDL source: rv32i/, apu/ (audioIO, vpu, memory_controller, ...), master/
  test/           GHDL/SystemVerilog testbenches, mirroring src/
  ip/             Vivado IP customizations (block memories, the VPU's DSP48 cores, ...)
  tcl-scripts/    Per-unit build scripts + tcl-scripts/master/recreate-bd.tcl (full SoC block design)
  constraints/    Zedboard XDC
software/
  firmware/       RV32I C firmware: bootloader, apu/gpio/uart drivers, main application
  host-tools/     PC-side Python: UART loader, .hex -> .coe converter
  shader-toolchain/  APU shader assembler/disassembler, isa.yaml (declarative ISA spec), examples/
```

## Building the Hardware

Requires Xilinx Vivado (developed against the 2024.x toolchain) targeting the Zedboard.

```sh
git submodule update --init --recursive   # pulls in the ADAU1761 codec interface (zedboard_audio)
```

Run `hardware/tcl-scripts/master/build-master.tcl` in Vivado to regenerate the full SoC project
(block design, IP, constraints) from source. The individual `build-*.tcl` scripts under
`hardware/tcl-scripts/` build each unit (RV32I core, APU, Audio I/O) in isolation for
simulation/bring-up.

## Loading Firmware

1. Build firmware with the Makefiles under `software/firmware/*/` (needs a `riscv32i`-targeting
   GCC toolchain).
2. Assemble a shader (optional — pick one from `software/shader-toolchain/examples/`, or write
   your own against `isa.yaml`):
   ```sh
   pip install -r software/shader-toolchain/requirements.txt
   python3 software/shader-toolchain/assembler.py examples/volume_up.shader -o volume_up.hex
   ```
3. Flash the bitstream, then load firmware (and the shader) over UART:
   ```sh
   pip install pyserial
   python3 software/host-tools/loader.py instr.hex data.hex COM3 --shader volume_up.hex
   ```
   Serial port addresses are read from `software/host-tools/memory_map.ini`.
