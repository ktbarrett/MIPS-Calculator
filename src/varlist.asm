.globl getvar setvar initvarlist
.include "macros.h"
.data

.align 2
_varlist_ptr: .space 4
_varlist_end: .space 4
_varlist_initialized: .byte 1

.text

.macro initialize()
	lb $t8, _varlist_initialized
	beqz $t8, _varlist_initialized_okay
	jal initvarlist
	sb $zero, _varlist_initialized
_varlist_initialized_okay:
.end_macro

# initializes varlist
initvarlist:
	push2($a0, $v0)
	li $v0, 9
	li $a0, 0
	syscall
	sw $v0, _varlist_ptr
	sw $v0, _varlist_end
	pop2($a0, $v0)
	jr $ra

# Find Variable (non-extern)
#  finds list node with given variable name 
#
# @param a0: address of variable name
# @param a1: end pointer of variable name
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
.eqv VARLIST_PTR $a0
.eqv VARLIST_END $s0
_findvar:
	# save
	push5($ra, $s0, $s1, $a0, $a1)
	move $s1, $a0 # save address of variable name
	lw VARLIST_PTR, _varlist_ptr
	lw VARLIST_END, _varlist_end
_findvar_L1:
	# check if end
	beq VARLIST_PTR, VARLIST_END, _findvar_notfound
	# string compare
	addi VARLIST_PTR, VARLIST_PTR, 4
	move $a1, $s1 # save variable name start address
	jal strcmp
	# if match, found variable
	beq $zero, $v0, _findvar_found
	# else add strlen(VARLIST_PTR) + 1(for nul-term) to pointer
	jal strlen
	add $a0, $a0, $v0
	addi $a0, $a0, 1
	# align up to next node
	li $a1, 4
	jal alignup
	move VARLIST_PTR, $v0
	b _findvar_L1
_findvar_notfound:
	li $v0, 1
	b _findvar_exit
_findvar_found:
	li $v0, 0
	addi $v1, VARLIST_PTR, -4 # returns beginning of node
_findvar_exit:	# reload
	pop5($ra, $s0, $s1, $a0, $a1)
	jr $ra
	
# Get Variable
#  gets value associated with given variable name, returns an error
#  if the variable isn't defined
#
# @param a0: address of variable name
# @param a1: end pointer of variable name
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
	initialize()
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
# @param a1: end pointer of variable name
# @param a2: new value of variable
#
# caveat: if variable string isn't nul-terminated, the behavior is undefined
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
	push2($ra, $v0)
	initialize()
	jal _findvar
	beqz $v0, _setvar_found
	## alloc new space
	# get string length
	sub $t0, $a1, $a0
	# add space for nul-terminator and int
	addi $t0, $t0, 5
	# align up to word boundary
	push2($a0, $a1)
	move $a0, $t0
	li $a1, 4
	jal alignup
	pop2($a0, $a1)
	# sbrk - allocate memory
	allocate($t0, $v0)
	# change varlist end pointer
	lw $t1, _varlist_end
	add $t1, $t1, $v0
	sw $t1, _varlist_end
	# save new integer in variable node
	sw $a2, ($t0)
	# memcpy variable name into list
	push3($a0, $a1, $a2)
	sub $a2, $a1, $a0 # string length
	move $a1, $a0 # variable name begin pointer
	addi $a0, $t0, 4 # load string begin for node (+4 byte offset because beginning int)
	jal memcpy
	# store nul-terminator at the end for safety
	add $t0, $a0, $a2
	sb $zero, ($t0)
	pop3($a0, $a1, $a2)
	j _setvar_leave
_setvar_found:
	sw $a2, ($v1)
_setvar_leave:
	pop2($ra, $v0)
	jr $ra
