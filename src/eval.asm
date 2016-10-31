.globl eval
.include "macros.h"
.include "error.h"
.include "params.h"
.include "lexer.h"
.data

.align 2
eval_values: .space MAX_EXPR_ARRAY_SZ
eval_types: .space MAX_EXPR_SZ
_eval_jmptbl: .word _eval_finish, _eval_varnum, _eval_varnum, _eval_add, _eval_sub, _eval_mul, _eval_div, _eval_ass, _eval_neg

.eqv EVAL_IDX $s0
.eqv OUTPUT_IDX $s1
.eqv ARG1_V $s2
.eqv ARG1_T $s3
.eqv ARG2_V $s4
.eqv ARG2_T $s5
.eqv CURR_V $a0
.eqv CURR_T $a1

.text

.macro pusheval(%r, %t)
	stw(%r, eval_values, EVAL_IDX)
	stb(%t, eval_types, EVAL_IDX)
	inc(EVAL_IDX, 1)
.end_macro

.macro popeval(%r, %t)
	dec(EVAL_IDX, 1)
	ldb(%t, eval_types, EVAL_IDX)
	ldw(%r, eval_values, EVAL_IDX)
.end_macro

.macro checkstackempty()
	bnez EVAL_IDX, _stackokay
	li $v0, ERR_MISFORMED_STATEMENT
	j _eval_leave
_stackokay:
.end_macro

.macro checktype(%value, %type)
	push($ra)
	move $a0, %value
	move $a1, %type
	jal checktype
	pop($ra)
	move %value, $v0
	move %type, $v1
.end_macro

.macro checknum(%value, %type)
	checktype(%value, %type)
	beq %type, TOK_NUM, _numokay
	li $v0, ERR_UNDEFINED_VAR
	j _eval_leave
_numokay:
.end_macro

.macro dispatch()
	inc(OUTPUT_IDX, 1)
	ldw(CURR_V, output_stack, OUTPUT_IDX)
	ldb(CURR_T, output_types, OUTPUT_IDX)
	ldw($t0, _eval_jmptbl, CURR_T)
	jr $t0
.end_macro


# reifies value to correct type
#
# @param a0: value
# @param a1: type
# @return v0: realvalue
# @return v1: realtype
#
# if number or undefined variable type and value remain the same
# if the type is variable and the variable is defined then return
# value associated with variable and type TOK_NUM
checktype:
	push($ra)
	# if number, return
	bne $a1, TOK_NUM, _checktype_L1
	j _checktype_issame
_checktype_L1:
	# if variable, test if defined
	#get beginning and end of variable name
	ldw($t0, var_begin, $a0)
	ldw($t1, var_end, $a0)
	# attempt to get associated value
	push2($a0, $a1)
	move $a0, $t0
	move $a1, $t1
	jal getvar
	pop2($a0, $a1)
	# check if defined (v0 == 0)
	bnez $v0, _checktype_issame
	# defined, return type number and associated value
	move $v0, $v1
	li $v1, TOK_NUM
	pop($ra)
	jr $ra
_checktype_issame:
	# not defined, is variable
	move $v0, $a0
	move $v1, $a1
	pop($ra)
	jr $ra


##################### EVALUATOR ENTRY #############################
# Evaluate given RPN expression
#
# @return v0: 0 indicates no error, else error and errorcode is the value
# @return v1: result of evaluation
eval:
	push4($ra, $s0, $s1, $s2)
	push5($s3, $s4, $s5, $a0, $a1)
	li EVAL_IDX, 0
	li OUTPUT_IDX, -1
	dispatch()
_eval_leave:
	pop5($s3, $s4, $s5, $a0, $a1)
	pop4($ra, $s0, $s1, $s2)
	jr $ra


# Perform final checks for validity of evaluation
_eval_finish:
	# if evaluation stack isn't only one value deep, error
	# value could be number or variable, but must be defined
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	# if after popping last value off stack, if stack isn't empty then error
	beqz EVAL_IDX, _eval_finish_okay
	li $v0, ERR_MISFORMED_STATEMENT
	j _eval_leave
_eval_finish_okay:
	li $v0, 0
	move $v1, ARG1_V
	j _eval_leave


# just push number or variable onto eval stack
# CURR_T and CURR_V hold necessary info
_eval_varnum:
	pusheval(CURR_V, CURR_T)
	dispatch()


# for all the arithmetic operators
# upon subroutine entry CURR_T adn CURR_V are the
# type and value of the top of the output stack.
# None of the arithmetic operator need this info,
# they only need to know what operation they are
# performing.
# ARG1_V and ARG1_T, and ARG2_V and ARG2_T are to
# hold the value and correct type of the elemnts
# used during the operation. If the type isn't
# correct, die.
#
# Each arithmetic operator must do the following to
# ensure the operation can be done
#
# 1: is the eval stack empty? If so, error
# 2: get an element from the top of the eval stack and put infor into ARG1_V/T
# 3. ensure the type is 'number' or if it's a variable, get it's associated value. If an undefined variable, error
# 4. Do steps 1-3 again for another value, and place into ARG2_V/T (if needed, 'neg' only needs 1)
# 5. Do the arithemtic operation on ARG1_V and ARG2_V, place the result into a temp reg
# 6. Push result back onto the top of the eval stack
# 7. Exit
_eval_add:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	checkstackempty()
	popeval(ARG2_V, ARG2_T)
	checknum(ARG2_V, ARG2_T)
	add $t0, ARG1_V, ARG2_V
	li $t1, TOK_NUM
	pusheval($t0, $t1)
	dispatch()


_eval_sub:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	checkstackempty()
	popeval(ARG2_V, ARG2_T)
	checknum(ARG2_V, ARG2_T)
	sub $t0, ARG2_V, ARG1_V
	li $t1, TOK_NUM
	pusheval($t0, $t1)
	dispatch()

	
_eval_mul:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	checkstackempty()
	popeval(ARG2_V, ARG2_T)
	checknum(ARG2_V, ARG2_T)
	mul $t0, ARG1_V, ARG2_V
	li $t1, TOK_NUM
	pusheval($t0, $t1)
	dispatch()

	
_eval_div:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	checkstackempty()
	popeval(ARG2_V, ARG2_T)
	checknum(ARG2_V, ARG2_T)
	bnez ARG1_V, _notdivbyzero
	li $v0, ERR_DIV_BY_ZERO
	j _eval_leave
_notdivbyzero:
	div $t0, ARG2_V, ARG1_V
	li $t1, TOK_NUM
	pusheval($t0, $t1)
	dispatch()


_eval_neg:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	neg $t0, ARG1_V
	li $t1, TOK_NUM
	pusheval($t0, $t1)
	dispatch()


# performs assignment of value to variable
#
# top of stack must be a number, second must be a variable
# if type checks work out, set variable equal to argument
# Finally, push the value back on top of the stack
_eval_ass:
	checkstackempty()
	popeval(ARG1_V, ARG1_T)
	checknum(ARG1_V, ARG1_T)
	checkstackempty()
	popeval(ARG2_V, ARG2_T)
	# is second argument variable?
	beq ARG2_T, TOK_VAR, _eval_ass_typeokay
	li $v0, ERR_ASSIGN_TO_NONVAR
	j _eval_leave
_eval_ass_typeokay:
	# setup and call setvar to set variable name equal to value
	ldw($a0, var_begin, ARG2_V)
	ldw($a1, var_end, ARG2_V)
	move $a2, ARG1_V
	jal setvar
	# finally, put assigned value back on stack
	pusheval(ARG1_V, ARG1_T)
	dispatch()
