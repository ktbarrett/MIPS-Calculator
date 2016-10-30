.globl inputbuf main
.include "macros.h"
.include "params.h"
.data

inputbuf: .space MAX_EXPR_SZ
copybuf: .space MAX_EXPR_SZ
intro: .ascii "Simple Calculator\n"
.ascii "Kaleb Barrett 2016\n\n"
.ascii "Can evaluate any simple mathematical expression\t+, -, *, /\n"
.ascii "Respects order of operations and parens\n"
.ascii "Can assign values to variables\ta = 12\n"
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
	la $a1 quitcmd
	jal strcmp
	beq $zero, $v0, _quit
	jal lexer
	bne $v0, $zero, _error
	jal parser
	bne $v0, $zero, _error
	#writeString(answer)
	#lw $t0, output_stack
	#printInteger($t0)
	writeString(nl)
	j _main_L1
_quit:
	exit()

_error:
	move $a0, $v0
	jal printError
	j _main_L1
