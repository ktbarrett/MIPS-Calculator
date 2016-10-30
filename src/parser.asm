.globl parser output_stack output_types
.include "macros.h"
.include "params.h"
.include "parser.h"
.include "lexer.h"
.include "error.h"
.data

.align 2
output_stack: .space MAX_EXPR_ARRAY_SZ
output_types: .space MAX_EXPR_SZ
operator_stack: .space MAX_EXPR_SZ

# rules for operators
precedence: .byte 0, 0, 0, OPP_ADD, OPP_SUB, OPP_MUL, OPP_DIV, OPP_ASS, OPP_NEG
associativity: .byte 0, 0, 0, OPA_ADD, OPA_SUB, OPA_MUL, OPA_DIV, OPA_ASS, OPA_NEG

_parser_jmptbl: .word _parse_finish, _parse_number, _parse_variable, _parse_plusminus, _parse_plusminus, _parse_op, _parse_op, _parse_op, _parse_op, _parse_lpar, _parse_rpar

.eqv TOKEN_IDX $s0
.eqv OUTPUT_IDX $s1
.eqv OPERATOR_IDX $s2

.text

# get next token and use it to jump to next part of state machine
.macro dispatch()
	inc(TOKEN_IDX, 1)
	ldb($t0, token_types, TOKEN_IDX)
	ldw($t0, _parser_jmptbl, $t0)
	jr $t0
.end_macro
	
.macro pushop(%r)
	stb(%r, operator_stack, OPERATOR_IDX)
	inc(OPERATOR_IDX, 1)
.end_macro

.macro popop(%r)
	dec(OPERATOR_IDX, 1)
	ldb(%r, operator_stack, OPERATOR_IDX)
.end_macro

.macro pushout(%type, %value)
	stb(%type, output_types, OUTPUT_IDX)
	stw(%value, output_stack, OUTPUT_IDX)
	inc(OUTPUT_IDX, 1)
.end_macro


# starts parser state machine
parser:
	push4($ra, $a0, $a1, $v1)
	push3($s0, $s1, $s2)
	# setup variables
	li TOKEN_IDX, -1
	li OUTPUT_IDX, 0
	li OPERATOR_IDX, 0
	# inital dispatch
	dispatch()
_parser_leave:
	pop3($s0, $s1, $s2)
	pop4($ra, $a0, $a1, $v1)
	jr $ra


# push number type and value onto appropriate output stacks
_parse_number:
	ldw($t1, token_values, TOKEN_IDX) # number value
	li $t0, TOK_NUM # number type
	pushout($t0, $t1)
	dispatch()


# while operator stack is not empty pop operators off opperator
# stack and on to output type stack. If any of the operators are
# left paren, then there is a missing right paren
_parse_finish:
	# if operator stack empty, leave
	beqz OPERATOR_IDX, _parse_finish_done
	# else, pop one operator off operator stack
	popop($t0)
	# if the operator is left parens, error
	beq $t0, TOK_LPAR, _parse_finish_error
	# else, push onto output
	pushout($t0, $zero)
	j _parse_finish
_parse_finish_done:
	# ensure a TOK_END is put on the output stack so the evaluater knows when to stop
	li $t0, TOK_END
	pushout($t0, $zero)
	li $v0, 0
	j _parser_leave
_parse_finish_error:
	li $v0, ERR_MISSINGRPAR
	j _parser_leave
	
# push left parens onto operator stack
_parse_lpar:
	li $t0, TOK_LPAR
	pushop($t0)
	dispatch()


# pop operator off operator stack and onto output stack until 
# left paren is found. If the end of the stack is reached before a
# left paren is found, missing left paren
_parse_rpar:
	# if operator stack empty, error
	beqz OPERATOR_IDX, _parse_rpar_error
	# else, pop one operator off operator stack
	popop($t0)
	# if the operator is left parens, leave (already popped)
	beq $t0, TOK_LPAR, _parse_rpar_done
	# else, push onto output
	pushout($t0, $zero)
	j _parse_rpar
_parse_rpar_done:
	dispatch()
_parse_rpar_error:
	li $v0, ERR_MISSINGLPAR
	j _parser_leave


# see if variable is defined yet, if it is push value onto output
# stack and number onto type stack. If not defined yet, push
# variable type onto type stack and variable index onto value stack 
_parse_variable:
	ldw($t0, token_values, TOKEN_IDX)
	ldw($a0, var_begin, $t0)
	ldw($t1, var_end, $t0)
	# swap byte at location of variable end with nul-term so getvar works
	lb $t0, ($t1)
	push2($t0, $t1)
	sb $zero, ($t1) # place nul terminator
	jal getvar
	pop2($t0, $t1)
	sb $t0, ($t1) # save old byte value back, probably not necessary
	# check if found
	beqz $v0, _parse_variable_found
	# not found push variable onto output
	ldw($t1, token_values, TOKEN_IDX)
	li $t0, TOK_VAR
	pushout($t0, $t1)
	j _parse_variable_done
