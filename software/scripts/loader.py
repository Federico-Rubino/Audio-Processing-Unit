import os

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

# New Memory Map Addresses
INSTR_START_ADDR = 0x00010000
DATA_START_ADDR  = 0x000200F0

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
    if len(sys.argv) < 3:
        print("Usage: python loader.py <instr.hex> <data.hex> [port]")
        return

    instr_file = sys.argv[1]
    data_file = sys.argv[2]
    port = sys.argv[3] if len(sys.argv) > 3 else 'COM3' # Adjust for your system
    
    try:
        ser = serial.Serial(port, 115200, timeout=2)
    except Exception as e:
        print(f"[!] Could not open port {port}: {e}")
        return

    print(f"[*] Port {port} opened. Reset your FPGA to start...")
    
    # 1. Wait for Bootloader
    while True:
        b = ser.read(1)
        if b and b[0] == READY_SIGNAL:
            print("[+] Bootloader Ready Signal Received!")
            break

    # 2. Upload Sections
    instr_data = load_hex_file(instr_file)
    send_chunk(ser, INSTR_START_ADDR, instr_data)

    data_vals = load_hex_file(data_file)
    send_chunk(ser, DATA_START_ADDR, data_vals)

    # 3. Finish and Jump
    print("[*] Sending Finished Command...")
    ser.write(bytes([CMD_FINISHED]))
    ser.close()
    os.system(f"python -m serial.tools.miniterm COM63 115200 --dtr 0 --rts 0")

if __name__ == "__main__":
    main()