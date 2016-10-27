.globl inputbuf main
.include "macros.h"
.include "params.h"
.data

inputbuf: .space MAX_EXPR_SZ
copybuf: .space MAX_EXPR_SZ
PS: .asciiz ">> "
answer: .asciiz "ans:\t"
nl: .asciiz "\n"
quitcmd: .asciiz "quit\n"
error_messages: .word 0

.text
main:
	writeString(PS)
	getString(inputbuf, MAX_EXPR_SZ)
	jal isquit
	beq $zero, $v0, _quit
	jal lexer
	bne $v0, $zero, _error
	jal parser
	bne $v0, $zero, _error
	writeString(answer)
	lw $t0, output_stack
	printInteger($t0)
	writeString(nl)
	j main
_error:
	lw $t0, error_messages($v0)
	writeStringReg($t0)
	j main
_quit:
	exit()
	
isquit:
	push($a0)
	push($a1)
	push($ra)
	la $a0, inputbuf
	la $a1 quitcmd
	jal strcmp
	pop($ra)
	pop($a1)
	pop($a0)
	jr $ra
