.globl eval
.include "macros.h"
.include "parser.h"
.include "error.h"
.data

_eval_jmptbl: .word _eval_add, _eval_sub, _eval_mul, _eval_div, _eval_ass, _eval_neg

.eqv OUTPUT_STACK_IDX $s1
.eqv OPERATOR_STACK_IDX $s2

.text

# Evaluate given RPN expression
eval:


_eval_add:

	
_eval_sub:

	
_eval_mul:

	
_eval_div:


_eval_ass:


_eval_neg:

