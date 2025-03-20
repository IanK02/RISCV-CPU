.section .text
.global _start

_start:
    # Initialize values in registers
    li x1, 10        # x1 = 10
    li x2, 20        # x2 = 20
    li x3, -5        # x3 = -5
    li x4, 0x1000    # x4 = memory base address
    li x5, 5         # x5 = loop counter
    li x6, 0         # x6 = accumulator

    # Store initial values in memory
    sw x1, 0(x4)     # Store 10 at [0x1000]
    sw x2, 4(x4)     # Store 20 at [0x1004]
    sw x3, 8(x4)     # Store -5 at [0x1008]

loop:
    lw x7, 0(x4)     # Load 10
    lw x8, 4(x4)     # Load 20
    lw x9, 8(x4)     # Load -5

    add x7, x7, x8   # x7 = 10 + 20 = 30
    sub x8, x7, x9   # x8 = 30 - (-5) = 35
    and x9, x8, x3   # x9 = 35 & (-5) (stresses dependency)
    
    add x6, x6, x9   # Accumulate result in x6

    addi x5, x5, -1  # Decrement loop counter
    bne x5, x0, loop # Repeat if x5 != 0

    # Final computation
    ori x10, x6, 0   # Store result in x10 (should be 42 if all goes well)

    # Exit loop
exit:
    nop
    nop
    j exit           # Infinite loop to halt execution
