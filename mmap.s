	.syntax unified
	.arch armv7-a
	.eabi_attribute 27, 3
	.eabi_attribute 28, 1
	.fpu vfpv3-d16
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"package.c"
@ GNU C (Ubuntu/Linaro 4.6.3-1ubuntu5) version 4.6.3 (arm-linux-gnueabihf)
@	compiled by GNU C version 4.6.3, GMP version 5.0.2, MPFR version 3.1.0-p3, MPC version 0.9
@ GGC heuristics: --param ggc-min-expand=80 --param ggc-min-heapsize=95225
@ options passed:  -imultilib . -imultiarch arm-linux-gnueabihf package.c
@ -march=armv7-a -mfloat-abi=hard -mfpu=vfpv3-d16 -mthumb
@ -auxbase-strip mmap.s -O0 -fverbose-asm -fstack-protector
@ options enabled:  -fauto-inc-dec -fbranch-count-reg -fcommon
@ -fdelete-null-pointer-checks -fdwarf2-cfi-asm -fearly-inlining
@ -feliminate-unused-debug-types -ffunction-cse -fgcse-lm -fident
@ -finline-functions-called-once -fira-share-save-slots
@ -fira-share-spill-slots -fivopts -fkeep-static-consts
@ -fleading-underscore -fmath-errno -fmerge-debug-strings
@ -fmove-loop-invariants -fpeephole -fprefetch-loop-arrays
@ -freg-struct-return -fsched-critical-path-heuristic
@ -fsched-dep-count-heuristic -fsched-group-heuristic -fsched-interblock
@ -fsched-last-insn-heuristic -fsched-rank-heuristic -fsched-spec
@ -fsched-spec-insn-heuristic -fsched-stalled-insns-dep -fshow-column
@ -fsigned-zeros -fsplit-ivs-in-unroller -fstack-protector
@ -fstrict-volatile-bitfields -ftrapping-math -ftree-cselim -ftree-forwprop
@ -ftree-loop-if-convert -ftree-loop-im -ftree-loop-ivcanon
@ -ftree-loop-optimize -ftree-parallelize-loops= -ftree-phiprop -ftree-pta
@ -ftree-reassoc -ftree-scev-cprop -ftree-slp-vectorize
@ -ftree-vect-loop-version -funit-at-a-time -fverbose-asm
@ -fzero-initialized-in-bss -mglibc -mlittle-endian -msched-prolog -mthumb
@ -munaligned-access -mvectorize-with-neon-quad

@ Compiler executable checksum: ffcbc490dd19d9f3c1e5842c6cc7a10d

	.section	.rodata
	.align	2
.LC0:
	.ascii	"/dev/mem\000"
	.align	2
.LC1:
	.ascii	"ERRO: n\303\243o foi poss\303\255vel abrir \"/dev/m"
	.ascii	"em\"...\000"
	.align	2
.LC2:
	.ascii	"ERRO: mmap() falhou...\000"
	.text
	.align	2
	.global	configurar_mapeamento
	.thumb
	.thumb_func
	.type	configurar_mapeamento, %function
configurar_mapeamento:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{r7, lr}	@
	sub	sp, sp, #24	@,,
	add	r7, sp, #8	@,,
	str	r0, [r7, #4]	@ fd, fd
	movw	r0, #:lower16:.LC0	@,
	movt	r0, #:upper16:.LC0	@,
	movw	r1, #4098	@,
	movt	r1, 16	@,
	bl	open	@
	mov	r2, r0	@ D.2573,
	ldr	r3, [r7, #4]	@ tmp140, fd
	str	r2, [r3, #0]	@ D.2573, *fd_3(D)
	ldr	r3, [r7, #4]	@ tmp141, fd
	ldr	r3, [r3, #0]	@ D.2574, *fd_3(D)
	cmp	r3, #-1	@ D.2574,
	bne	.L2	@,
	movw	r0, #:lower16:.LC1	@,
	movt	r0, #:upper16:.LC1	@,
	bl	puts	@
	mov	r3, #0	@ D.2577,
	b	.L3	@
.L2:
	ldr	r3, [r7, #4]	@ tmp142, fd
	ldr	r3, [r3, #0]	@ D.2578, *fd_3(D)
	str	r3, [sp, #0]	@ D.2578,
	mov	r3, #0	@ tmp143,
	movt	r3, 65312	@ tmp143,
	str	r3, [sp, #4]	@ tmp143,
	mov	r0, #0	@,
	mov	r1, #20480	@,
	mov	r2, #3	@,
	mov	r3, #1	@,
	bl	mmap	@
	str	r0, [r7, #12]	@, virtual
	ldr	r3, [r7, #12]	@ tmp144, virtual
	cmp	r3, #-1	@ tmp144,
	bne	.L4	@,
	movw	r0, #:lower16:.LC2	@,
	movt	r0, #:upper16:.LC2	@,
	bl	puts	@
	ldr	r3, [r7, #4]	@ tmp145, fd
	ldr	r3, [r3, #0]	@ D.2581, *fd_3(D)
	mov	r0, r3	@, D.2581
	bl	close	@
	mov	r3, #0	@ D.2577,
	b	.L3	@
.L4:
	ldr	r3, [r7, #12]	@ D.2577, virtual
.L3:
	mov	r0, r3	@, <retval>
	add	r7, r7, #16	@,,
	mov	sp, r7
	pop	{r7, pc}
	.size	configurar_mapeamento, .-configurar_mapeamento
	.ident	"GCC: (Ubuntu/Linaro 4.6.3-1ubuntu5) 4.6.3"
	.section	.note.GNU-stack,"",%progbits
