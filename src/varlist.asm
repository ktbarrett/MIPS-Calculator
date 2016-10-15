#.include "strings.asm"
#.include "memory.asm"
#.include "macros.asm"

.data

.align 2
_varlist_ptr: .space 4
_varlist_end: .space 4

.text

j _testvarlist

# initializes varlist
.macro initvarlist()
	li $v0, 9
	li $a0, 0
	syscall
	sw $v0, _varlist_ptr
	sw $v0, _varlist_end
.end_macro

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
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	sw $s0, 12($sp)
	sw $s1, 8($sp)
	sw $a0, 4($sp)
	sw $a1, 0($sp)
	lw $a0, _varlist_ptr
	move $s1, $a0
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
	bne $zero, $v0, _findvar_found
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
	move $a0, $s1
	lw $a1, 0($sp)
	lw $a0, 4($sp)
	lw $s1, 8($sp)
	lw $s0, 12($sp)
	lw $ra, 16($sp)
	addi $sp, $sp, 20
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
	beq $v0, $zero, _getvar_L1
	lw $v0, ($v0)
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
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $a1, 0($sp)
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
	move $v1, $v0 # save pointer for saving integer
	# strcpy into list
	addi $a1, $v0, 4
	pop($a0)
	jal strcpy
	move $a0, $a1
_setvar_L1: # reload
	lw $a1, 0($sp)
	sw $a1, ($v1) # save new integer in variable node
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
_testvarlist:

	writeString(testvarlist)
	initvarlist()
	la $a0, test
	lw $a1, testasnum
	jal setvar
	jal getvar
	la $s0, okay
	la $s1, notokay
	cmovne($s0, $s1, $v0, $a0)
	writeStringReg($s0)