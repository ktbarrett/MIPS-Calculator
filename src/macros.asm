###### SYSCALLS ######

# Write String to Console
#
# @param 1: address of string to print
# @clobbers: v0, a0
#
# caveat: No idea what will happen if you try to print a non-nul-term'd string,
# but it's definitely UB.
#
.macro writeString (%string)
la $a0, %string
li $v0, 4
syscall
.end_macro

# Get String from Console
#
# @param 1: buffer to place string into
# @param 2: maximum length of string to grab
# @clobbers: v0, a0, a1
#
# caveat: length specification acts like fgets. Buffer overruns are undefined behavior.
#
.macro getString(%string, %len)
la $a0, %string
li $a1, %len
li $v0, 8
syscall
.end_macro

# Exit without return value
.macro exit
li $v0, 10
syscall
.end_macro

# Get Integer from Console
#
# @param 1: register to place integer into
# @clobbers: v0
#
.macro getInteger (%r)
li $v0, 5
syscall
move %r, $v0
.end_macro

# Print Integer to Console
#
# @param 1: register holding integer to print
# @clobbers: v0, a0
#
.macro printInteger (%r)
move $a0, %r
li $v0, 1
syscall
.end_macro

##### SMALL INLINE FUNCTIONS #####

# Stack Push
#
# @ param 1: register to push onto stack
#
# push word
.macro pushw (%r)
subi $sp, $sp, 4
sw %r, ($sp)
.end_macro
# push halfword
.macro pushh (%r)
subi $sp, $sp, 2
sh %r, ($sp)
.end_macro
# push byte
.macro pushb (%r)
subi $sp, $sp, 1
sb %r, 0($sp)
.end_macro

# Stack Pop
#
# @param 1: register to pop value into
#
# pop word
.macro popw (%r)
lw %r, 0($sp)
addi $sp, $sp, 4
.end_macro
# pop halfword
.macro poph (%r)
lh %r, 0($sp)
addi $sp, $sp, 2
.end_macro
# pop byte
.macro popb (%r)
lb %r, 0($sp)
addi $sp, $sp, 1
.end_macro
