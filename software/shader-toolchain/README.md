# APU Shader Toolchain

Assembler/disassembler for the APU's shader instruction set. Turns a `.shader` source file into
the `.hex` word stream the APU's shader memory expects, and back again. See the top-level
[README](../../README.md) and the project report for how this fits into the SoC as a whole.

## Files

- `isa.yaml` — declarative instruction encoding: instruction width, opcode field, and per-opcode
  field layouts (name + bit range). This is the single source of truth for the encoding; nothing
  else in the toolchain hardcodes it.
- `isa.py` — loads `isa.yaml` into lookup tables.
- `preprocessor.py` — resolves comments, `.define`/`.param`/`.macro` directives, and block syntax
  into a flat list of plain instruction lines.
- `encoder.py` — parses one instruction line and packs its fields into words per the ISA table.
- `assembler.py` — CLI entry point tying the above together.
- `disassemble.py` — inverse of the assembler: `.hex` back to mnemonic form, for checking a shader
  encoded as intended.
- `examples/` — complete example shaders (see below).

## Usage

```sh
pip install -r requirements.txt

# assemble
python3 assembler.py examples/volume_up.shader -o volume_up.hex

# also emit a C header with one #define per .param offset, for firmware
python3 assembler.py examples/volume_up.shader -o volume_up.hex --emit-params volume_up.h

# inspect the macro-expanded instruction list before encoding (debugging)
python3 assembler.py examples/volume_up.shader --emit-flat volume_up.flat

# check what a .hex file actually encodes
python3 disassemble.py volume_up.hex
```

`--isa` overrides which `isa.yaml` to use (default: the one alongside `assembler.py`).

## Shader Syntax

```
# comment

.param GRAIN_START          # declares a named parameter-table offset (assigned in order, from 0)
.define FOO 3                # a plain numeric constant, substituted at assembly time

.macro DOUBLE_ADD(buf, gain) # reusable instruction template
    ADD_SCALAR { ... }
    ADD_SCALAR { ... }
.endmacro

AUDIO_IN {                   # block form: one field per line
    buffer_start_reg=GRAIN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

MUL_SCALAR field1=x field2=y # equivalent flat form

DOUBLE_ADD(GRAIN_START, GAIN) # macro call, expands inline

STOP
```

Every field on every opcode is an **offset into the parameter table**, never a literal value
(the only exceptions are `FFT`'s single-bit mode flags). A shader only ever names *which*
parameter-table slot to read; the CPU must stage the real value there via `apu_load_param()`
before running it — see `isa.yaml`'s header comment for the full rationale, and
`software/firmware/main/src/main.c` for worked examples of staging params for a given shader.

## Adding an Opcode

Add an entry under `opcodes:` in `isa.yaml` (value, field list) — no code changes needed in the
assembler itself. Reuse an existing field-layout block via a YAML anchor (`&name` / `*name`) if
the new opcode's layout matches one that already exists, rather than repeating it.

## Examples

`examples/` contains worked shaders: `passthrough.shader` (baseline, no processing),
`volume_up.shader` (scalar gain), and `test_add.shader`/`test_adds.shader` — diagnostic shaders
used to isolate individual VPU operations (`ADD_VEC`, `ADD_SCALAR`/`SUB_SCALAR`) during hardware
bring-up.
