from pyelftools import ELFFile
import struct

def extract_main_instructions(input_file, output_file):
    with open(input_file, 'rb') as f:
        elf = ELFFile(f)
        
        # Find the symbol table
        symtab = elf.get_section_by_name('.symtab')
        if not symtab:
            print("No symbol table found")
            return

        # Find the 'main' symbol
        main_symbol = symtab.get_symbol_by_name('main')[0]
        if not main_symbol:
            print("No 'main' symbol found")
            return

        # Get the section containing 'main'
        main_section = elf.get_section(main_symbol['st_shndx'])
        
        # Calculate the offset and size of 'main'
        main_offset = main_symbol['st_value'] - main_section['sh_addr']
        main_size = main_symbol['st_size']

        # Seek to the start of 'main'
        f.seek(main_section['sh_offset'] + main_offset)

        # Read the instructions
        main_data = f.read(main_size)

        # Write instructions to hex file
        with open(output_file, 'w') as hex_file:
            for i in range(0, len(main_data), 4):
                chunk = main_data[i:i+4]
                if len(chunk) < 4:
                    chunk = chunk.ljust(4, b'\0')  # Pad with zeros if less than 4 bytes
                hex_value = struct.unpack('<I', chunk)[0]  # Unpack as little-endian unsigned int
                hex_file.write(f'{hex_value:08X}\n')  # Write as 8-character hex string

# Usage
extract_main_instructions('output.elf', 'py_translated.hex')