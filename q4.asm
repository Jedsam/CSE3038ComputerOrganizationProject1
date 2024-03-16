.data 
#Given matrix x,y,e1,e2,e3...e x*y
matrix: .byte 5, 6, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0
.text
#Assing same numbers to the lands on the same island
li $s0, 1 # Largest island number (0 not an island)
la $s1, matrix #Adress of matrix
addi $s3, $s1, 2 #Starting point of matrix with bounds (x,y)
#Start of the loops
li $s2, 0#i
lb $s2, 1($s1) #limit of j (x value of matrix)
lb $s1, 0($s1) #limit of i (y value of matrix
slt $t0, 
bne
li $s3, 0#j

Loop1Exit:
#loading byte
lb $t1, 0($s1)
#Find the biggest island


#Printing the result
move $a0, $t1
li $v0, 1
syscall

