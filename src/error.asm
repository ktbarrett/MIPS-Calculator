.globl error_messages printError
.include "macros.h"
.data

error: .asciiz "Error: "
err_unknownchar: .asciiz "Unknown character\n"
err_baddigit: .asciiz "Poorly formed digit\n"
err_missinglpar: .asciiz "Mismatched parens; missing left paren\n"
err_missingrpar: .asciiz "Mismatched parens; missing right paren\n"

error_messages: .word 0 err_unknownchar err_baddigit, err_missinglpar, err_missingrpar

.text

# prints error message
# TODO other data
printError:
	writeString(error)
	ldw($t0, error_messages, $a0)
	writeStringReg($t0)
	jr $ra
