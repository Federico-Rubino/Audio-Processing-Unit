"""Uploads a grain-packed .hex file into APU a-ram over UART, matching ir_preload_stage() in main.c."""

import struct
import sys

# Protocol constants -- must match ir_preload_stage() in main.c
IR_READY_SIGNAL = 0xCC
IR_ACK_SIGNAL = 0xCD
IR_CMD_LOAD_GRAIN = 0x01
IR_CMD_FINISHED = 0x02

GRAIN_WORDS = 128  # 256 samples / 2 samples-per-word


def load_hex_file(filename):
    """Reads a hex file where each line is a 32-bit hex string, and checks it's grain-aligned."""
    words = []
    try:
        with open(filename, "r") as f:
            for line in f:
                line = line.strip()
                if line:
                    words.append(int(line, 16))
    except FileNotFoundError:
        sys.exit(f"[!] Error: file {filename} not found.")

    if len(words) % GRAIN_WORDS != 0:
        sys.exit(f"[!] Error: {filename} has {len(words)} words, not a multiple of {GRAIN_WORDS} "
                  f"(not grain-aligned -- was it produced by audio_to_hex.py?)")
    return words


def send_word(ser, value):
    """Sends a 32-bit word in little-endian, matching uart_read_word()."""
    ser.write(struct.pack("<I", value))


def send_grain(ser, grain_index, words):
    ser.write(bytes([IR_CMD_LOAD_GRAIN]))
    for w in words:
        send_word(ser, w)

    # bridge latency can leave a stray leftover IR_READY_SIGNAL ahead of the real ACK -- not an error
    while True:
        b = ser.read(1)
        if not b:
            sys.exit(f"\n[!] Error: grain {grain_index}: timeout waiting for ACK")
        if b[0] == IR_ACK_SIGNAL:
            return
        if b[0] != IR_READY_SIGNAL:
            sys.exit(f"\n[!] Error: grain {grain_index}: expected ACK, got {b.hex()}")


def upload_ir(ser, hexfile):
    """Uploads a grain-aligned .hex file to a-ram over an already-open connection. Does not open or close `ser`."""
    words = load_hex_file(hexfile)
    num_grains = len(words) // GRAIN_WORDS

    print(f"[*] Waiting for the board's IR-ready signal (it resends this continuously)...")
    while True:
        b = ser.read(1)
        if b and b[0] == IR_READY_SIGNAL:
            print("[+] Ready signal received.")
            break

    # discard the backlog of ready bytes still queued behind the one just read
    ser.reset_input_buffer()

    for g in range(num_grains):
        grain_words = words[g * GRAIN_WORDS:(g + 1) * GRAIN_WORDS]
        send_grain(ser, g, grain_words)
        print(f"    Grain {g + 1}/{num_grains} acknowledged", end="\r")

    print(f"\n[*] Sending IR Finished Command...")
    ser.write(bytes([IR_CMD_FINISHED]))
    print(f"[+] Done: {num_grains} grains uploaded.")
