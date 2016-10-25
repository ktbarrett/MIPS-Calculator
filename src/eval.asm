.globl eval
.include "macros.h"
.include "params.h"
.data

precedence: .word OPP_ADD, OPP_SUB, OPP_MUL, OPP_DIV, OPP_ASS
associativity: .word OPA_ADD, OPA_SUB, OPA_MUL, OPA_DIV, OPA_ASS

.text

# Evaluate given intermediate expression
#
# Uses current output and operator stack statesm, argument, and 
# operator precedence and associativity rules to determine
# how operator will modify current state
#
eval:
	