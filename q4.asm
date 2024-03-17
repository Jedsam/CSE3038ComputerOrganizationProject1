.data 
#Given matrix x,y,e1,e2,e3...e x*y
matrix: .byte 5, 6, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0
maxSize: .word 0
.text
#Assing same numbers to the lands on the same island
li $s0, 2 # Largest island number minus 1 (-1) (0 not an island, 1 unassigned island)
li $v0, 0 # Largest island size
la $s6, matrix #Adress of matrix
addi $s5, $s6, 2 # Current pointer of the matrix with size (x,y)

# Start of the loops
li $s3, 0 # i = 0
lb $s2, 1($s6) #limit of j (x value of matrix)
lb $s1, 0($s6) #limit of i (y value of matrix)

# Calculate the max size adress of matrix
mul $t0, $s1, $s2 
sw $t0, maxSize # Load the size

# if i < y not true then exit loop   
loop1Start:
slt $t0, $s3, $s1   
beq $t0, $zero, Loop1Exit

li $s4, 0 # j = 0 
#if j < x not true then exit loop
loop2Start:
slt $t0, $s4, $s2   
beq $t0, $zero, Loop2Exit

# get the current element
lb $t0, 0($s5) 
li $t1, 1
bne $t0, $t1, Loop2ShortExit # skip the element if it is not 1
# else start method call

# Saving current variables
sub $sp, $sp, 16
sw $s0, 0($sp) 
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $v0, 12($sp)
# Setting parameter variables
mul $t0, $s3, $s2
add $a0, $t0, $s4 # a0 = i * x + j
add $a1, $zero, $s0 # a1 = the island code
add $a2, $zero, $s2 # a2 = x value

# Method call
jal calculateIsland
# Restoring values
lw $s0, 0($sp) 
lw $s1, 4($sp)
lw $ra, 8($sp)
add $t0, $zero, $v0 # Save the return value to temp register
lw $v0, 12($sp) # restore the return value of the original main method
add $sp, $sp, 16

addi $s0, $s0, 1 # increment the island code
slt $t1, $t0, $v0 # if new return value is smaller than current one, dont override
bne $t1, $zero, Loop2ShortExit
# Else override
add $v0, $zero, $t0
 
# skip the method call
Loop2ShortExit:
addi $s5, $s5, 1
addi $s4, $s4, 1
j loop2Start # return to start of loop
Loop2Exit:

addi $s3, $s3, 1
j loop1Start # return to start of loop
Loop1Exit:


#Printing the result
add $a0, $zero, $v0
addi $v0, $zero ,1
syscall

addi $v0, $zero, 10 # Exit code return value
# Exit main
syscall


#Recursive method parameters : 
# a0 = current index
# a1 = island code
# a2 = x value
# returns = amount of islands connected
calculateIsland: 
la $s0, matrix # starting address of matrix
add $s0, $s0, $a0 # Address of current index
addi $s0, $s0, 2 # + 2
sb $a1, 0($s0) # Update the value to the island code

addi $s1, $zero, 1 # get the island count


# Checking the nearby islands
# TOP :  
slt $t0, $a0, $a2   
bne $t0, $zero, topExit # Check currentAddress if its below x
sub $t1, $s0, $a2  # Get the address of top value

# Checking if the top value is equal to 1
lb $t1, 0($t1) # get the bit value of the top
addi $t2, $zero, 1 # Load 1 to t1
bne $t1, $t2, topExit 

# Recursive call 
# Saving values
sub $sp, $sp, 16
sw $a0, 0($sp) 
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s0, 12($sp)
sub $a0, $a0, $a2
jal calculateIsland 
# Restoring values
lw $a0, 0($sp) 
lw $s1, 4($sp)
lw $ra, 8($sp)
sw $s0, 12($sp)
add $sp, $sp, 16

# Add the total count of islands
add $s1, $s1, $v0
topExit: 

# BOTTOM  
lw $t0, maxSize # Get max size
sub $t0, $t0, $a2 # t0 = maxSize - x 
slt $t0, $a0, $t0  
beq $t0, $zero, bottomExit # Check currentAddress if its below maxSize - x 
add $t1, $a2, $s0 # Get the address of bottom value

# Checking if the bottom value is equal to 1
lb $t1, 0($t1) # get the bit value of the bottom
addi $t2, $zero, 1 # Load 1 to t1
bne $t1, $t2, bottomExit 

# Recursive call 
# Saving values
sub $sp, $sp, 16
sw $a0, 0($sp) 
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s0, 12($sp)
add $a0, $a0, $a2
jal calculateIsland 
# Restoring values
lw $a0, 0($sp) 
lw $s1, 4($sp)
lw $ra, 8($sp)
lw $s0, 12($sp)
add $sp, $sp, 16

# Add the total count of islands
add $s1, $s1, $v0
bottomExit: 

# LEFT
rem $t0, $a0, $a2 # t0 = currentIndex % x
beq $t0, $zero, leftExit # Check currentIndex % x equals 0
addi $t1, $s0, -1 # Get the address of left value

# Checking if the left value is equal to 1
lb $t1, 0($t1) # get the bit value of the left
addi $t2, $zero, -1 # Load 1 to t1
bne $t1, $t2, leftExit 

# Recursive call 
# Saving values
sub $sp, $sp, 16
sw $a0, 0($sp) 
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s0, 12($sp)
addi $a0, $a0, -1
jal calculateIsland 
# Restoring values
lw $a0, 0($sp) 
lw $s1, 4($sp)
lw $ra, 8($sp)
lw $s0, 12($sp)
add $sp, $sp, 16

# Add the total count of islands
add $s1, $s1, $v0
leftExit: 

# RIGHT
rem $t0, $a0, $a2 # t0 = currentIndex % x
addi $t1, $a2, -1 # t1 = x - 1
beq $t0, $t1, rightExit # Check currentIndex % x equals x - 1

add $t1, $s0, 1 # Get the address of right value

# Checking if the right value is equal to 1
lb $t1, 0($t1) # get the bit value of the right
addi $t2, $zero, 1 # Load 1 to t1
bne $t1, $t2, rightExit 

# Recursive call 
# Saving values
sub $sp, $sp, 16
sw $a0, 0($sp) 
sw $s1, 4($sp)
sw $ra, 8($sp)
sw $s0, 12($sp)
addi $a0, $a0, 1
jal calculateIsland 
# Restoring values
lw $a0, 0($sp) 
lw $s1, 4($sp)
lw $ra, 8($sp)
lw $s0, 12($sp)
add $sp, $sp, 16

# Add the total count of islands
add $s1, $s1, $v0
rightExit: 

# Return total of numbers
add $v0, $zero, $s1
jr $ra
