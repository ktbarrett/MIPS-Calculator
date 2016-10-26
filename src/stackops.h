
.macro stackpush(%sp, %r)
	sw %r, (%sp)
	addi %sp, %sp, 4
.end_macro

.macro stackadd(%base, %ind, %r)
	sw %r, %base(%ind)
	addi %ind, %ind, 4
.end_macro

.macro stackpop(%sp, %r)
	addi %sp, %sp, -4
	lw %r, (%sp)
.end_macro

.macro stackrem(%base, %ind, %r)
	addi %ind, %ind, -4
	lw %r, %base(%ind)
.end_macro

.macro stackpeek(%sp, %r)
	addi %sp, %sp, -4
	lw %r, (%sp)
	addi %sp, %sp, 4
.end_macro

.macro stacktop(%base, %ind, %r)
	addi %ind, %ind, -4
	lw %r, %base(%ind)
	addi %ind, %ind, 4
.end_macro
