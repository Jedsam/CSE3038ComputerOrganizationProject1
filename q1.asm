.data
prompt1: .asciiz "Please enter the coefficients: "
prompt2: .asciiz "Please enter first two numbers of the sequence: "
prompt3: .asciiz "Enter the number you want to calculate (it must be greater than 1): "
output: .asciiz "Output: "
result: .asciiz "th element of the sequence is "

.text
.globl main

main:
    # Display prompt1 and read coefficients a and b
    li $v0, 4
    la $a0, prompt1
    syscall
    li $v0, 5
    syscall
    move $s0, $v0  # s0 = a
    li $v0, 5
    syscall
    move $s1, $v0  # s1 = b

    # Display prompt2 and read first two numbers x0 and x1
    li $v0, 4
    la $a0, prompt2
    syscall
    li $v0, 5
    syscall
    move $s2, $v0  # s2 = x0
    li $v0, 5
    syscall
    move $s3, $v0  # s3 = x1

    invalid_loop:
    	# Display prompt3 and read n
    	li $v0, 4
    	la $a0, prompt3
    	syscall
    	li $v0, 5
    	syscall
    	move $s4, $v0  # s4 = n

    	# Check if n > 1
    	ble $s4, 1, invalid_input

    	# Calculate the nth element of the sequence
    	li $t0, 3      # t0 = counter (counter starts from 3 because the first 2 numbers are already given)
    	move $t1, $s2  # t1 = f(x-2)
    	move $t2, $s3  # t2 = f(x-1)

    	sequence_loop:
        	mul $t3, $s0, $t2    # a * f(x-1)
        	mul $t4, $s1, $t1    # b * f(x-2)
        	add $t5, $t3, $t4    # a * f(x-1) + b * f(x-2)
        	sub $t5, $t5, 2      # a * f(x-1) + b * f(x-2) - 2

        	# Check if counter = n
        	beq $t0, $s4, print_result

        	# Update values for next iteration
        	addi $t0, $t0, 1   # counter++
        	move $t1, $t2  # t1 = f(x-2)
        	move $t2, $t5  # t2 = f(x-1)
        	j sequence_loop

    	print_result:
        	li $v0, 4
        	la $a0, output
        	syscall
        	move $a0, $s4
        	li $v0, 1
        	syscall
        	li $v0, 4
        	la $a0, result
        	syscall
        	move $a0, $t5
        	li $v0, 1
        	syscall
        	j exit

    	invalid_input:
        	j invalid_loop

    	exit:
        	li $v0, 10
        	syscall
