    .section .text
    .globl compute_sum

compute_sum:
    # Function prologue
    addi sp, sp, -16    # Allocate stack space
    sw ra, 12(sp)       # Save return address
    sw a0, 8(sp)        # Save a0
    sw a1, 4(sp)        # Save a1

    # Compute sum
    add a0, a0, a1      # a0 = a0 + a1

    # Function epilogue
    lw ra, 12(sp)       # Restore return address
    addi sp, sp, 16     # Deallocate stack space
    ret                 # Return
