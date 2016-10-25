.globl lexer token_values token_ends token_types
.include "params.h"
.include "macros.h"
.data

.align 2
token_values: .space MAX_EXPR_ARRAY_SZ
token_ends: .space MAX_EXPR_ARRAY_SZ
token_types: .space MAX_EXPR_ARRAY_SZ

.text

_lexer_whichop:
	li $v0, TOK_ASS
	li $t8, TOK_ADD
	li $t1, CHR_ADD
	cmoveq($v0, $t8, $a0, $t1)
	li $t8, TOK_SUB
	li $t1, CHR_SUB
	cmoveq($v0, $t8, $a0, $t1)
	li $t8, TOK_MUL
	li $t1, CHR_MUL
	cmoveq($v0, $t8, $a0, $t1)
	li $t8, TOK_DIV
	li $t1, CHR_DIV
	cmoveq($v0, $t8, $a0, $t1)
	jr $ra


# Tokenizes input string based upon lexing rules
#
# # @return v0: 0 on good lex, 1 if error
#
# Rules:
#    isspace() -> break, consume space
#    isoperator() -> capture, break
#    isdigit() -> consume isdigit(), isalpha() == 1 -> parse error
#    isvarstart() -> consume isvarname()
#    isend() -> stop
lexer:
	# s0 string to lex
	# a0 character from string
	# s1 index of token arrays
	push($ra)
	push($s0)
	push($s1)
	push($a0)
	la $s0, inputbuf
	addi $s0, $s0, -1 # to offset addition at beginning of loop
	move $s1, $zero # token array index
_lexer_loop:
	addi $s0, $s0, 1
	lb $a0, ($s0)
	# while (isspace())
	jal isspace
	bne $v0, $zero, _lexer_loop
	# if operator
	jal isoperator
	beq $v0, $zero, _lexer_notoperator
	jal _lexer_operator
	j _lexer_loop
_lexer_notoperator:
	# if digit
	jal isdigit
	beq $v0, $zero, _lexer_notnumber
	jal _lexer_number
	j _lexer_loop
_lexer_notnumber:
	# if varname
	jal isvarstart
	beq $v0, $zero, _lexer_notvar
	jal _lexer_variable
	j _lexer_loop
_lexer_notvar:
	# if paren
	li $t0, CHR_LPAR
	seq $t1, $a0, $t0
	li $t0 CHR_RPAR
	seq $t1, $a0, $t0
	beq $zero, $t1, _lexer_notparens
	jal _lexer_paren
	j _lexer_loop
_lexer_notparens:
	# is end or shits bork
	jal isend
	beq $v0, $zero, _lexer_error
	li $t0, TOK_END
	sw $t0, token_types($s1)
	move $v0, $zero # done, load okay and leave
	j _lexer_leave
_lexer_error:
	li $v0, 1
_lexer_leave:
	pop($a0)
	pop($s1)
	pop($s0)
	pop($ra)
	jr $ra

# is paren
_lexer_paren:
	li $t0, CHR_LPAR
	li $t1, TOK_LPAR
	li $t2, TOK_RPAR
	cmovne($t1, $t2, $a0, $t0)
	sw $t1, token_types($s1)
	addi $s1, $s1, 4
	jr $ra
	
	
# isoperator() -> capture, break
_lexer_operator:
	push($ra)
	jal _lexer_whichop
	sw $v0, token_types($s1)
	addi $s1, $s1, 4
	pop($ra)
	jr $ra


#    isdigit() -> consume isdigit(), isspace() != 1 || isoperator() != 1 -> parse error
_lexer_number:
	push($ra)
	push($s2)
	move $s2, $s0 # save beginning of string
	addi $s0, $s0, 1
	lb $a0, ($s0)
_lexer_number_L1:
	jal isdigit # grab isdigit()
	beq $zero, $v0, _lexer_number_L2
	addi $s0, $s0, 1
	lb $a0, ($s0)
	j _lexer_number_L1
_lexer_number_L2:
	# next operator must be a space or operator
	jal isspace
	bne $v0, $zero, _lexer_number_okay
	jal isoperator
	bne $v0, $zero, _lexer_number_okay
	pop($ra)
	j _lexer_error # if it isn't, error
_lexer_number_okay:
	li $t0, TOK_NUM
	sw $t0, token_types($s1)
	move $a0, $s2
	jal str2num # convert number and save
	sw $v0, token_values($s1)
	addi $s1, $s1, 4
	pop($s2)
	pop($ra)
	jr $ra

#    isvarstart() -> consume isvarname()
_lexer_variable:
	push($ra)
	# store start of variable 
	sw $s0, token_values($s1)
	addi $s0, $s0, 1
	lb $a0, ($s0)
_lexer_variable_L1:
	jal isvarname # grab everything up to a space or operator, etc.
	beq $zero, $v0, _lexer_variable_L2
	addi $s0, $s0, 1
	lb $a0, ($s0)
	j _lexer_variable_L1
_lexer_variable_L2:
	# store the end of the variable name and type
	sw $s0, token_ends($s1)
	li $t0, TOK_VAR
	sw $t0, token_types($s1)
	addi $s1, $s1, 4
	addi $s0, $s0, -1 # backup to end of variable
	pop($ra)
	jr $ra
