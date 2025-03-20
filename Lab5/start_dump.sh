#!/bin/bash

# Directory containing the RISC-V tools
TOOL_DIR="/root/EE469/xpacks/.bin"

# Input file (object file generated from start.s)
INPUT_FILE="start.o"

# Output file for the objdump output
OUTPUT_FILE="start.txt"

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found!"
    exit 1
fi

# Run objdump on the object file and pipe the output to start.txt
"$TOOL_DIR/riscv-none-elf-objdump" -d "$INPUT_FILE" > "$OUTPUT_FILE"

# Notify the user
echo "Objdump output saved to $OUTPUT_FILE"