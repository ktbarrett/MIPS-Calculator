.globl eval
.include "macros.h"
.include "params.h"
.include "stackops.h"
.data

precedence: .word OPP_ADD, OPP_SUB, OPP_MUL, OPP_DIV, OPP_ASS
associativity: .word OPA_ADD, OPA_SUB, OPA_MUL, OPA_DIV, OPA_ASS
.align 2
setjmpbuf: .space 116 # because I'm so fucking done

.eqv OUTPUT_STACK_IDX $s0
.eqv OPERATOR_STACK_IDX $s1

.text

# Evaluate given intermediate expression
#
# Uses current output and operator stack statesm, argument, and 
# operator precedence and associativity rules to determine
# how operator will modify current state
#
eval:
	push($s0)
	push($s1)
	push($a0)
	li $v0, 0
	jal setjmp
	bne $zero, $v0, _eval_error
	li $t0, TOK_LPAR
	beq $a0, $t0, _eval_notlpar
	stackadd(operator_stack, OPERATOR_STACK_IDX, $t0)
	j _eval_leave
_eval_notlpar:
	li $t0, TOK_RPAR
	beq $a0, $t0, _eval_notrpar
	jal evalit
	bne $zero, $v0, _eval_error
	j _eval_leave
_eval_notrpar:
	li $t0, TOK_END
	beq $a0, $t0, _eval_notend
	jal evalit
	bne $zero, $v0, _eval_error
	li $t0, 1 # ensure only one value in stack
	bne OUTPUT_STACK_IDX, $t0, _eval_error
	j _eval_leave
_eval_notend:
	li $t0, TOK_NEG
	beq $a0, $t0, _eval_notneg
	stackadd(operator_stack, OPERATOR_STACK_IDX, $t0)
	j _eval_leave
_eval_notneg:
	jal handleop
_eval_leave:
	pop($a0)
	pop($s1)
	pop($s0)
	jr $ra
	
_eval_error:
	la $a0, setjmpbuf
	li $a1, 1
	j longjmp

.data

jmptbl: .word _eval_add, _eval_sub, _eval_mul, _eval_div, _eval_neg

.text


# evaluate until either a left paren or the end of the operator stack, whichever is first 
evalit:
	# pop operator off stack, do operation, check for left paren or index == 0
	push($ra)
_evalit_L1:
	li $t0, 1
	beq OPERATOR_STACK_IDX, $t0, _evalit_done # if operator stack is empty, finish
	stackrem(operator_stack, OPERATOR_STACK_IDX, $t1)
	li $t0, TOK_LPAR
	beq $t0, $t1, _evalit_done # if op is left paren, finish
	lw $t0, jmptbl($t1) # otherwise do the operation
	jalr $t0
	j _evalit_L1
_evalit_done:
	pop($ra)
	jr $ra
	
# if stack is empty, push op
# while (1) {
#   $t0 = curr prec
#   $t1 = top of stack prec
#   $t2 = curr ass
#   if $t3 == RIGHT
#     if $t0 < $t1
#       eval once
#     else
#       push op
#   else //$t3 == LEFT
#     if $t0 <= $t1
#       eval once
#     else
#       push op
# }
handleop:
	bne $zero, OPERATOR_STACK_IDX, _handleop_L1
	stackadd(operator_stack, OPERATOR_STACK_IDX, $a0)
	b _handleop_done
_handleop_L1:
	lw $t0, precedence($a0)
	stackrem(operator_stack, OPERATOR_STACK_IDX, $t3)
	lw $t1, precedence($t3)
	lw $t2, associativity($a0)
	li $t4, OPA_RIGHT
	bne $t4, $t3, _handleop_lefta
	bge $t0, $t1, _handleop_noeval
	b _handleop_eval
_handleop_lefta:
	bgt $t0, $t1, _handleop_noeval
	b _handleop_eval
_handleop_done:
	jr $ra
_handleop_eval:
	lw $t3, jmptbl($t3)
	jalr $t3
	j _handleop_L1
_handleop_noeval:
	
	j _handleop_L1

.macro checktype(%r, %type)
	li $t8, %type
	bne $t8, %type, _eval_error
.end_macro

.macro checkstack(%ind)
	beq $zero, %ind, _eval_error
.end_macro

_eval_add:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t1)
	add $t0, $t0, $t1
	stackadd(output_stack, OUTPUT_STACK_IDX, $t0)
	jr $ra
	
_eval_sub:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t1)
	sub $t0, $t1, $t0
	stackadd(output_stack, OUTPUT_STACK_IDX, $t0)
	jr $ra
	
_eval_mul:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t1)
	mul $t0, $t0, $t1
	stackadd(output_stack, OUTPUT_STACK_IDX, $t0)
	jr $ra
	
_eval_div:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t1)
	div $t0, $t1, $t0
	stackadd(output_stack, OUTPUT_STACK_IDX, $t0)
	jr $ra

_eval_ass:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_VAR)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t1)
	push($s2)
	push($s3)
	lw $a0, token_values($t1) # load variable start pointer
	lw $s3, token_ends($t1) # load variable end pointer
	lb $s2, ($s3) # save old end value
	sb $zero, ($s2) # make end nul-terminator
	move $a1, $t0
	jal setvar # set variable to value
	bne $v0, $zero, _eval_error
	sb $s2, ($s3) # reset end
	pop($s3)
	pop($s2)
	jr $ra

_eval_neg:
	checkstack(OUTPUT_STACK_IDX)
	stacktop(output_types, OUTPUT_STACK_IDX, $t2)
	checktype($t2, TOK_NUM)
	stackrem(output_stack, OUTPUT_STACK_IDX, $t0)
	neg $t0, $t0
	stackadd(output_stack, OUTPUT_STACK_IDX, $t0)
	jr $ra
