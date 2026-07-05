"""Loads isa.yaml into simple lookup structures for the assembler."""

import yaml


class AssemblerError(Exception):
    def __init__(self, message, line=None):
        self.line = line
        prefix = f"line {line}: " if line is not None else ""
        super().__init__(prefix + message)


class Field:
    def __init__(self, name, msb, lsb):
        self.name = name
        self.msb = msb
        self.lsb = lsb
        self.width = msb - lsb + 1
        self.mask = (1 << self.width) - 1


class Opcode:
    def __init__(self, name, value, fields, implemented):
        self.name = name
        self.value = value
        self.fields = fields  # list[Field]
        self.implemented = implemented


class ISA:
    def __init__(self, path):
        with open(path, "r") as f:
            spec = yaml.safe_load(f)

        self.instruction_bits = spec["instruction_bits"]
        self.word_bits = spec["word_bits"]
        self.words_per_instruction = self.instruction_bits // self.word_bits
        if spec["word_order"] != "msb_first":
            raise AssemblerError(f"unsupported word_order '{spec['word_order']}'")

        self.opcode_field = Field("opcode", spec["opcode_field"]["msb"], spec["opcode_field"]["lsb"])

        self.opcodes = {}
        self.by_value = {}
        for name, entry in spec["opcodes"].items():
            fields = [Field(f["name"], f["msb"], f["lsb"]) for f in entry.get("fields", [])]
            opcode = Opcode(
                name=name,
                value=entry["value"],
                fields=fields,
                implemented=entry.get("implemented", True),
            )
            self.opcodes[name] = opcode
            if opcode.value in self.by_value:
                raise AssemblerError(
                    f"opcodes '{self.by_value[opcode.value].name}' and '{name}' "
                    f"both use value 0x{opcode.value:x}"
                )
            self.by_value[opcode.value] = opcode

    def get(self, mnemonic, line=None):
        opcode = self.opcodes.get(mnemonic)
        if opcode is None:
            raise AssemblerError(f"unknown opcode '{mnemonic}'", line)
        if not opcode.implemented:
            raise AssemblerError(
                f"opcode '{mnemonic}' is not implemented yet (marked implemented: false in isa.yaml)", line
            )
        return opcode

    def get_by_value(self, value):
        return self.by_value.get(value)
