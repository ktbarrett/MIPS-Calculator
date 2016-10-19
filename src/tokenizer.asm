.globl lexer token_starts token_ends tokens
.include "params.h"
.include "macros.asm"
.data

.align 2
token_starts: .space TOKEN_ARRAYS_SZ
token_ends: .space TOKEN_ARRAYS_SZ
tokens: .space TOKEN_ARRAYS_SZ
_lexer_errormsg: .asciiz "Lexer Error"

.text

# clears token arrays
clearlex:
	push($ra)
	push($a0)
	push($a1)
	push($a2)
	push($a3)
	la $a0, token_starts
	move $a1, $zero
	li $a2, TOKEN_ARRAYS_SZ
	li $a3, 1
	jal memset
	la $a0, token_ends
	jal memset
	pop($a3)
	pop($a2)
	pop($a1)
	pop($a0)
	pop($ra)
	jr $ra


# Tokenizes input string based upon lexing rules
#
# @param a0: address of string to lex
# @return v0: 0 on good lex, 1 if error
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
	addi $s0, $a0, -1
	move $s1, $zero
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
	jal isend
	beq $v0, $zero, _lexer_error
	li $t0, TOK_END
	sw $t0, tokens($s1)
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
	
# isoperator() -> capture, break
_lexer_operator:
	push($ra)
	sw $s0, token_starts($s1)
	addi $t0, $s0, 1
	sw $t0, token_ends($s1)
	li $t0, TOK_OP
	sw $t0, tokens($s1)
	addi $s1, $s1, 4
	pop($ra)
	jr $ra


#    isdigit() -> consume isdigit(), isspace() != 1 || isoperator() != 1 -> parse error
_lexer_number:
	push($ra)
	sw $s0, token_starts($s1)
	addi $s0, $s0, 1
	lb $a0, ($s0)
_lexer_number_L1:
	jal isdigit
	beq $zero, $v0, _lexer_number_L2
	addi $s0, $s0, 1
	lb $a0, ($s0)
	j _lexer_number_L1
_lexer_number_L2:
	sw $s0, token_ends($s1)
	jal isspace
	bne $v0, $zero, _lexer_number_okay
	jal isoperator
	bne $v0, $zero, _lexer_number_okay
	pop($ra)
	j _lexer_error
_lexer_number_okay:
	addi $s0, $s0, -1
	li $t0, TOK_NUM
	sw $t0, tokens($s1)
	addi $s1, $s1, 4
	pop($ra)
	jr $ra

#    isvarstart() -> consume isvarname()
_lexer_variable:
	push($ra)
	sw $s0, token_starts($s1)
	addi $s0, $s0, 1
	lb $a0, ($s0)
_lexer_variable_L1:
	jal isvarname
	beq $zero, $v0, _lexer_variable_L2
	addi $s0, $s0, 1
	lb $a0, ($s0)
	j _lexer_variable_L1
_lexer_variable_L2:
	sw $s0, token_ends($s1)
	li $t0, TOK_VAR
	sw $t0, tokens($s1)
	addi $s1, $s1, 4
	addi $s0, $s0, -1
	pop($ra)
	jr $ra
