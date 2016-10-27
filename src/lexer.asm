.globl lexer token_values token_ends token_types
.include "params.h"
.include "macros.h"
.include "error.h"
.data

.align 2
token_values: .space MAX_EXPR_ARRAY_SZ
token_ends: .space MAX_EXPR_ARRAY_SZ
token_types: .space MAX_EXPR_ARRAY_SZ

.eqv STRING_PTR $s0
.eqv TOKEN_IDX $s1
.eqv THIS_CHAR $a0

.text

_lexer_whichop:
	li $v0, TOK_ASS
	cmoveqi($v0, TOK_ADD, THIS_CHAR, CHR_ADD)
	cmoveqi($v0, TOK_SUB, THIS_CHAR, CHR_SUB)
	cmoveqi($v0, TOK_MUL, THIS_CHAR, CHR_MUL)
	cmoveqi($v0, TOK_DIV, THIS_CHAR, CHR_DIV)
	jr $ra

# Tokenizes input string based upon lexing rules
#
# # @return v0: 0 on good lex, otherwise error
#
# Rules:
#    isspace() -> break, consume space
#    isoperator() -> capture, break
#    isdigit() -> consume isdigit(), isalpha() == 1 -> parse error
#    isvarstart() -> consume isvarname()
#    isend() -> stop
lexer:
	push4($ra, $s0, $s1, $a0)
	la STRING_PTR, inputbuf
	dec(STRING_PTR, 1) # to offset inc at beginning
	move TOKEN_IDX, $zero # token array index
_lexer_loop:
	# get next char
	inc(STRING_PTR, 1)
	lb THIS_CHAR, 0(STRING_PTR)
	# while (isspace())
	jal isspace
	beq $v0, 1, _lexer_loop
	# if operator
	jal isoperator
	bne $v0, 1, _lexer_notoperator
	j _lexer_operator
_lexer_notoperator:
	# if digit
	jal isdigit
	bne $v0, 1, _lexer_notnumber
	j _lexer_number
_lexer_notnumber:
	# if varname
	jal isvarstart
	bne $v0, 1, _lexer_notvar
	j _lexer_variable
_lexer_notvar:
	# if paren
	jal isparen
	bne $v0, 1, _lexer_notparens
	j _lexer_paren
_lexer_notparens:
	# is end or shits bork
	jal isend
	bne $v0, 1, _lexer_notend
	j _lexer_end
_lexer_notend:
	li $v0, ERR_UNKNOWNCHAR
_lexer_leave:
	pop4($ra, $s0, $s1, $a0)
	jr $ra

# isend() -> capture, leave
# push end onto token stack and stop
_lexer_end:
	li $t0, TOK_END
	stw($t0, token_types, TOKEN_IDX)
	inc(TOKEN_IDX, 1)
	li $v0, 0 # ensure valid lex is achieved
	j _lexer_leave

# isparen() -> capture, break
# push appropiate token onto token stack and continue
_lexer_paren:
	li $t0, TOK_LPAR
	cmoveqi($t0, TOK_RPAR, THIS_CHAR, CHR_RPAR)
	stw($t0, token_types, TOKEN_IDX)
	inc(TOKEN_IDX, 1)
	j _lexer_loop
	
	
# isoperator() -> capture, break
# push appropriate token value onto type stack and continue
_lexer_operator:
	jal _lexer_whichop
	stw($v0, token_types, TOKEN_IDX)
	inc(TOKEN_IDX, 1)
	j _lexer_loop


# isdigit() -> consume isdigit(), isspace() != 1 || isoperator() != 1 -> parse error
# capture as many digits as possible, run str2num on the captured number
# place TOK_NUM in token_types and the number value in token_values
# if number ends with invalid character return error ERR_BADDIGIT
# ensure STRING_PTR points to last digit after completion
_lexer_number:
	# save string start
	push(STRING_PTR)
	# while next character is digit ( while(isdigit(str++)) )
_lexer_number_L1:
	inc(STRING_PTR, 1)
	lb THIS_CHAR, (STRING_PTR)
	jal isdigit
	beq $v0, 1, _lexer_number_L1
	# determine if next character (in THIS_CHAR) is valid to follow digit
	# valid: space or operator
	jal isoperator
	move $t1, $v0
	jal isspace
	or $t1, $t1, $v0 # if either $t1 should not be 0
	bnez $t1, _lexer_number_valid
	# not an operator or a space
	li $v0, ERR_BADDIGIT
	pop(STRING_PTR) # to keep stack maintained
	j _lexer_leave
_lexer_number_valid: # valid digit
	move $a1, STRING_PTR # num end is one past last digit
	pop($a0) # pop saved beginning string pointer into a0 for str2num
	jal str2num
	li $t0, TOK_NUM
	stw($t0, token_types, TOKEN_IDX)
	stw($v0, token_values, TOKEN_IDX)
	inc(TOKEN_IDX, 1)
	# decrement string pointer to last digit to continue
	dec(STRING_PTR, 1)
	# reloading THIS_CHAR is done by lexer_loop 
	j _lexer_loop

# isvarstart() -> consume isvarname()
# capture as many valid characters as the name of a variable as possible
# store the start of teh variable name in token_values, the end of the variable
# in token_ends, and TOK_VAR in token_types
_lexer_variable:
	# save string start in lexer_values for later use by the parser
	stw(STRING_PTR, token_values, TOKEN_IDX)
	# while next character is valid in variable name ( while(isvarname(str++)) )
_lexer_variable_L1:
	inc(STRING_PTR, 1)
	lb THIS_CHAR, (STRING_PTR)
	jal isvarname
	beq $v0, 1, _lexer_variable_L1
	# save variable string end and type
	stw(STRING_PTR, token_ends, TOKEN_IDX)
	li $t0, TOK_VAR
	stw($t0, token_types, TOKEN_IDX)
	inc(TOKEN_IDX, 1) # next token
	# decrement string pointer to last digit to continue
	dec(STRING_PTR, 1)
	# reloading THIS_CHAR is done by lexer_loop 
	j _lexer_loop
