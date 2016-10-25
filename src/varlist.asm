
.globl getvar setvar initvarlist
.include "macros.h"
.data

.align 2
_varlist_ptr: .space 4
_varlist_end: .space 4

.text

# initializes varlist
initvarlist:
	push($a0)
	push($v0)
	li $v0, 9
	li $a0, 0
	syscall
	sw $v0, _varlist_ptr
	sw $v0, _varlist_end
	pop($v0)
	pop($a0)
	jr $ra

# Find Variable (non-extern)
#  finds list node with given variable name 
#
# @param a0: address of variable name
# @return v0: error (0 if no error, 1 if error)
# @return v1: address of variable node or undefined if not found
#
# caveat: if variable string isn't nul-terminated, the behavoir is undefined
#
# C(ish):
#    while (1) {
#        varlist_ptr = alignup(varlist_ptr);
#        if (varlist_ptr == varlist_end) return {1, ???};
#        varlist_ptr += 4;
#        if (strcmp(varlist_ptr, string)) return {0, varlist-4};
#        varlist_ptr += strlen(varlist_ptr)+1;
#    }
_findvar:
	# save
	push($ra)
	push($s0)
	push($s1)
	push($a0)
	push($a1)
	move $s1, $a0
	lw $a0, _varlist_ptr
	lw $s0, _varlist_end
_findvar_L1:
	# align
	li $a1, 4
	jal alignup
	move $a0, $v0
	# check if end
	beq $s0, $a0, _findvar_notfound
	# string compare
	addi $a0, $a0, 4
	move $a1, $s1
	jal strcmp
	# if match, found variable
	beq $zero, $v0, _findvar_found
	# else add strlen + 1(nul-term) to pointer
	jal strlen
	add $a0, $a0, $v0
	addi $a0, $a0, 1
	b _findvar_L1
_findvar_notfound:
	li $v0, 1
	b _findvar_exit
_findvar_found:
	li $v0, 0
	addi $v1, $a0, -4
_findvar_exit:	# reload
	pop($a1)
	pop($a0)
	pop($s1)
	pop($s0)
	pop($ra)
	jr $ra
	
# Get Variable
#  gets value associated with given variable name, returns an error
#  if the variable isn't defined
#
# @param a0: address of variable name
# @return v0: error (0 if no error, 1 if error)
# @return v1: value associated with variable or undefined if not found
#
# caveat: if variable string isn't nul-terminated, the behavoir is undefined
#
# C(ish):
#    {err, loc} = _findvar(string);
#    if (!err) return {err, *loc};
#    return {err, ???}
getvar:
	push($ra)
	jal _findvar
	bne $v0, $zero, _getvar_L1
	lw $v1, ($v1)
_getvar_L1:
	pop($ra)
	jr $ra

# Set Variable
#  sets variable to new value if it exists, if it doesn't
#  it allocates more space and appends it to the list
#
# @param a0: address of variable string
# @param a1: new value of variable
#
# caveat: if variable string isn't nul-terminated, the behavoir is undefined
#
# C(ish):
#    {err, loc} = _findvar(string);
#    if (err) {
#        loc = malloc(alignup(strlen(string)+5));
#        strcpy(loc+4, string);
#    }
#    *loc = value;
#
setvar: # save
	push($ra)
	push($a1)
	jal _findvar
	beq $v0, $zero, _setvar_L1
	## alloc new space
	push($a0)
	# get string length
	jal strlen
	# add space for nul-terminator and int
	addi $a0, $v0, 5
	# align up to word boundary
	li $a1, 4
	jal alignup
	# sbrk - allocate memory
	move $a0, $v0
	li $v0, 9
	syscall
	# change end pointer
	add $a0, $a0, $v0
	sw $a0, _varlist_end
	# strcpy into list
	addi $a0, $v0, 4
	pop($a1)
	jal strcpy
	move $a0, $a1 # src back to $a0
	move $v1, $v0
_setvar_L1: # reload
	pop($a1)
	pop($ra)
	sw $a1, ($v1) # save new integer in variable node
	jr $ra
