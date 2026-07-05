#!/usr/bin/env python3
"""Assembles a .shader source file into a .hex word stream for APU shader
memory, using isa.yaml as the instruction encoding spec.

Usage:
    python3 assembler.py path/to/program.shader [-o path/to/program.hex]
"""

import argparse
import sys
from pathlib import Path

from encoder import encode_instruction, parse_instruction
from isa import ISA, AssemblerError
from preprocessor import preprocess


def assemble(source_path, isa_path):
    """Returns (words, instructions), where instructions is the flattened
    (line_no, text) list after .define/.macro resolution -- exposed so the
    CLI can optionally dump it for inspection/debugging."""
    isa = ISA(isa_path)
    with open(source_path, "r") as f:
        lines = f.readlines()

    instructions = preprocess(lines)

    words = []
    for line_no, text in instructions:
        mnemonic, field_values = parse_instruction(text, line_no)
        words.extend(encode_instruction(isa, mnemonic, field_values, line_no))
    return words, instructions


def main():
    parser = argparse.ArgumentParser(description="Assemble an APU shader source file into a .hex word stream.")
    parser.add_argument("source", help="Path to the .shader source file")
    parser.add_argument("-o", "--output", help="Output .hex path (default: alongside source, same name)")
    parser.add_argument(
        "--isa",
        default=str(Path(__file__).parent / "isa.yaml"),
        help="Path to isa.yaml (default: alongside this script)",
    )
    parser.add_argument(
        "--emit-flat",
        nargs="?",
        const=True,
        default=None,
        metavar="PATH",
        help="Also write the flattened instruction list (.define/.macro resolved, "
        "pre-encoding) to PATH (default: alongside source, .flat extension)",
    )
    args = parser.parse_args()

    source_path = Path(args.source)
    output_path = Path(args.output) if args.output else source_path.with_suffix(".hex")

    try:
        words, instructions = assemble(source_path, args.isa)
    except AssemblerError as e:
        print(f"[!] {source_path}: {e}", file=sys.stderr)
        sys.exit(1)

    with open(output_path, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")

    print(f"[+] {len(words)} words written to {output_path}")

    if args.emit_flat is not None:
        flat_path = Path(args.emit_flat) if isinstance(args.emit_flat, str) else source_path.with_suffix(".flat")
        with open(flat_path, "w") as f:
            for line_no, text in instructions:
                f.write(f"{text}  # line {line_no}\n")
        print(f"[+] {len(instructions)} flattened instruction(s) written to {flat_path}")


if __name__ == "__main__":
    main()
