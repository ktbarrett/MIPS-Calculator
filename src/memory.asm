.globl alignup
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
