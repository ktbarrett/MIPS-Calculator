##### SMALL INLINE FUNCTIONS #####

# Stack Push
#
# @ param 1: register to push onto stack
#
# push word
.macro push (%r)
	addi $sp, $sp, -4
	sw %r, ($sp)
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

# Conditional move if equal
# move %dest <- %src if %r1 == %r2
.macro cmoveq(%dest, %src, %r1, %r2)
	push($t0)
	sne $t0, %r1, %r2
	movz %dest, %src, $t0
	pop($t0)
.end_macro

# Conditional move if not equal
# move %dest <- %src if %r1 != %r2
.macro cmovne(%dest, %src, %r1, %r2)
	push($t0)
	seq $t0, %r1, %r2
	movz %dest, %src, $t0
	pop($t0)
.end_macro

# increment register 'r', amount 'amt'
.macro inc(%r, %amt)
	addi %r, %r, %amt
.end_macro

# decrement register 'r', amount 'amt'
.macro dec(%r, %amt)
	addi %r, %r, -%amt
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
	push($a0)
	push($v0)
	la $a0, %string
	li $v0, 4
	syscall
	pop($v0)
	pop($a0)
.end_macro
.macro writeStringReg(%stringr)
	push($a0)
	push($v0)
	move $a0, %stringr
	li $v0, 4
	syscall
	pop($v0)
	pop($a0)
.end_macro

# Get String from Console
#
# @param 1: buffer to place string into
# @param 2: maximum length of string to grab
# @clobbers: v0, a0, a1
#
# caveat: length specification acts like fgets. Buffer overruns are undefined behavior.
#
.macro getString(%string, %len)
	push($a0)
	push($a1)
	push($v0)
	la $a0, %string
	li $a1, %len
	li $v0, 8
	syscall
	pop($v0)
	pop($a1)
	pop($a0)
.end_macro

# Exit without return value
.macro exit
	li $v0, 10
	syscall
.end_macro

# Get Integer from Console
#
# @param 1: register to place integer into
# @clobbers: v0
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
# @clobbers: v0, a0
#
.macro printInteger (%r)
	push($a0)
	push($v0)
	move $a0, %r
	li $v0, 1
	syscall
	pop($v0)
	pop($a0)
.end_macro
