.globl parser
.include "macros.asm"
.data

.text

.macro _nexttoken(%r0)
	lw $t0, tokens(%r0)
	lw $t1, token_starts(%r0)
	lw $t2, token_ends(%r)
.end_macro

# Grabs 
_parse_plusminus:
	push($ra)
	# t0, t1, t2 used by _nexttoken
	move $t3, $zero #sign of number
	li $t4, TOK_OPS # to see if toke is an operator
_parse_plusmins_L1:
	_nexttoken()
	blt $t0, $t4, _parse_plusminus_done
	
_parse_plusmins_done:
	

parser:
	