.globl alignup memcpy memset
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
# @param a0: destination memory buffer
# @param a1: source memory buffer
# @param a2: length in bytes to copy
# 
# caveats: buffer overruns are undefined
#
# C:
#    char *end = src + len;
#    while (src != end)
#        *dest++ = *src++ 
memcpy:
	move $t0, $a1
	move $t1, $a0
	add $t2, $t0, $a2 # calculate end pointer
	blez $a2, _memcpy_L2 # skip if amount is negative or zero
_memcpy_L1:
	lb $t3, ($t0) # load byte from source
	sb $t3, ($t1) # store byte in dest
	addi $t0, $t0, 1 # inc pointers
	addi $t1, $t1, 1
	bne $t0, $t2 _memcpy_L1 # stop if end pointer reached
_memcpy_L2:
	jr $ra

# Sets Memory to specified value
#
# @param $a0: (addr) address of starting location
# @param $a1: (v) value to set each byte to
# @param $a2: (i) number of iterations
# @param $a3: (step) next iteration every n bytes
#
# C:
#    for (;i-- > 0; addr += step) *addr = v;
memset:
	# a3, $a1 const
	# move $a0, $a2 into temps
	move $t0, $a0
	move $t2, $a2
	ble $t2, $zero, _memset_L2 # ensure good args i > 0
_memset_L1:
	# store value, incrememnt pointer,take step
	sb $a1, ($t0)
	add $t0, $t0, $a3
	addi $t2, $t2, -1
	bne $t2, $zero, _memset_L1
_memset_L2:
	jr $ra
