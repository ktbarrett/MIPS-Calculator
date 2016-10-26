.globl setjmp longjmp
.data

.text

# saves all registers state
# exceptions:
#	$0: always 0, redundant
#	$1: instruction temporary register, redundant
#	$2: contains return from longjmp argument
#
# @return v0: single result passed from coresponding longjmp argument
# @param a0: single argument address to store shit
#
# given meory location must have 116 bytes allocated
setjmp:
	sw $3, 0($a0)
	sw $4, 4($a0)
	sw $5, 8($a0)
	sw $6, 12($a0)
	sw $7, 16($a0)
	sw $8, 20($a0)
	sw $9, 24($a0)
	sw $10, 28($a0)
	sw $11, 32($a0)
	sw $12, 36($a0)
	sw $13, 40($a0)
	sw $14, 44($a0)
	sw $15, 48($a0)
	sw $16, 52($a0)
	sw $17, 56($a0)
	sw $18, 60($a0)
	sw $19, 64($a0)
	sw $20, 68($a0)
	sw $21, 72($a0)
	sw $22, 76($a0)
	sw $23, 80($a0)
	sw $24, 84($a0)
	sw $25, 88($a0)
	sw $26, 92($a0)
	sw $27, 96($a0)
	sw $28, 100($a0)
	sw $29, 104($a0)
	sw $30, 108($a0)
	sw $31, 112($a0)

# instates registers from preceding call to setjmp
#
# @param a0: address of setjmp buffer
# @param a1: single result to return from setjmp
longjmp:
	move $v0, $a1 # return from longjmp
	lw $3, 0($a0)
	lw $4, 4($a0)
	lw $5, 8($a0)
	lw $6, 12($a0)
	lw $7, 16($a0)
	lw $8, 20($a0)
	lw $9, 24($a0)
	lw $10, 28($a0)
	lw $11, 32($a0)
	lw $12, 36($a0)
	lw $13, 40($a0)
	lw $14, 44($a0)
	lw $15, 48($a0)
	lw $16, 52($a0)
	lw $17, 56($a0)
	lw $18, 60($a0)
	lw $19, 64($a0)
	lw $20, 68($a0)
	lw $21, 72($a0)
	lw $22, 76($a0)
	lw $23, 80($a0)
	lw $24, 84($a0)
	lw $25, 88($a0)
	lw $26, 92($a0)
	lw $27, 96($a0)
	lw $28, 100($a0)
	lw $29, 104($a0)
	lw $30, 108($a0)
	lw $31, 112($a0)
	jr $ra # jump back to location saved in setjmp
