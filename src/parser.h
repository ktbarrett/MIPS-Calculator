### OPERATOR PRECEDENCES ###
.eqv OPP_ADD 3
.eqv OPP_SUB 3
.eqv OPP_MUL 4
.eqv OPP_DIV 4
.eqv OPP_ASS 1
.eqv OPP_NEG 2
.eqv OPP_LPAR 0
# lpar precedence must be less than everything so nothing can pop it off the stack
# Ahhhh, the precedence of assignment. Having the assignment operator higher than 
# all other operators and lower than all other operators makes sense. If the precedence
# is larger, it grabs non-greedily; and if it's lower than everything it grabs
# greedily. However, making the precdence low creates an entirely different
# grammar, one that the current validator cannot prove valid. If one doesn't surround
# assignemnts in parentheses it fails to parse correctly. So, although the
# grammar is valid, it is not easily verifiable, so the assignemnt operator
# has a high precedence and to grab more greedily, use parentheses to surround
# the expression you to evaluate for the assignment.
#### ACTUALLY SCRATCH THAT
# people expect writing 'a = 12 - 9' to set a to 3, not 12
# this is an actual corner case, that has not been handled yet. This would require an
# addition to the validator, to ensure that the token preceding the variable
# preceding assignment operator is either the beginning of the expression, or
# a left parentheses. Fun stuff.

### OPERATOR ASSOCIATIVITY
.eqv OPA_LEFT 0
.eqv OPA_RIGHT 1
.eqv OPA_ADD OPA_LEFT
.eqv OPA_SUB OPA_LEFT
.eqv OPA_MUL OPA_LEFT
.eqv OPA_DIV OPA_LEFT
.eqv OPA_ASS OPA_RIGHT
.eqv OPA_NEG OPA_RIGHT
.eqv OPA_LPAR OPA_RIGHT
# lpar associativity must be right to keep from popping another lpar off the
# operator stack
