.globl validater
.include "macros.h"
.include "lexer.h"
.include "error.h"
.data

# validity matrix generated with python script
_validity_matrix: .byte 0x0 0xc8 0x63 0x3e 0x3d 0xe6 0x31 0x8f 0x79 0xcc 0x63 0x6 0xf2 0x58 0x1e 0x1
.eqv _validity_matrix_R 11
.eqv _validity_matrix_C 11

.eqv TOK_ARR_IDX $s0
.eqv CURR_TOK $a0
.eqv PREV_TOK $a1

.text

# index validity bit matrix using given indexes
#
# @param a1: row index
# @param a0: column index
# @return v0: 0 if bit at the index is set, 1 otherwise 
bitindexmatrix:
	# scale row index by number of columns
	li $t0, _validity_matrix_C
	mul $t0, $a1, $t0
	# add column index
	add $t0, $t0, $a0 # t0 is bit index
	# index byte
	srl $t1, $t0, 3
	andi $t2, $t0, 7
	lb $t0, _validity_matrix($t1)
	srlv $t0, $t0, $t2
	andi $v0, $t0, 1
	xori $v0, $v0, 1
	jr $ra

# perform validation on tokenized string
#
# @return v0: 0 if no error, error otherwise
validater:
	push4($ra, $s0, $a1, $a0)
	li PREV_TOK, 0
	li TOK_ARR_IDX, 0
	ldb(CURR_TOK, token_types, TOK_ARR_IDX)
_validate_L1:
	beq CURR_TOK, TOK_END, _validate_L2
	inc(TOK_ARR_IDX, 1)
	move PREV_TOK, CURR_TOK
	ldb(CURR_TOK, token_types, TOK_ARR_IDX)
	bne CURR_TOK, TOK_ASS, _validate_assignokay
	# if assignment, check if index is 1 (assignment as beginning), or if two tokens previous is left paren
	beq TOK_ARR_IDX, 1, _validate_assignokay
	addi $t0, TOK_ARR_IDX, -2
	ldb($t1, token_types, $t0)
	bne $t1, TOK_LPAR, _validate_error
_validate_assignokay:
	jal bitindexmatrix
	beqz $v0, _validate_L1
_validate_error:
	li $v0, ERR_MISFORMED_STATEMENT
_validate_L2:
	pop4($ra, $s0, $a1, $a0)
	jr $ra
