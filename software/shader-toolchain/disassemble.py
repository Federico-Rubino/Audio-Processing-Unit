#!/usr/bin/env python3
"""Disassembles a .hex shader word stream back into `MNEMONIC field=value`
text, using isa.yaml as the instruction encoding spec. Mainly useful for:
  - round-trip checking (assemble a .shader, disassemble the .hex, confirm
    the fields match what you wrote -- .define/.macro text itself can't be
    recovered, since those are compile-time only)
  - inspecting a shader dumped back off real hardware over UART

Usage:
    python3 disassemble.py path/to/program.hex [-o path/to/program.dis]
"""

import argparse
import sys
from pathlib import Path

from isa import ISA, AssemblerError


def read_words(hex_path):
    words = []
    with open(hex_path, "r") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                words.append(int(line, 16))
            except ValueError:
                raise AssemblerError(f"'{line}' is not a valid hex word", line_no)
    return words


def disassemble_instruction(isa, words):
    instr = 0
    for w in words:
        instr = (instr << isa.word_bits) | w

    opcode_value = (instr >> isa.opcode_field.lsb) & isa.opcode_field.mask
    opcode = isa.get_by_value(opcode_value)
    if opcode is None:
        return f"; unknown opcode 0x{opcode_value:x}"

    parts = [opcode.name]
    for field in opcode.fields:
        value = (instr >> field.lsb) & field.mask
        parts.append(f"{field.name}=0x{value:x}")

    text = " ".join(parts)
    if not opcode.implemented:
        text += "  ; NOTE: not implemented in hardware yet"
    return text


def disassemble(hex_path, isa_path, stop_at_stop=False):
    isa = ISA(isa_path)
    words = read_words(hex_path)

    n = isa.words_per_instruction
    if len(words) % n != 0:
        raise AssemblerError(
            f"{hex_path} has {len(words)} word(s), not a multiple of {n} (words per instruction)"
        )

    lines = []
    for i in range(0, len(words), n):
        text = disassemble_instruction(isa, words[i : i + n])
        lines.append(text)
        if stop_at_stop and text.split()[0] == "STOP":
            break
    return lines


def main():
    parser = argparse.ArgumentParser(
        description="Disassemble a .hex shader word stream back into MNEMONIC field=value text."
    )
    parser.add_argument("hexfile", help="Path to the .hex word stream")
    parser.add_argument("-o", "--output", help="Output path (default: print to stdout)")
    parser.add_argument(
        "--isa",
        default=str(Path(__file__).parent / "isa.yaml"),
        help="Path to isa.yaml (default: alongside this script)",
    )
    parser.add_argument(
        "--stop-at-stop",
        action="store_true",
        help="Stop decoding after the first STOP instruction instead of reading the whole file",
    )
    args = parser.parse_args()

    try:
        lines = disassemble(args.hexfile, args.isa, args.stop_at_stop)
    except AssemblerError as e:
        print(f"[!] {args.hexfile}: {e}", file=sys.stderr)
        sys.exit(1)

    output = "\n".join(lines) + "\n"
    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"[+] {len(lines)} instruction(s) written to {args.output}")
    else:
        print(output, end="")


if __name__ == "__main__":
    main()
