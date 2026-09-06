"""Standalone sample upload to a board already sitting in ir_preload_stage().
Prefer `loader.py --sample <hexfile>` instead -- a fresh connection here
resets a reset-on-connect UART bridge (e.g. an ESP32) before it can relay
anything. Usage: python3 sample_loader.py path/to/file.hex [port]"""

import argparse
import sys

import serial

import ir_protocol


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("hexfile", help="Grain-aligned .hex file to upload (e.g. IR.hex)")
    parser.add_argument("port", nargs="?", default="COM3", help="Serial port (default: COM3)")
    parser.add_argument("--baud", type=int, default=115200)
    args = parser.parse_args()

    try:
        ser = serial.Serial(args.port, args.baud, timeout=5)
    except Exception as e:
        sys.exit(f"[!] Could not open port {args.port}: {e}")

    print(f"[*] Port {args.port} opened.")
    ir_protocol.upload_ir(ser, args.hexfile)
    ser.close()


if __name__ == "__main__":
    main()
