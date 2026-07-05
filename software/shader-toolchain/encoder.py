"""Parses one preprocessed instruction line and encodes it into words using
the ISA table (isa.py)."""

import re

from isa import AssemblerError

_INSTR_RE = re.compile(r"^(\w+)\s*(.*)$")
_FIELD_RE = re.compile(r"(\w+)\s*=\s*([^\s,]+)")


def parse_instruction(text, line_no):
    m = _INSTR_RE.match(text)
    if not m:
        raise AssemblerError(f"could not parse instruction '{text}'", line_no)
    mnemonic = m.group(1)
    rest = m.group(2).strip()

    field_values = {}
    for fm in _FIELD_RE.finditer(rest):
        name, value_text = fm.group(1), fm.group(2)
        try:
            field_values[name] = int(value_text, 0)
        except ValueError:
            raise AssemblerError(
                f"field '{name}' has non-numeric value '{value_text}' "
                f"(unresolved symbol? check .define spelling)",
                line_no,
            )
    return mnemonic, field_values


def encode_instruction(isa, mnemonic, field_values, line_no):
    opcode = isa.get(mnemonic, line_no)

    instr = opcode.value << isa.opcode_field.lsb

    remaining = dict(field_values)
    for field in opcode.fields:
        if field.name not in remaining:
            raise AssemblerError(f"opcode '{mnemonic}' is missing field '{field.name}'", line_no)
        value = remaining.pop(field.name)
        if value < 0 or value > field.mask:
            raise AssemblerError(
                f"value {value} for field '{field.name}' does not fit in {field.width} bit(s) "
                f"(max {field.mask})",
                line_no,
            )
        instr |= (value & field.mask) << field.lsb

    if remaining:
        raise AssemblerError(
            f"opcode '{mnemonic}' has no field(s): {', '.join(remaining)}", line_no
        )

    words = []
    shift = isa.instruction_bits - isa.word_bits
    word_mask = (1 << isa.word_bits) - 1
    for _ in range(isa.words_per_instruction):
        words.append((instr >> shift) & word_mask)
        shift -= isa.word_bits
    return words
