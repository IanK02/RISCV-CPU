#
#
# Convert a string into a integer.
#
# e.g. my_atoi("-55") should return: -55
#      my_atoi("+55") should return +55
#      my_atoi("55") should return 55
## Function: my_atoi
# Arguments:
#   a0 - pointer to the input string
# Return value:
#   a0 - converted integer
.globl my_atoi
.text
my_atoi:
    # Prologue
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    # Initialize variables
    li s0, 0       # result
    li s1, 0       # negate flag
    mv s2, a0      # s2 = input string pointer

    # Check if input is null
    beqz s2, end

    # Check for sign
    lbu t0, 0(s2)
    li t1, 45      # ASCII '-'
    beq t0, t1, negative
    li t1, 43      # ASCII '+'
    beq t0, t1, positive
    j convert

negative:
    li s1, 1       # Set negate flag
    addi s2, s2, 1 # Move to next character
    j convert

positive:
    addi s2, s2, 1 # Move to next character

convert:
    lbu t0, 0(s2)  # Load current character
    beqz t0, apply_sign # If null, end conversion

    # Check if character is a digit
    li t1, 48      # ASCII '0'
    blt t0, t1, apply_sign
    li t1, 57      # ASCII '9'
    bgt t0, t1, apply_sign

    # Multiply result by 10
    slli t1, s0, 3 # result * 8
    slli t2, s0, 1 # result * 2
    add s0, t1, t2 # result = result * 10

    # Add current digit
    addi t0, t0, -48 # Convert ASCII to integer
    add s0, s0, t0   # Add to result

    addi s2, s2, 1   # Move to next character
    j convert

apply_sign:
    beqz s1, end   # If not negative, skip
    neg s0, s0     # Negate result

end:
    mv a0, s0      # Move result to return register

    # Epilogue
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 16
    ret