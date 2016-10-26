.globl parser output_stack operator_stack output_types
.include "macros.h"
.include "params.h"
.data

.align 2
output_stack: .space MAX_EXPR_ARRAY_SZ
output_types: .space MAX_EXPR_ARRAY_SZ
operator_stack: .space MAX_EXPR_ARRAY_SZ
_statemachine: .word _parse_finish, _parse_number, _parse_variable, _parse_plusminus, _parse_plusminus, _parse_op, _parse_op, _parse_op, _parse_op, _parse_op

.eqv TOK_IDX $s0
.eqv OUTPUT_IDX $s1
.eqv OPERATOR_IDX $s2
.eqv CURR_TOK $s3
.eqv PREV_TOK $s4

.text

# evaluate as much as possible
.macro evaluate(%r)
	move $a0, %r
	jal eval
	bne $v0, $zero, _parse_leave
.end_macro

# gets next token type from token_type array and stores value in argument
.macro nexttoken()
	move PREV_TOK, CURR_TOK
	lw CURR_TOK, token_types(TOK_IDX)
	inc(TOK_IDX, 4)
.end_macro

# pushes current token to operator stack
.macro pushop()
	sw CURR_TOK, operator_stack(OPERATOR_IDX)
	inc(OPERATOR_IDX, 4)
.end_macro

# peek at top operator in the stack, stores in specified register
.macro peekop(%r)
	dec(OPERATOR_IDX, 4)
	lw %r, operator_stack(OPERATOR_IDX)
	inc(OPERATOR_IDX, 4)
.end_macro

# pushes number in argument to output stack and type in second arguemnt to output type stack
.macro pushout(%r, %t)
	push($t8)
	sw %r, output_stack(OUTPUT_IDX)
	li $t8, %t
	sw $t8, output_types(OUTPUT_IDX)
	inc(OUTPUT_IDX, 4)
	pop($t8)
.end_macro

# gets next token type from token_type array, stores in argument, and jumps state depending upon type value
.macro dispatch()
	nexttoken()
	push($t0)
	sll $t0, CURR_TOK, 2
	pop($t0)
	lw $at, _statemachine(CURR_TOK)
	jr $at
.end_macro


parser:
	# s0 contains index to tokens
	# s1 contains pointer to output stack
	# s2 contains pointer to operator stack
	# s3 always contains current token
	# s4 always contains previous token
	push($ra)
	push($s0)
	push($s1)
	push($s2)
	push($s3)
	push($s4)
	# enter state machine
	move TOK_IDX, $zero # zero index
	li CURR_TOK, TOK_START # start with TOK_START token
	dispatch()
_parse_leave:
	pop($s4)
	pop($s3)
	pop($s2)
	pop($s1)
	pop($s0)
	pop($ra)
	jr $ra


_parse_finish:
	evaluate(CURR_TOK) #v0 is passed through
	j _parse_leave


# Grabs extraneous + and -, conditionally adds negate operator to operator stack
_parse_plusminus:
	# if previous token is an operator or the beginning
	li $t0, TOK_OPS_START
	bge $t0, PREV_TOK, _parse_plusminus_sign
	li $t0, TOK_START
	beq $t0, PREV_TOK, _parse_plusminus_sign
	j _parse_op
_parse_plusminus_sign:
	li $t0, 1 #sign of number
	li $t1, TOK_ADD # +
	li $t2, TOK_SUB # -
_parse_plusminus_L1:
	nexttoken()
	beq CURR_TOK, $t1, _parse_plusminus_L1 # if +, keep going
	bne CURR_TOK, $t2, _parse_plusminus_notsub # if not -, then no longer +/-, exit loop
	not $t0, $t0 # found '-', invert 'negate state'
	b _parse_plusminus_L1
_parse_plusminus_notsub:
	beq $zero, $t0, _parse_plusminus_skip
	# if negate state is negative, add a negate operator to stack
	li $a0, TOK_NEG
	evaluate($a0)
_parse_plusminus_skip:
	dispatch()


_parse_op:
	# Special note: if left paren, just add to operator stack
	evaluate(CURR_TOK)
	dispatch() # dispatch

		
_parse_number:
	lw $t0, token_values(TOK_IDX)
	pushout($t0, TOK_NUM)
	dispatch()

	
_parse_variable:
	push($s5)
	lw $a0, token_values(TOK_IDX) # get start of variable for getvar
	lw $t0, token_ends(TOK_IDX) # get the end of the variable to place a nul
	lb $s5, ($t0) # save character
	sb $zero, ($t0) # set end as nul for getvar to function
	jal getvar # attempt to index the variable name
	bne $v1, $zero, _parse_variable_notfound
	# if the variable name is found, push the value to the output stack as a number
	pushout($v0, TOK_NUM)
	j _parse_variable_leave
_parse_variable_notfound:
	# else push the variable's index in the token arry to the output stack as an unresolved variable
	pushout(TOK_IDX, TOK_VAR)
_parse_variable_leave:
	# place original character back in place of nul-terminator
	lw $t0, token_ends(TOK_IDX)
	sb $s5, ($t0)
	pop($s5)
	dispatch()
