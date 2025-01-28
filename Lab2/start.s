#.extern main
.globl _start

.text

_start:
#
# Uncomment / add to / etc to test lab 2


                        #auipc   a4,0x1000
                        #addi    a4,a4,-436
                        #add a5,a5,a4

#
# place additional test instructions here

# Initialize registers
li x1, 10            # Set x1 = 10
li x2, 5             # Set x2 = 5
li x30, 0            # Clear x30 (used for checksum)

# Test R-type instructions
add x3, x1, x2       # ADD: x3 = x1 + x2 = 15
sub x4, x1, x2       # SUB: x4 = x1 - x2 = 5
and x5, x1, x2       # AND: x5 = x1 & x2 = 0
or  x6, x1, x2       # OR:  x6 = x1 | x2 = 15
xor x7, x1, x2       # XOR: x7 = x1 ^ x2 = 15
sll x8, x1, x2       # SLL: x8 = x1 << (x2 & 0x1F) = 320
srl x9, x1, x2       # SRL: x9 = x1 >> (x2 & 0x1F) = 0
sra x10, x1, x2      # SRA: x10 = x1 >>> (x2 & 0x1F) = 0
slt x11, x1, x2      # SLT: x11 = (x1 < x2) ? 1 : 0 = 0
sltu x12, x1, x2     # SLTU: x12 = (unsigned)x1 < (unsigned)x2 ? 1 : 0 = 0

# Accumulate R-type results into x30 (checksum)
add x30, x30, x3     # x30 += x3
add x30, x30, x4     # x30 += x4
add x30, x30, x5     # x30 += x5
add x30, x30, x6     # x30 += x6
add x30, x30, x7     # x30 += x7
add x30, x30, x8     # x30 += x8
add x30, x30, x9     # x30 += x9
add x30, x30, x10    # x30 += x10
add x30, x30, x11    # x30 += x11
add x30, x30, x12    # x30 += x12

# Test I-type instructions
addi x13, x1, 10     # ADDI: x13 = x1 + 10 = 20
andi x14, x1, 15     # ANDI: x14 = x1 & 15 = 10
ori  x15, x1, 7      # ORI:  x15 = x1 | 7 = 15
xori x16, x1, 9      # XORI: x16 = x1 ^ 9 = 3
slli x17, x1, 3      # SLLI: x17 = x1 << 3 = 80
srli x18, x1, 2      # SRLI: x18 = x1 >> 2 = 2
srai x19, x1, 2      # SRAI: x19 = x1 >>> 2 = 2
slti x20, x1, 8      # SLTI: x20 = (x1 < 8) ? 1 : 0 = 0
sltiu x21, x1, 8     # SLTIU: x21 = (unsigned)x1 < 8 ? 1 : 0 = 0

# Accumulate I-type results into x30 (checksum)
add x30, x30, x13    # x30 += x13
add x30, x30, x14    # x30 += x14
add x30, x30, x15    # x30 += x15
add x30, x30, x16    # x30 += x16
add x30, x30, x17    # x30 += x17
add x30, x30, x18    # x30 += x18
add x30, x30, x19    # x30 += x19
add x30, x30, x20    # x30 += x20
add x30, x30, x21    # x30 += x21


### Everything below here is not required for lab2.
######
#
#  halt
#        li a0, 0x0002FFFC
#        sw zero, 0(a0)
        
# Eventually this is is the start of your code for future labs (by lab 4 this will be needed)
#    li      sp, (0x00030000 - 16)
#    call    main
#    call    halt
#    j       _start