_parse_variable_found:
	# found, push num to type stack and value in v0 to value stack
	li $t0, TOK_NUM
	pushout($t0, $v1)
_parse_variable_done:
	dispatch()


# returns truthness of previous operation being an operation that
# requires op to be parsed as a sign
#
# @param a0: previous operation
# @return v0: 0 if op is valid, 1 if it is not valid
#
# valid ops to cause parse as a sign:
#    + - * / = (
_parse_plusminus_validop:
	li $v0, 1
	cmoveqi($v0, 0, $a0, TOK_ADD)
	cmoveqi($v0, 0, $a0, TOK_SUB)
	cmoveqi($v0, 0, $a0, TOK_MUL)
	cmoveqi($v0, 0, $a0, TOK_DIV)
	cmoveqi($v0, 0, $a0, TOK_ASS)
	cmoveqi($v0, 0, $a0, TOK_LPAR)
	jr $ra


# if previous operation is an operator that requires following
# plus and minus operators as signs, or the beginning or there
# is no previous token (beginning of expression), then parse
# following plu and minus signs as the sign of a number and
# conditionally generate a negate operation if it is negative.
# If not a valid previous operator or not beginning of expression
# parse the plus or minus as an operator
_parse_plusminus:
	# if beginning of string, parse as sign
	beqz TOKEN_IDX, _parse_sign
	# if preceding token is valid operator, parse as sign
	addi $t0, TOKEN_IDX, -1
	ldb($a0, token_types, $t0) # t0 contains previous token
	jal _parse_plusminus_validop
	beqz $v0, _parse_sign
	# else parse as addition/subtraction
	j _parse_op


# picks up as many plus and minus and makes effective sign
_parse_sign:
	dec(TOKEN_IDX, 1)
	li $t1, 0 # negate state
_parse_sign_L1:
	inc(TOKEN_IDX, 1)
	ldb($t0, token_types, TOKEN_IDX)
	beq $t0, TOK_ADD, _parse_sign_L1 # if token is +, skip
	bne $t0, TOK_SUB, _parse_sign_L2 # if token not -, token isn't +/-: end
	# token is -
	not $t1, $t1
	j _parse_sign_L1
_parse_sign_L2:
	beqz $t1, _parse_sign_notneg # if negate state is 0, effective sign is 0, skip 'neg' generation
	# generate a negate operation
	# since negate is always the lowest precedence operation and there is never another
	# negate before a negate, just put immediately onto output stack
	li $t0, TOK_NEG
	pushout($t0, $zero)
_parse_sign_notneg:
	dec(TOKEN_IDX, 1) # now pointing to one past end of current token sequence, dispatch will increment again
	dispatch()


# do precedence and associativity parsing
#
# while (1) {
#    if operator_stack empty
#        push current operator to operator stack
#        break
#    if previous op is left associative
#        if previous op's precedence > current op's precedence
#            pop previous operator from operator stack
#            push previous operator onto output stack
#            continue
#        else
#            push current operator onto operator stack
#            break
#    else // associativity == right
#        if previous op's precedence >= current op's precedence
#            pop previous operator from operator stack
#            push previous operator onto output stack
#            continue
#        else
#            push current operator onto operator stack
#            break
# }
_parse_op:
	ldb($t0, token_types, TOKEN_IDX)
_parse_op_L1:
	beqz OPERATOR_IDX, _parse_op_done
	# get previous operator
	addi $t1, OPERATOR_IDX, -1
	ldb($t1, operator_stack, $t1)
	# get precedence of current and previous operator, and previous operator associativity
	ldb($t2, associativity, $t1) # previous associativity
	ldb($t3, precedence, $t1) # previous precedence
	ldb($t4, precedence, $t0) # current precedence
	beq $t2, OPA_RIGHT, _parse_op_right # if previous associativity == RIGHT
_parse_op_left:
	ble $t4, $t3, _parse_op_consume # if precendence of current operator <= previous operator, move previous operator
	b _parse_op_done # else push current operator
_parse_op_right:
	blt $t4, $t3, _parse_op_consume # if precendence of current operator <= previous operator, move previous operator
	b _parse_op_done # else push current operator
_parse_op_consume:
	# pop previous operator from operator stack
	popop($t1)
	# push previous operator onto output stack
	pushout($t1, $zero)
	# continue
	j _parse_op_L1
_parse_op_done:
	pushop($t0)
	# push current operator to operator stack and leave
	dispatch()
