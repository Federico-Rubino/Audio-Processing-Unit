#!/usr/bin/env python3
"""Assembles a .shader source file into a .hex word stream for APU shader
memory, using isa.yaml as the instruction encoding spec.

Usage:
    python3 assembler.py path/to/program.shader [-o path/to/program.hex]
"""

import argparse
import re
import sys
from pathlib import Path

from encoder import encode_instruction, parse_instruction
from isa import ISA, AssemblerError
from preprocessor import preprocess


def write_param_header(header_path, source_path, params):
    """Writes a C header with one #define per `.param` offset, so firmware
    can call apu_load_param(apu, left, right, PARAM_NAME) instead of a bare
    number that has to be kept in sync with the shader by hand."""
    guard = re.sub(r"\W", "_", header_path.stem.upper()) + "_H"
    with open(header_path, "w") as f:
        f.write(f"#ifndef {guard}\n#define {guard}\n")
        f.write(f"/* generated from {source_path.name} -- do not hand-edit */\n\n")
        for name, offset in params:
            f.write(f"#define {name} {offset}\n")
        f.write(f"\n#endif // {guard}\n")


def assemble(source_path, isa_path):
    """Returns (words, instructions, params):
      - instructions: the flattened (line_no, text) list after
        .define/.param/.macro resolution -- exposed so the CLI can
        optionally dump it for inspection/debugging.
      - params: (name, offset) list from this shader's `.param` directives
        -- exposed so the CLI can emit a firmware-side offset manifest.
    """
    isa = ISA(isa_path)
    with open(source_path, "r") as f:
        lines = f.readlines()

    instructions, params = preprocess(lines)

    words = []
    for line_no, text in instructions:
        mnemonic, field_values = parse_instruction(text, line_no)
        words.extend(encode_instruction(isa, mnemonic, field_values, line_no))
    return words, instructions, params


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
    parser.add_argument(
        "--emit-params",
        nargs="?",
        const=True,
        default=None,
        metavar="PATH",
        help="Also write a C header with one #define per .param offset, for firmware to include "
        "(default: alongside source, .h extension)",
    )
    args = parser.parse_args()

    source_path = Path(args.source)
    output_path = Path(args.output) if args.output else source_path.with_suffix(".hex")

    try:
        words, instructions, params = assemble(source_path, args.isa)
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

    if args.emit_params is not None:
        header_path = Path(args.emit_params) if isinstance(args.emit_params, str) else source_path.with_suffix(".h")
        write_param_header(header_path, source_path, params)
        print(f"[+] {len(params)} param offset(s) written to {header_path}")


if __name__ == "__main__":
    main()
