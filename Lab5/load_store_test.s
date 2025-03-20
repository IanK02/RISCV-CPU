    .section .data
values:
    .word 10    # Stored value for x5
    .word 15    # Stored value for x6
    .word 5     # Stored value for x7
    .word 20    # Stored value for x8

    .section .text
    .globl _start
    .globl compute_sum

_start:
    la x10, values   # Load address of memory section
    lw x5, 0(x10)    # Load x5 from memory (10)
    lw x6, 4(x10)    # Load x6 from memory (15)
    lw x7, 8(x10)    # Load x7 from memory (5)
    lw x8, 12(x10)   # Load x8 from memory (20)

    # Jump to a random branch
    j branch_1

branch_1:
    beq x5, x6, fail_case_1   # Not taken
    j branch_2

branch_2:
    blt x7, x6, branch_3  # Taken
    j fail_case_2

branch_3:
    sw x8, 0(x10)    # Store x8 (20) in memory
    lw x9, 0(x10)    # Load x9 (should be 20)

    # Jump forward
    j branch_5

branch_4:
    bge x9, x5, branch_5  # Taken
    j fail_case_3

branch_5:
    # Call the function `compute_sum(x5, x6)`
    mv a0, x5   # First argument: x5 = 10
    mv a1, x6   # Second argument: x6 = 15
    call compute_sum  # Function call

    mv x12, a0  # Store return value in x12

    # Conditional jump based on return value
    beq x12, x8, branch_6   # If sum == 20 (incorrect), go to branch_6
    j success_case

branch_6:
    bltu x12, x8, fail_case_4  # Should not be taken
    j success_case

fail_case_1:
fail_case_2:
fail_case_3:
fail_case_4:
    # Infinite loop for failure
    j fail_case_1  

success_case:
    # Success - Infinite loop
    j success_case  
