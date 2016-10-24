.globl parser output_stack operator_stack output_types
.include "macros.h"
.include "params.h"
.data

output_stack: .space MAX_EXPR_ARRAY_SZ
output_types: .space MAX_EXPR_ARRAY_SZ
operator_stack: .space MAX_EXPR_ARRAY_SZ
_statemachine: .word _parse_finish, _parse_number, _parse_variable, _parse_plusminus, _parse_plusminus, _parse_op, _parse_op, _parse_op, _parse_op, _parse_rparen

.text

# gets next token type from token_type array and stores value in argument
.macro nexttoken()
	move $s4, $s3
	lw $s3, token_types($s0)
	addi $s0, $s0, 4
.end_macro

# pushes current token to operator stack
.macro pushop()
	sw $s3, operator_stack($s2)
	addi $s2, $s2, 4
.end_macro

# pushes number in argument to output stack and type in second arguemnt to output type stack
.macro pushout(%r, %t)
	sw %r, output_stack($s1)
	li $t0, %t
	sw $t0, output_types($s1)
	addi $s1, $s1, 4
.end_macro

# gets next token type from token_type array, stores in argument, and jumps state depending upon type value
.macro dispatch()
	nexttoken()
	lw $at, _statemachine($s3)
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
	move $s0, $zero # zero index
	li $s3, TOK_START # start with TOK_START token
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


_parse_error:
	li $v0, 1
	j _parse_leave


# Grabs extraneous + and -, conditionally adds negate operator to operator stack
_parse_plusminus:
	# if previous token is an operator
	li $t0, TOK_OPS_START
	bge $t0, $s4, _parse_plusminus_sign
	j _parse_op
_parse_plusminus_sign:
	li $t0, 1 #sign of number
	li $t1, TOK_ADD # +
	li $t2, TOK_SUB # -
_parse_plusminus_L1:
	nexttoken()
	beq $s3, $t1, _parse_plusminus_L1 # if +, keep going
	bne $s3, $t2, _parse_plusminus_notsub # if not -, then no longer +/-, exit loop
	not $t0, $t0 # found '-', invert 'negate state'
	b _parse_plusminus_L1
_parse_plusminus_notsub:
	beq $zero, $t0, _parse_plusminus_skip
	# if negate state is negative, add a negate operator to stack
	li $t0, TOK_NEG
	sw $t0, operator_stack($s2)
	addi $s2, $s2, 4
_parse_plusminus_skip:
	dispatch()


_parse_op:
	# Special note: if left paren, just add to operator stack
	pushop() # push current token to operator stack
	dispatch() # dispatch

		
_parse_number:
	lw $t0, token_values($s0)
	pushout($t0, TOK_NUM)
	dispatch()
	
_parse_variable:
	push($s5)
	lw $a0, token_values($s0) # get start of variable for getvar
	lw $t0, token_ends($s0) # get the end of the variable to place a nul
	lb $s5, ($t0) # save character
	sb $zero, ($t0) # set end as nul for getvar to function
	jal getvar # attempt to index the variable name
	bne $v1, $zero, _parse_variable_notfound
	# if the variable name is found, push the value to the output stack as a number
	pushout($v0, TOK_NUM)
	j _parse_variable_leave
_parse_variable_notfound:
	# else push the variable's index in the token arry to the output stack as an unresolved variable
	pushout($s0, TOK_VAR)
_parse_variable_leave:
	# place original character back in place of nul-terminator
	lw $t0, token_ends($s0)
	sb $s5, ($t0)
	pop($s5)
	dispatch()


_parse_rparen:
	# if right paren, evaluate until left paren
	li $a0, TOK_LPAR
	jal eval
	bne $v0, $zero, _parse_error
	dispatch()
