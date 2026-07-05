import serial.tools.list_ports

# Fetch a list of all available COM ports
ports = serial.tools.list_ports.comports()

if not ports:
    print("No serial ports found. Is your device plugged in?")
else:
    print("Available ports:")
    for port, desc, hwid in sorted(ports):
        print(f"Port: {port}")
        print(f"Description: {desc}")
        print(f"Hardware ID: {hwid}")
        print("-" * 30)