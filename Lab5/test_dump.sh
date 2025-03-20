#!/bin/bash

# Directory containing the RISC-V tools
TOOL_DIR="/root/EE469/xpacks/.bin"

# Input file (fully linked ELF executable)
INPUT_FILE="test"

# Output file for the objdump output
OUTPUT_FILE="test.txt"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found!"
    exit 1
fi

# Run objdump on the fully linked executable and save output to test.txt
"$TOOL_DIR/riscv-none-elf-objdump" -d "$INPUT_FILE" > "$OUTPUT_FILE"

# Notify the user
echo "Objdump output saved to $OUTPUT_FILE"
