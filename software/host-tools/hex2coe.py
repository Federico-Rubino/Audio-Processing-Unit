import argparse
import sys
import os

def hex_to_coe(input_path, output_path, start_addr):
    if not os.path.exists(input_path):
        sys.exit(f"Error: File '{input_path}' not found.")

    with open(input_path, 'r') as f:
        hex_data = [line.strip() for line in f if line.strip()]

    if not hex_data:
        sys.exit("Error: Input file is empty.")

    padded_data = ['00000000'] * start_addr + hex_data

    with open(output_path, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        f.write(",\n".join(padded_data) + ";\n")

    print(f"Success: {len(padded_data)} words written to {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Pad a HEX file with zeros and convert to COE.")
    parser.add_argument("input", help="Path to the input .hex file")
    parser.add_argument("output", help="Path to the output .coe file")
    # type=lambda x: int(x, 0) automatically handles both '10' (decimal) and '0x0A' (hex)
    parser.add_argument("-a", "--address", type=lambda x: int(x, 0), required=True, 
                        help="Starting address/offset (decimal or hex, e.g., 4 or 0x04)")
    
    args = parser.parse_args()
    hex_to_coe(args.input, args.output, args.address)

if __name__ == "__main__":
    main()