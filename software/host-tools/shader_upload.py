"""Runtime shader uploader: listens for the FPGA's SHADER_REQUEST byte
(sent when BTN_U is pressed, see firmware/main/src/main.c) and answers with
a shader assembled by shader-toolchain/assembler.py.

Doubles as a serial monitor -- any byte that isn't part of the protocol is
printed straight to the console, so firmware's printuart() output is still
visible while this is running.

Usage:
    python3 shader_upload.py program.hex [--params program.params] [port]
"""

import argparse
import struct
import sys

import serial

# Must match firmware/main/src/main.c
SHADER_REQUEST = 0xC0
SHADER_NONE = 0xC1
SHADER_DATA = 0xC2
SHADER_ACK = 0xC3

ACK_TIMEOUT_S = 5


def load_hex_words(path):
    words = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                words.append(int(line, 16))
    return words


def load_params(path):
    """Sidecar file: one `offset left right` triple per line (decimal or
    0x-hex), '#' comments allowed. This is hand-written for now -- the
    assembler's --emit-params only emits offsets, not the values to load
    into them."""
    triples = []
    if path is None:
        return triples
    with open(path, "r") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 3:
                sys.exit(f"[!] {path}:{line_no}: expected 'offset left right', got '{line}'")
            offset, left, right = (int(x, 0) for x in parts)
            triples.append((offset, left, right))
    return triples


def send_word(ser, value):
    ser.write(struct.pack("<I", value))


def handle_request(ser, shader_path, params_path, shader_start_addr):
    words = load_hex_words(shader_path)
    params = load_params(params_path)

    print(f"[*] sending {shader_path} ({len(words)} words, {len(params)} param(s))...")
    ser.write(bytes([SHADER_DATA]))
    send_word(ser, shader_start_addr)
    send_word(ser, len(words))
    for w in words:
        send_word(ser, w)
    send_word(ser, len(params))
    for offset, left, right in params:
        send_word(ser, offset)
        send_word(ser, left)
        send_word(ser, right)

    ser.timeout = ACK_TIMEOUT_S
    ack = ser.read(1)
    if ack and ack[0] == SHADER_ACK:
        print("[+] shader acknowledged")
    else:
        print(f"[!] no ACK from device (got {ack.hex() if ack else 'nothing'})")
    ser.timeout = None


def main():
    parser = argparse.ArgumentParser(description="Serve an assembled shader to the FPGA on request.")
    parser.add_argument("hexfile", help="Path to the assembled .hex shader")
    parser.add_argument("--params", help="Path to an 'offset left right' param sidecar file")
    parser.add_argument("--shader-start-addr", type=lambda x: int(x, 0), default=0, help="Offset into shader_mem (default 0)")
    parser.add_argument("port", nargs="?", default="COM3", help="Serial port (default COM3)")
    parser.add_argument("--baud", type=int, default=115200)
    args = parser.parse_args()

    try:
        ser = serial.Serial(args.port, args.baud, timeout=None)
    except Exception as e:
        sys.exit(f"[!] could not open port {args.port}: {e}")

    print(f"[*] listening on {args.port}, will serve {args.hexfile} on request (Ctrl+C to stop)")
    try:
        while True:
            b = ser.read(1)
            if not b:
                continue
            if b[0] == SHADER_REQUEST:
                handle_request(ser, args.hexfile, args.params, args.shader_start_addr)
            else:
                sys.stdout.write(b.decode("utf-8", errors="replace"))
                sys.stdout.flush()
    except KeyboardInterrupt:
        print("\n[*] stopped")
    finally:
        ser.close()


if __name__ == "__main__":
    main()
