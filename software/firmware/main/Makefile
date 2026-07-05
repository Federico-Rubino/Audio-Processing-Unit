#Toolchain
CC = riscv64-unknown-elf-gcc
OBJDUMP = riscv64-unknown-elf-objdump
OBJCOPY = riscv64-unknown-elf-objcopy

# Include directories
INCLUDES = -Iinclude -I../uart/include -I../common -I../gpio/include -I../apu/include

# Project files
SRC = ../bsp/startup.s src/main.c
ELF = bin/firmware.elf
BIN_INSTR = bin/instr.bin
BIN_DATA = bin/data.bin
HEX_INSTR = bin/instr.hex
HEX_DATA = bin/data.hex

#Compiler flags
CFLAGS = -O2 -Wall -march=rv32i -mabi=ilp32 -ffreestanding -nostartfiles -nodefaultlibs $(INCLUDES)
SFLAGS = -S -fverbose-asm -O2 -Wall -march=rv32i -mabi=ilp32 -ffreestanding -nostartfiles -nodefaultlibs $(INCLUDES)
LDFLAGS = -T ../bsp/linker.ld

#Default target
all: $(ELF) $(HEX_INSTR) $(HEX_DATA)

#compile ELF
$(ELF): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ -lgcc

# Generate instruction binary (.text)
$(BIN_INSTR): $(ELF)
	$(OBJCOPY) -j .text -O binary $< $@

# Generate data binary (.data + .rodata)
$(BIN_DATA): $(ELF)
	$(OBJCOPY) -O binary -j .data -j .rodata -j .sdata -j .srodata $< $@


# Generate hex files from binaries
$(HEX_INSTR): $(BIN_INSTR)
	hexdump -v -e '1/4 "%08x\n"' $< > $@

$(HEX_DATA): $(BIN_DATA)
	hexdump -v -e '1/4 "%08x\n"' $< > $@

# Optional disassembly
disasm: $(ELF)
	$(OBJDUMP) -d $< > bin/firmware.asm

asm:
	$(CC) $(SFLAGS) $(LDFLAGS) -o bin/main.s src/main.c

clean:
	rm -f $(ELF) $(BIN_INSTR) $(BIN_DATA) $(HEX_INSTR) $(HEX_DATA) bin/firmware.asm
