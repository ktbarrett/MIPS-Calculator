.globl inputbuf
.include "macros.h"
.include "params.h"
.data

inputbuf: .space MAX_EXPR_SZ
copybuf: .space MAX_EXPR_SZ
PS: .asciiz ">> "
answer: .asciiz "\t"
exitcmd: .asciiz "exit"
quitcmd: .asciiz "quit"
error_messages: .word 0

.text
main:
	writeString(PS)
	getString(inputbuf, MAX_EXPR_SZ)
	jal isquit
	bne $zero, $v0, _quit
	jal lexer
	bne $v0, $zero, _error
	jal parser
	bne $v0, $zero, _error
	writeString(answer)
	lw $t0, output_stack
	printInteger($t0)
	j main
_error:
	lw $t0, error_messages($v0)
	writeStringReg($t0)
	j main
	
isquit:
	push($ra)
	push($a0)
	push($a1)
	push($v0)
	la $a0, inputbuf
	jal strip
	move $a0, $v0
	jal lowercase
	move $a0, $v0
	la $a1, quitcmd
	jal strcmp
	bne $v0, $zero, _quit
	la $a1, exitcmd
	jal strcmp
	bne $v0, $zero, _quit
	pop($v0)
	pop($a1)
	pop($a0)
	pop($ra)
	jr $ra
_quit:
	exit()