.globl error_messages printError
.include "macros.h"
.data

error: .asciiz "Error: "
err_unknownchar: .asciiz "Unkown character\n"
err_baddigit: .asciix "Poorly formed digit\n"

error_messages: .word 0 err_unknownchar err_baddigit

.text

# prints error message
# TODO other data
printError:
	writeString(error)
	ldw($t0, error_messages, $a0)
	writeStringReg($t0)
	jr $ra
