# calculator general paramters (size of buffers)
.eqv MAX_EXPR_SZ 64
.eqv MAX_EXPR_ARRAY_SZ 256 # sizeof(ptr)*MAX_EXPR_SZ
.eqv MAX_VAR_PER_EXPR 128 # a=b=c... means ((MAX_EXPR_SZ + 1)//2)*sizeof(ptr)
