#include "riscv_csr_encoding.h"
#include "sc_test.h"

.section .text
.global _start
.global start
.global main

_start:
start:
#ifndef __RVE_EXT
    zero_int_regs 1, 31
#else
    zero_int_regs 1, 15
#endif
    # Global pointer init
    .option push
    .option norelax
    la    gp, __global_pointer$
    .option pop
	
	# clear bss
    la      a1, __BSS_START__
    la      a2, __BSS_END__
    j       4f
3:  sw      zero, 0(a1)
    add     a1, a1, 4
4:  bne     a1, a2, 3b
	
	/* print "START\n" */
	lui a0,0x10000000>>12
	addi a1,zero,'S'
	addi a2,zero,'T'
	addi a3,zero,'A'
	addi a4,zero,'R'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a2,0(a0)
	sw a3,0(a0)
	sw a4,0(a0)
	sw a2,0(a0)
	sw a5,0(a0)

	/* execute some insns for "make timing" */
	lui a0,0
	auipc a0,0
	slli a0,a0,0
	slli a0,a0,31
	addi a1,zero,0
	sll a0,a0,a1
	addi a1,zero,31
	sll a0,a0,a1

	/* set stack pointer */
	la sp, __C_STACK_TOP__

	/* jump to main C code */
	li      a0, 0
    li      a1, 0
	jal ra,main

	/* print "DONE\n" */
	lui a0,0x10000000>>12
	addi a1,zero,'D'
	addi a2,zero,'O'
	addi a3,zero,'N'
	addi a4,zero,'E'
	addi a5,zero,'\n'
	sw a1,0(a0)
	sw a2,0(a0)
	sw a3,0(a0)
	sw a4,0(a0)
	sw a5,0(a0)

	/* write special port for $finish() in simulation case*/
	lui  a0,0x10001000>>12
	addi a1,zero,'*'
	sw a1,0(a0)

stop:
	j stop
	
	/* trap */
	ebreak

