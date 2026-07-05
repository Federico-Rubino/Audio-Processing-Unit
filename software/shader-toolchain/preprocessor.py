"""Preprocessing: comments, .define constants, and .macro (inline
'function') expansion. Produces a flat list of (line_no, instruction_text)
with defines and macro calls fully resolved -- nothing past this stage knows
that defines or macros ever existed.
"""

import re

from isa import AssemblerError

_DEFINE_RE = re.compile(r"^\.define\s+(\w+)\s+(\S+)\s*$")
_MACRO_START_RE = re.compile(r"^\.macro\s+(\w+)\s*\(([^)]*)\)\s*$")
_MACRO_END_RE = re.compile(r"^\.endmacro\s*$")
_MACRO_CALL_RE = re.compile(r"^(\w+)\s*\(([^)]*)\)\s*$")
_BLOCK_OPEN_RE = re.compile(r"^(\w+)\s*\{(.*)$")


def _strip_comment(line):
    idx = line.find("#")
    return line if idx == -1 else line[:idx]


def _join_blocks(lines):
    """Collapse `MNEMONIC { field=value ... }` blocks -- possibly spread
    across any number of physical lines -- into a single logical
    (line_no, text) entry equivalent to the one-line `MNEMONIC field=value
    ...` form. Runs before .define/.macro handling, so block syntax works
    inside macro bodies too. Anything outside a block passes through as-is.
    """
    joined = []
    i, n = 0, len(lines)
    while i < n:
        line_no, text = lines[i]
        m = _BLOCK_OPEN_RE.match(text)
        if not m:
            joined.append((line_no, text))
            i += 1
            continue

        mnemonic, rest = m.group(1), m.group(2)
        i += 1
        body_parts = []
        closed = "}" in rest
        if closed:
            body_parts.append(rest.split("}", 1)[0])
        else:
            body_parts.append(rest)
            while i < n and not closed:
                _, next_text = lines[i]
                i += 1
                if "}" in next_text:
                    body_parts.append(next_text.split("}", 1)[0])
                    closed = True
                else:
                    body_parts.append(next_text)
            if not closed:
                raise AssemblerError(f"'{mnemonic} {{' has no matching '}}'", line_no)

        joined.append((line_no, f"{mnemonic} {' '.join(body_parts)}".strip()))
    return joined


def _substitute_tokens(text, mapping):
    """Replace whole-word occurrences of mapping keys with their values."""
    if not mapping:
        return text
    pattern = re.compile(r"\b(" + "|".join(re.escape(k) for k in mapping) + r")\b")
    return pattern.sub(lambda m: str(mapping[m.group(0)]), text)


def _split_args(text):
    return [a.strip() for a in text.split(",") if a.strip()]


def preprocess(source_lines):
    """source_lines: raw text lines from the .shader source file (1-indexed
    by position). Returns a list of (line_no, instruction_text) ready for
    the encoder -- comments stripped, .define substituted, .macro calls
    expanded inline. line_no is the original source line (a macro call
    expanding to N instructions reports the call-site line for all of them).
    """
    stripped = []
    for i, raw in enumerate(source_lines, start=1):
        text = _strip_comment(raw).strip()
        if text:
            stripped.append((i, text))

    lines = _join_blocks(stripped)

    defines = {}
    macros = {}  # name -> (params, body [(line_no, text), ...])

    candidates = []  # (line_no, text) -- plain lines or macro calls
    macro_name = macro_params = macro_body = None

    for i, text in lines:
        if macro_name is not None:
            if _MACRO_END_RE.match(text):
                macros[macro_name] = (macro_params, macro_body)
                macro_name = macro_params = macro_body = None
            else:
                macro_body.append((i, text))
            continue

        m = _DEFINE_RE.match(text)
        if m:
            name, value = m.group(1), m.group(2)
            try:
                defines[name] = int(value, 0)
            except ValueError:
                raise AssemblerError(f"'.define {name}' has non-numeric value '{value}'", i)
            continue

        m = _MACRO_START_RE.match(text)
        if m:
            macro_name = m.group(1)
            macro_params = _split_args(m.group(2))
            macro_body = []
            continue

        candidates.append((i, text))

    if macro_name is not None:
        raise AssemblerError(f"'.macro {macro_name}' has no matching .endmacro")

    def apply_defines(text):
        return _substitute_tokens(text, defines)

    # substitute defines inside macro bodies too, once, up front
    macros = {
        name: (params, [(ln, apply_defines(t)) for ln, t in body])
        for name, (params, body) in macros.items()
    }

    instructions = []
    for line_no, text in candidates:
        text = apply_defines(text)
        m = _MACRO_CALL_RE.match(text)
        if m and m.group(1) in macros:
            name, arg_text = m.group(1), m.group(2)
            params, body = macros[name]
            args = _split_args(arg_text)
            if len(args) != len(params):
                raise AssemblerError(
                    f"macro '{name}' expects {len(params)} argument(s), got {len(args)}", line_no
                )
            arg_map = dict(zip(params, args))
            for _, body_text in body:
                instructions.append((line_no, _substitute_tokens(body_text, arg_map)))
        else:
            instructions.append((line_no, text))

    return instructions
