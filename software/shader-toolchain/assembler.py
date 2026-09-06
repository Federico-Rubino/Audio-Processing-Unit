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


def write_shader_header(header_path, source_path, params, words):
    """Writes a C header with the assembled word array and one #define per `.param` offset."""
    guard = re.sub(r"\W", "_", header_path.stem.upper()) + "_H"
    array_name = re.sub(r"\W", "_", header_path.stem.lower()) + "_words"
    with open(header_path, "w") as f:
        f.write(f"#ifndef {guard}\n#define {guard}\n")
        f.write(f"/* generated from {source_path.name} -- do not hand-edit */\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"static const uint32_t {array_name}[] = {{\n")
        for i in range(0, len(words), 4):
            row = ", ".join(f"0x{w:08x}" for w in words[i:i + 4])
            f.write(f"    {row},\n")
        f.write("};\n\n")
        for name, offset in params:
            f.write(f"#define {name} {offset}\n")
        f.write(f"\n#endif // {guard}\n")


def assemble(source_path, isa_path, min_param_offset=0):
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

    instructions, params = preprocess(lines, min_param_offset=min_param_offset)

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
        "--min-param-offset",
        type=lambda s: int(s, 0),
        default=0,
        help="Force .param allocation to start no lower than this offset -- for a shader "
        "with no LOAD instruction of its own that still needs to avoid a range another "
        "cooperating shader writes directly (e.g. LOAD's fixed 0-127 grain region, written "
        "by firmware, not by that other shader's own .params)",
    )
    parser.add_argument(
        "--emit-params",
        nargs="?",
        const=True,
        default=None,
        metavar="PATH",
        help="Also write a C header with the assembled word array and one #define per .param "
        "offset, for firmware to include directly (default: alongside source, .h extension)",
    )
    args = parser.parse_args()

    source_path = Path(args.source)
    output_path = Path(args.output) if args.output else source_path.with_suffix(".hex")

    try:
        words, instructions, params = assemble(source_path, args.isa, min_param_offset=args.min_param_offset)
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
        write_shader_header(header_path, source_path, params, words)
        print(f"[+] {len(words)} word(s) and {len(params)} param offset(s) written to {header_path}")


if __name__ == "__main__":
    main()
