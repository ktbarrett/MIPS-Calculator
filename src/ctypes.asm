.globl isdigit isspace isvarstart isvarname isoperator isend str2num
.include "macros.asm"
.include "params.h"
.data

# bit maps created with python script
_isdigit_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0xff 0x3 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isspace_bm: .byte 0x0 0x3e 0x0 0x0 0x1 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isvarstart_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0xfe 0xff 0xff 0x87 0xfe 0xff 0xff 0x7
_isvarname_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0xff 0x3 0xfe 0xff 0xff 0x87 0xfe 0xff 0xff 0x7
_isop_bm: .byte 0x0 0x0 0x0 0x0 0x0 0xac 0x0 0x20 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0

.text

.macro bit_array_extract(%array)
	srl $t0, $a0, 3
	lb $t0, %array($t0)
	andi $t1, $a0, 7
	srlv $t0, $t0, $t1
	andi $v0, $t0, 1
.end_macro

isdigit:
	bit_array_extract(_isdigit_bm)
	jr $ra

isspace:
	bit_array_extract(_isspace_bm)
	jr $ra

isvarstart:
	bit_array_extract(_isvarstart_bm)
	jr $ra

isvarname:
	bit_array_extract(_isvarname_bm)
	jr $ra
	
isend:
	li $t0, CHR_NUL
	seq $t0, $a0, $t0
	li $v0, CHR_NL
	seq $v0, $a0, $v0
	or $v0, $v0, $t0
	jr $ra
	
isoperator:
	bit_array_extract(_isop_bm)
	jr $ra

# Converts string to integer
#
# @param a0: pointer to string to convert
# @param a1: string end
#
# C:
#    int num = 0
#    while (isdigit((c = str++)))
#        num = num * 10 + c - '0';
str2num:
	# enter
	push($ra)
	push($a0)
	push($s0)
	push($s1)
	# setup variables
	li $s1, 0
	move $s0, $a0
	j _str2num_L1cond
_str2num_L1:
	# num = num * 10 + digit - '0'
	li $t0, 10
	mul $s1, $s1, $t0
	addi $t0, $a0, -48 # '0'
	add $s1, $s1, $t0
	# condition, c = str++, if !isdigit(c) leave
_str2num_L1cond:
	lb $a0, ($s0)
	addi $s0, $s0, 1
	jal isdigit
	bgt $s0, $a1, _str2num_done
	bne $v0, $zero, _str2num_L1
_str2num_done:
	# leave
	move $v0, $s1
	pop($a0)
	pop($s0)
	pop($s1)
	pop($ra)
	jr $ra
	
