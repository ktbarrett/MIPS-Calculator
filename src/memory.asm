.globl alignup memcpy
.data

.text

# Align Address Upwards
#
# @param a0: address to align
# @param a1: alignment
# @return v0: aligned up address
# 
# caveats: only works on power of 2 alignment
# C:
#    addr = (addr + (alignment - 1)) & -alignment;
alignup:
	addi $t0, $a1, -1
	neg $t1, $a1
	add $t0, $a0, $t0
	and $v0, $t0, $t1
	jr $ra

# Copy Memory
#
# @param a0: source memory buffer
# @param a1: destination memory buffer
# @param a2: length in bytes to copy
# 
# caveats: buffer overruns are undefined
#
# C:
#    char *end = src + len;
#    while (src != end)
#        *dest++ = *src++ 
memcpy:
	move $t0, $a0
	move $t1, $a1
	add $t2, $t0, $a2
	beq $a2, $zero, _memcpy_L2
_memcpy_L1:
	lb $t3, ($t0)
	sb $t3, ($t1)
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	bne $t0, $t2 _memcpy_L1
_memcpy_L2:
	jr $ra
