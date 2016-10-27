.globl strcpy strlen strcmp str2num
.include "macros.h"
.data

.text

#
# caveat: If the source string isn't nul-terminated beavoir is undefined.
#    Additionally, buffer overruns are undefined.
#
# C:
#    while ((c = src++) != '\0') dest++ = c;
strcpy:
	move $t0, $a0
	move $t1, $a1
_strcpy_L1:
	lb $t2, ($t1)
	sb $t2, ($t0)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	bne $t2, $zero _strcpy_L1
	jr $ra


# String Length
#
# @param a0: nul-terminated string
# @returns v0: length of the string in bytes
#
# caveat: If the string isn't nul-terminated behavior is undefined.
#
# C:
#    int c, i = 0;
#    while ((c = str++) != '\0') i++;
#    return i;
strlen:
	move $t0, $a0
_strlen_L1:
	lb $t1, ($t0)
	addi $t0, $t0, 1
	bne $zero, $t1 _strlen_L1
	sub $v0, $t0, $a0
	addi $v0, $v0, -1
	jr $ra


# String Compare
#
# @param a0: string 1
# @param a1: string 2
# @return v0: 0 if match, 1 otherwise
#
# caveat: If the string isn't nul-terminated, behavior is undefined.
#
# C:
#    int c, out;
#    while ((c = str1++) != '\0' && (out = c == str2++))
#    return out;
strcmp:
	addi $t0, $a0, -1
	addi $t1, $a1, -1
	move $v0, $zero
_strcmp_L1:
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	lb $t2, ($t0)
	beq $t2, $zero, _strcmp_L2
	lb $t3, ($t1)
	beq $t2, $t3, _strcmp_L1
	addi $v0, $v0, 1
_strcmp_L2:
	jr $ra


# Converts string to integer
#
# @param a0: pointer to string to convert
# @param a1: string end
# @return v0: number converted as word-sized int
#
# C:
#    int num = 0
#    while (isdigit((c = str++)) && str <= str_end)
#        num = num * 10 + c - '0';
str2num:
	# enter
	push4($ra, $a0, $s0, $s1)
	# setup variables
	li $s1, 0
	move $s0, $a0
	j _str2num_L1cond
_str2num_L1:
	# num = num * 10 + digit - '0'
	li $t0, 10
	mul $s1, $s1, $t0
	addi $t0, $a0, -48 # '0'
	add $s1, $s1, $t0
	# condition, c = str++, if !isdigit(c) leave
_str2num_L1cond:
	lb $a0, ($s0)
	addi $s0, $s0, 1
	jal isdigit
	bgt $s0, $a1, _str2num_done
	bne $v0, $zero, _str2num_L1
_str2num_done:
	# leave
	move $v0, $s1
	pop4($ra, $a0, $s0, $s1)
	jr $ra

