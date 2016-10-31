### OPERATOR PRECEDENCES ###
.eqv OPP_ADD 1
.eqv OPP_SUB 1
.eqv OPP_MUL 2
.eqv OPP_DIV 2
.eqv OPP_ASS 3
.eqv OPP_NEG 0
.eqv OPP_LPAR 4
# lpar precedence must be greater than everything so it doesn't cause anything
# to be popped off operator stack

### OPERATOR ASSOCIATIVITY
.eqv OPA_LEFT 0
.eqv OPA_RIGHT 1
.eqv OPA_ADD OPA_LEFT
.eqv OPA_SUB OPA_LEFT
.eqv OPA_MUL OPA_LEFT
.eqv OPA_DIV OPA_LEFT
.eqv OPA_ASS OPA_RIGHT
.eqv OPA_NEG OPA_LEFT
.eqv OPA_LPAR OPA_RIGHT
# lpar associativity must be right to keep from popping another lpar off the
# operator stack