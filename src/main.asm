.globl inputbuf main
.include "macros.h"
.include "params.h"
.include "chars.h"
.include "error.h"
.data

inputbuf: .space MAX_EXPR_SZ
copybuf: .space MAX_EXPR_SZ
intro: .ascii "Simple Calculator\n"
.ascii "Kaleb Barrett 2016\n\n"
.ascii "Can evaluate any simple mathematical expression\t\t+ - * / ( )\t(9 + (-5)) * 24 / 2\n"
.ascii "Respects order of operations and parens\t\t\t12 - 3 * 4\t-> 0\n"
.ascii "Can assign expressions to variables\t\t\ta = 12 - 8\t-> 4, a = 4\n"
.ascii "Can use assignments as values\t\t\t\t12 + (b = 8)\t-> 20, b = 8\n"
.asciiz "'quit' to stop evaluation and clear memory\n\n"
PS: .asciiz ">> "
answer: .asciiz "ans:\t"
nl: .asciiz "\n"
quitcmd: .asciiz "quit\n"

.text
main:
	writeString(intro)
_main_L1:
	writeString(PS)
	getString(inputbuf, MAX_EXPR_SZ)
	# check if user is quiting
	la $a0, inputbuf
	la $a1, quitcmd
	jal strcmp
	beq $zero, $v0, _quit
	la $a1, nl
	jal strcmp
	beq $zero, $v0, _main_L1
	jal lexer
	bne $v0, $zero, _error
	jal validater
	bne $v0, $zero, _error
	jal parser
	bne $v0, $zero, _error
	jal eval
	bne $v0, $zero, _error
	writeString(answer)
	printInteger($v1)
	writeString(nl)
	j _main_L1
_quit:
	exit()

_error:
	move $a0, $v0
	jal printError
	j _main_L1
