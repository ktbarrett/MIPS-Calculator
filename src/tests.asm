.globl main
.include "ctypes.asm"
.include "memory.asm"
.include "macros.asm"
.include "strings.asm"
.include "varlist.asm"

.data
test: .asciiz "1234567890"
copybuffer: .space 11
.align 2
testasnum: .word 1234567890

okay: .asciiz "Okay\n"
notokay: .asciiz "Failed\n"
testalignup: .asciiz "Testing alignup... "
teststrlen: .asciiz "Testing strlen... "
teststrcpy: .asciiz "Testing strcpy... "
teststrcmp: .asciiz "Testing strcmp... "
teststr2num: .asciiz "Testing str2num... "
testvarlist: .asciiz "Testing var list operations... "
nl: .asciiz "\n"
space: .asciiz " "

.text

main:
	# test alignup
	writeString(testalignup)
	move $s0, $zero # counter
	move $s2, $zero # test failure acc
	li $s1, 16
	li $a1, 16
	move $a0, $s0
	jal alignup
	addi $s0, $s0, 1
	sne $t1, $zero, $v0
	add $s2, $s2, $t1
_L1:
	move $a0, $s0
	jal alignup
	addi $s0, $s0, 1
	sne $t1, $a1, $v0
	add $s2, $s2, $t1
	bne $s0, $s1, _L1
	la $s0, okay
	la $s1, notokay
	cmovne($s0, $s1, $zero, $s2)
	writeStringReg($s0)
	

	# test strcpy
	writeString(teststrcpy)
	la $a1, test
	la $a0, copybuffer
	jal strcpy
	
	# test strcmp
	writeString(teststrcmp)
	jal strcmp
	la $s0, okay
	la $s1, notokay
	movz $s0, $s1, $v0
	writeStringReg($s0)
	
	# test strlen
	writeString(teststrlen)
	la $a0, test
	jal strlen
	li $t1, 10
	la $s0, okay
	la $s1, notokay
	cmovne($s0, $s1, $v0, $t1)
	writeStringReg($s0)
	
	# test isdigit and str2num
	writeString(teststr2num)
	la $a0, test
	jal strlen
	add $a1, $v0, $a0
	jal str2num
	lw $t1, testasnum
	la $s0, okay
	la $s1, notokay
	cmovne($s0, $s1, $v0, $t1)
	writeStringReg($s0)
	
	writeString(testvarlist)
	initvarlist()
	la $a0, test
	lw $a1, testasnum
	jal setvar
	jal getvar
	la $s0, okay
	la $s1, notokay
	cmovne($s0, $s1, $v0, $a0)
	writeStringReg($s0)
	
	#stop
	exit()