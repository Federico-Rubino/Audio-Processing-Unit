import argparse
import configparser
import os
from pathlib import Path

import serial
import sys
import struct
import time
import threading

# Protocol Constants
READY_SIGNAL = 0xAA
ACK_SIGNAL = 0xAB
CMD_LOAD_CHUNK = 0x01
CMD_FINISHED = 0x02

DEFAULT_CONFIG_PATH = Path(__file__).parent / "memory_map.ini"


def load_config(config_path):
    """Reads the [addresses] section of memory_map.ini into a dict of ints
    (instr_start_addr, data_start_addr, shader_start_addr)."""
    parser = configparser.ConfigParser()
    if not parser.read(config_path):
        sys.exit(f"[!] Error: config file '{config_path}' not found.")
    addrs = parser["addresses"]
    return {name: int(value, 0) for name, value in addrs.items()}


def send_word(ser, value):
    """Sends 32-bit word in Little Endian."""
    ser.write(struct.pack('<I', value))

def load_hex_file(filename):
    """Reads a hex file where each line is a 32-bit hex string."""
    words = []
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    words.append(int(line, 16))
        return words
    except FileNotFoundError:
        print(f"[!] Error: File {filename} not found.")
        sys.exit(1)

def send_chunk(ser, address, data_words):
    if not data_words:
        return
    
    print(f"[*] Sending chunk to 0x{address:08X} ({len(data_words)} words)...")
    ser.write(bytes([CMD_LOAD_CHUNK]))
    send_word(ser, address)
    send_word(ser, len(data_words))
    
    for i, word in enumerate(data_words):
        send_word(ser, word)
        if i % 100 == 0:
            print(f"    Progress: {i}/{len(data_words)}", end='\r')
            
    # Wait for ACK
    ack = ser.read(1)
    if ack and ack[0] == ACK_SIGNAL:
        print(f"\n[+] Chunk at 0x{address:08X} acknowledged.")
    else:
        print(f"\n[!] Error: Expected ACK, got {ack.hex() if ack else 'Timeout'}")
        sys.exit(1)

def serial_monitor(ser):
    """Continuously reads from serial and prints to console."""
    print("\n--- Serial Monitor Active (Ctrl+C to stop) ---")
    try:
        while True:
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                # Using 'replace' for bytes that aren't valid UTF-8
                print(data.decode('utf-8', errors='replace'), end='', flush=True)
            time.sleep(0.01)
    except KeyboardInterrupt:
        print("\n--- Closing Monitor ---")

def main():
    parser = argparse.ArgumentParser(description="Upload a CPU program (and optionally a shader) over the UART bootloader.")
    parser.add_argument("instr", help="Path to the CPU instruction .hex file")
    parser.add_argument("data", help="Path to the CPU data .hex file")
    parser.add_argument("port", nargs="?", default="COM3", help="Serial port (default: COM3)")
    parser.add_argument("--shader", help="Path to an assembled shader .hex file to upload into APU shader memory")
    parser.add_argument(
        "--config",
        default=str(DEFAULT_CONFIG_PATH),
        help=f"Path to the memory-map config file (default: {DEFAULT_CONFIG_PATH.name} alongside this script)",
    )
    args = parser.parse_args()

    cfg = load_config(args.config)

    try:
        ser = serial.Serial(args.port, 115200, timeout=2)
    except Exception as e:
        print(f"[!] Could not open port {args.port}: {e}")
        return

    print(f"[*] Port {args.port} opened. Reset your FPGA to start...")

    # 1. Wait for Bootloader
    while True:
        b = ser.read(1)
        if b and b[0] == READY_SIGNAL:
            print("[+] Bootloader Ready Signal Received!")
            break

    # 2. Upload Sections
    instr_data = load_hex_file(args.instr)
    send_chunk(ser, cfg["instr_start_addr"], instr_data)

    data_vals = load_hex_file(args.data)
    send_chunk(ser, cfg["data_start_addr"], data_vals)

    if args.shader:
        shader_words = load_hex_file(args.shader)
        send_chunk(ser, cfg["shader_start_addr"], shader_words)

    # 3. Finish and Jump
    print("[*] Sending Finished Command...")
    ser.write(bytes([CMD_FINISHED]))
    ser.close()
    os.system(f"python -m serial.tools.miniterm {args.port} 115200 --dtr 0 --rts 0")

if __name__ == "__main__":
    main()