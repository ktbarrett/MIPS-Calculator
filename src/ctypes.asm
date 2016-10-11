
.data

# bit maps created with python script
_isdigit_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0x7f 0x3 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isspace_bm: .byte 0x0 0x3e 0x0 0x0 0x1 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
_isalpha_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x7e 0x7f 0x7f 0x7 0x7e 0x7f 0x7f 0x7
_isalnum_bm: .byte 0x0 0x0 0x0 0x0 0x0 0x0 0x7f 0x3 0x7e 0x7f 0x7f 0x7 0x7e 0x7f 0x7f 0x7

.text

.macro bit_array_extract(%array)
	srl $t0, $a0, 5
	lw $t0, %array($t0)
	andi $t1, $a0, 31
	srlv $t0, $t0, $t1
	andi $v0, $t0, 1
.end_macro

isdigit:
	bit_array_extract(_isdigit_bm)
	jr $ra

isspace:
	bit_array_extract(_isspace_bm)
	jr $ra

isalpha:
	bit_array_extract(_isalpha_bm)
	jr $ra

isalnum:
	bit_array_extract(_isalnum_bm)
	jr $ra
