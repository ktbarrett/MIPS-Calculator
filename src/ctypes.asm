
.data

# bit maps created with python script
_isdigit_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0xff 0x3 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isspace_bm: .byte 0x0 0x3e 0x0 0x0 0x1 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isalpha_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0xfe 0xff 0xff 0x7 0xfe 0xff 0xff 0x7
_isalnum_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0xff 0x3 0xfe 0xff 0xff 0x7 0xfe 0xff 0xff 0x7

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

isalpha:
	bit_array_extract(_isalpha_bm)
	jr $ra

isalnum:
	bit_array_extract(_isalnum_bm)
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
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $a0, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
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
	lw $s1, 0($sp)
	lw $s0, 4($sp)
	lw $a0, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
