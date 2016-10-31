##### SMALL INLINE FUNCTIONS #####

# Stack Push
#
# @ param 1: register to push onto stack
#
# push word
.macro push(%r)
	addi $sp, $sp, -4
	sw %r, ($sp)
.end_macro
# multiple register push
.macro push2(%r1, %r2)
	addi $sp, $sp, -8
	sw %r1, 0($sp)
	sw %r2, 4($sp)
.end_macro
.macro push3(%r1, %r2, %r3)
	addi $sp, $sp, -12
	sw %r1, 0($sp)
	sw %r2, 4($sp)
	sw %r3, 8($sp)
.end_macro
.macro push4(%r1, %r2, %r3, %r4)
	addi $sp, $sp, -16
	sw %r1, 0($sp)
	sw %r2, 4($sp)
	sw %r3, 8($sp)
	sw %r4, 12($sp)
.end_macro
.macro push5(%r1, %r2, %r3, %r4, %r5)
	addi $sp, $sp, -20
	sw %r1, 0($sp)
	sw %r2, 4($sp)
	sw %r3, 8($sp)
	sw %r4, 12($sp)
	sw %r5, 16($sp)
.end_macro

# Stack Pop
#
# @param 1: register to pop value into
#
# pop word
.macro pop (%r)
	lw %r, 0($sp)
	addi $sp, $sp, 4
.end_macro
# multiple register pops
.macro pop2(%r1, %r2)
	lw %r1, 0($sp)
	lw %r2, 4($sp)
	addi $sp, $sp, 8
.end_macro
.macro pop3(%r1, %r2, %r3)
	lw %r1, 0($sp)
	lw %r2, 4($sp)
	lw %r3, 8($sp)
	addi $sp, $sp, 12
.end_macro
.macro pop4(%r1, %r2, %r3, %r4)
	lw %r1, 0($sp)
	lw %r2, 4($sp)
	lw %r3, 8($sp)
	lw %r4, 12($sp)
	addi $sp, $sp, 16
.end_macro
.macro pop5(%r1, %r2, %r3, %r4, %r5)
	lw %r1, 0($sp)
	lw %r2, 4($sp)
	lw %r3, 8($sp)
	lw %r4, 12($sp)
	lw %r5, 16($sp)
	addi $sp, $sp, 20
.end_macro

# Conditional move if equal
# move %dest <- %src if %r1 == %r2
.macro cmoveq(%dest, %src, %r1, %r2)
	sne $t8, %r1, %r2
	movz %dest, %src, $t8
.end_macro

.macro cmoveqi(%dest, %imm, %r1, %r2)
	sne $t8, %r1, %r2
	li $t9, %imm
	movz %dest, $t9, $t8
.end_macro

# Conditional move if not equal
# move %dest <- %src if %r1 != %r2
.macro cmovne(%dest, %src, %r1, %r2)
	seq $t8, %r1, %r2
	movz %dest, %src, $t8
.end_macro

.macro cmovnei(%dest, %imm, %r1, %r2)
	seq $t8, %r1, %r2
	li $t9, %imm
	movz %dest, $t9, $t8
.end_macro

# increment register 'r', amount 'amt'
.macro inc(%r, %amt)
	addi %r, %r, %amt
.end_macro

# decrement register 'r', amount 'amt'
.macro dec(%r, %amt)
	addi %r, %r, -%amt
.end_macro

# different load from array with scaled offset commands
.macro ldb(%dest, %mem, %idx)
	lb %dest, %mem(%idx)
.end_macro
.macro ldh(%dest, %mem, %idx)
	sll $t8, %idx, 1
	lh %dest, %mem($t8)
.end_macro
.macro ldw(%dest, %mem, %idx)
	sll $t8, %idx, 2
	lw %dest, %mem($t8)
.end_macro

# different store from array with scaled index commands
.macro stb(%dest, %mem, %idx)
	sb %dest, %mem(%idx)
.end_macro
.macro sth(%dest, %mem, %idx)
	sll $t8, %idx, 1
	sh %dest, %mem($t8)
.end_macro
.macro stw(%dest, %mem, %idx)
	sll $t8, %idx, 2
	sw %dest, %mem($t8)
.end_macro


###### SYSCALLS ######

# Write String to Console
#
# @param 1: address of string to print
# @clobbers: v0, a0
#
# caveat: No idea what will happen if you try to print a non-nul-term'd string,
# but it's definitely UB.
#
.macro writeString (%string)
	push2($a0, $v0)
	la $a0, %string
	li $v0, 4
	syscall
	pop2($a0, $v0)
.end_macro
.macro writeStringReg(%stringr)
	push2($a0, $v0)
	move $a0, %stringr
	li $v0, 4
	syscall
	pop2($a0, $v0)
.end_macro

# Get String from Console
#
# @param 1: buffer to place string into
# @param 2: maximum length of string to grab
#
# caveat: length specification acts like fgets. Buffer overruns are undefined behavior.
#
.macro getString(%string, %len)
	push3($a0, $a1, $v0)
	la $a0, %string
	li $a1, %len
	li $v0, 8
	syscall
	pop3($a0, $a1, $v0)
.end_macro

# Exit without return value
.macro exit
	li $v0, 10
	syscall
.end_macro

# Get Integer from Console
#
# @param 1: register to place integer into
#
.macro getInteger (%r)
	push($v0)
	li $v0, 5
	syscall
	move %r, $v0
	pop($v0)
.end_macro

# Print Integer to Console
#
# @param 1: register holding integer to print
#
.macro printInteger (%r)
	push2($a0, $v0)
	move $a0, %r
	li $v0, 1
	syscall
	pop2($a0, $v0)
.end_macro

# Allocate memory on the heap using sbrk
#
# @param 1: desination address of pointer to beginning of new block
# @param 2: number of bytes to allocate
#
.macro allocate(%dest, %amt)
	push2($a0, $v0)
	move $a0, %amt
	li $v0, 9
	syscall
	move %dest, $v0
	pop2($a0, $v0)
.end_macro