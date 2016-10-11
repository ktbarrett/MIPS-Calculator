
.include "memory.asm"
.include "macros.asm"

# String copy
#
# @param a0: nul-terminated string source
# @param a1: destination buffer
.data

.text

#
# caveat: If the source string isn't nul-terminated beavoir is undefined.
#    Additionally, buffer overruns are undefined.
#
# C:
#    size_t len = strlen(str);
#    memcpy(dest, src, len);
strcpy:
	pushw($ra)
	jal strlen
	move $a2, $v0
	jal memcpy
	popw($ra)
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
# @return v0: 0 if no match, 1 otherwise
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
	