.syntax unified
.arch armv7-a
.thumb

.section .rodata
msg_enviando:       .ascii "Enviando dados para o coprocessador:\000"
msg_dados_enviados: .ascii "\012Dados enviados com sucesso!\000"
msg_processando:    .ascii "\012(Processando dados)\012\000"
msg_recebendo:      .ascii "Recebendo dados de volta:\000"
msg_dados_recebidos:.ascii "\012Dados recebidos com sucesso!\012\000"

.section .text
.align 2



@ @Mapeamento de memoria
@ .global configurar_mapeamento
@ .text

@ configurar_mapeamento:
@ @ Recebe ponteiro no r0

@ MOV r1, #1 @ flag = 1 (bit 0)

@ MOV r2, #0b101
@ LSL r2, r2, #1
@ ORR r1, r1, r2

@ MOV r3, #0x22
@ LSL r3, r3, #4
@ ORR r1, r1, r3

@ MOV r4, #0x44
@ LSL r4, r4, #12
@ ORR r1, r1, r4

@ STR r1, [r0]

@ BX lr



@  =============================================================================
@  Função: enviar_dados_para_fpga
@  Parâmetros: 
@    r0 = LEDR_ptr (ponteiro base)
@    r1 = matrizA (ponteiro para matriz A)
@    r2 = matrizB (ponteiro para matriz B) 
@    r3 = data (dados de controle)
@  =============================================================================
.global enviar_dados_para_fpga
.thumb_func
enviar_dados_para_fpga:
    push    {r4-r7, lr}         @  Salva registradores
    sub     sp, sp, #32         @  Reserva espaço na stack
    mov     r7, sp              @  Frame pointer
    
    @  Salva parâmetros na stack
    str     r0, [r7, #12]       @  LEDR_ptr
    str     r1, [r7, #8]        @  matrizA  
    str     r2, [r7, #4]        @  matrizB
    strb    r3, [r7, #3]        @  data
    
    @  Calcula RETURN_ptr = LEDR_ptr + 16 (4 words)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    add     r3, r3, #16         @  Adiciona offset
    str     r3, [r7, #20]       @  Salva RETURN_ptr
    
    @  Imprime mensagem inicial
    ldr     r0, =msg_enviando
    bl      puts
    
    @  Inicializa contador do loop (i = 0)
    mov     r3, #0
    str     r3, [r7, #16]       @  i = 0
    
loop_envio:
    @  Verifica se i < 25
    ldr     r3, [r7, #16]       @  Carrega i
    cmp     r3, #24
    bgt     fim_envio
    
    @  Aguarda FPGA ficar pronto (bit 31 do RETURN_ptr == 0)
espera_fpga_pronto:
    ldr     r3, [r7, #20]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor do registrador
    tst     r3, #0x80000000     @  Testa bit 31
    bne     espera_fpga_pronto  @  Se bit 31 = 1, continua esperando
    
    @  Calcula índices da matriz (i/5 e i%5)
    ldr     r2, [r7, #16]       @  r2 = i
    
    @  Divisão por 5 usando multiplicação mágica
    @  Equivale a: linha = i / 5, coluna = i % 5
    movw    r3, #26215          @  Constante mágica para divisão por 5
    movt    r3, #26214
    smull   r1, r3, r3, r2      @  Multiplicação 64 bits
    asr     r1, r3, #1          @  Shift aritmético
    asr     r3, r2, #31         @  Sinal
    sub     r4, r1, r3          @  r4 = linha = i/5
    
    @  Calcula coluna: i - (linha * 5)
    mov     r3, r4              @  r3 = linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5
    sub     r5, r2, r3          @  r5 = coluna = i % 5
    
    @  Lê valor da matrizA[linha][coluna]
    ldr     r2, [r7, #8]        @  Carrega ponteiro matrizA
    mov     r3, r4              @  linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5 
    add     r0, r2, r3          @  matrizA + (linha * 5)
    ldrb    r3, [r0, r5]        @  matrizA[linha][coluna]
    strb    r3, [r7, #30]       @  Salva valA
    
    @  Lê valor da matrizB[linha][coluna] (mesmo cálculo)
    ldr     r2, [r7, #4]        @  Carrega ponteiro matrizB
    mov     r3, r4              @  linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5
    add     r0, r2, r3          @  matrizB + (linha * 5)
    ldrb    r3, [r0, r5]        @  matrizB[linha][coluna]
    strb    r3, [r7, #31]       @  Salva valB
    
    @  Monta palavra de 32 bits: word = valA | (valB << 8) | (data << 16)
    mov     r3, #0              @  word = 0
    str     r3, [r7, #24]
    
    ldrb    r3, [r7, #30]       @  Carrega valA
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= valA
    str     r3, [r7, #24]       @  Salva word
    
    ldrb    r3, [r7, #31]       @  Carrega valB
    lsl     r3, r3, #8          @  valB << 8
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= (valB << 8)
    str     r3, [r7, #24]       @  Salva word
    
    ldrb    r3, [r7, #3]        @  Carrega data
    and     r3, r3, #63         @  Máscara 6 bits
    lsl     r3, r3, #16         @  data << 16
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= (data << 16)
    str     r3, [r7, #24]       @  Salva word final
    
    @  Escreve palavra no registrador LEDR
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r2, [r7, #24]       @  Carrega word
    str     r2, [r3, #0]        @  *LEDR_ptr = word
    
    @  Sinaliza início da transmissão (bit 31 = 1)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    orr     r2, r3, #0x80000000 @  Seta bit 31
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Aguarda confirmação do FPGA (bit 31 do RETURN_ptr == 1)
espera_confirmacao:
    ldr     r3, [r7, #20]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x80000000     @  Testa bit 31
    beq     espera_confirmacao  @  Se bit 31 = 0, continua esperando
    
    @  Limpa sinal de transmissão (bit 31 = 0)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    bic     r2, r3, #0x80000000 @  Limpa bit 31
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Atualiza barra de progresso
    ldr     r3, [r7, #16]       @  Carrega i
    add     r0, r3, #1          @  i + 1 (para progresso)
    mov     r1, #25             @  Total
    bl      print_progress_bar
    
    @  Delay
    movw    r0, #34464          @  100ms em microssegundos
    movt    r0, #1
    @bl      usleep
    
    @  Incrementa contador
    ldr     r3, [r7, #16]       @  Carrega i
    add     r3, r3, #1          @  i++
    str     r3, [r7, #16]       @  Salva i
    
    b       loop_envio          @  Volta para o loop

fim_envio:
    @  Imprime mensagem final
    ldr     r0, =msg_dados_enviados
    bl      puts
    
    @  Restaura stack e retorna
    add     sp, sp, #32
    pop     {r4-r7, pc}











@  =============================================================================
@  Função: receber_dados_da_fpga
@  Parâmetros:
@    r0 = LEDR_ptr (ponteiro base)
@    r1 = matrizC (ponteiro para matriz resultado)
@  =============================================================================
.global receber_dados_da_fpga
.thumb_func
receber_dados_da_fpga:
    push    {r4-r7, lr}         @  Salva registradores
    sub     sp, sp, #24         @  Reserva espaço na stack
    mov     r7, sp              @  Frame pointer
    
    @  Salva parâmetros
    str     r0, [r7, #4]        @  LEDR_ptr
    str     r1, [r7, #0]        @  matrizC
    
    @  Calcula RETURN_ptr = LEDR_ptr + 16
    ldr     r3, [r7, #4]        @  Carrega LEDR_ptr
    add     r3, r3, #16         @  Adiciona offset
    str     r3, [r7, #16]       @  Salva RETURN_ptr
    
    @  Imprime mensagens iniciais
    ldr     r0, =msg_processando
    bl      puts
    ldr     r0, =msg_recebendo
    bl      puts
    
    @  Inicializa contador (indice = 0)
    mov     r3, #0
    str     r3, [r7, #12]       @  indice = 0
    
loop_recebimento:
    @  Verifica se indice < 25
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #24
    bgt     fim_recebimento
    
    @  Aguarda dados válidos (bit 30 do RETURN_ptr == 1)
espera_dados_validos:
    ldr     r3, [r7, #16]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x40000000     @  Testa bit 30
    beq     espera_dados_validos @  Se bit 30 = 0, continua esperando
    
    @  Lê dado do registrador
    ldr     r3, [r7, #16]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê dado
    str     r3, [r7, #20]       @  Salva dado
    
    @  Verifica se ainda há mais de 3 elementos para processar
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #21
    bgt     processa_ultimo_elemento
    
    @  Processa 3 elementos de uma vez
    @  Elemento 1: dado[7:0] -> matrizC[indice/5][indice%5]
    ldr     r2, [r7, #12]       @  r2 = indice
    
    @  Calcula linha e coluna para elemento atual
    movw    r3, #26215          @  Constante mágica
    movt    r3, #26214
    smull   r1, r3, r3, r2      @  Divisão por 5
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  r4 = linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4          @  linha * 5
    sub     r5, r2, r3          @  r5 = coluna
    
    ldr     r2, [r7, #0]        @  Carrega matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4          @  linha * 5
    add     r0, r2, r3          @  matrizC + (linha * 5)
    ldr     r3, [r7, #20]       @  Carrega dado
    uxtb    r3, r3              @  Extrai byte inferior
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[7:0]
    
    @  Elemento 2: dado[15:8] -> matrizC[(indice+1)/5][(indice+1)%5]
    ldr     r3, [r7, #12]       @  Carrega indice
    add     r2, r3, #1          @  indice + 1
    
    @  Calcula linha e coluna para indice+1
    movw    r3, #26215
    movt    r3, #26214
    smull   r1, r3, r3, r2
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    sub     r5, r2, r3          @  coluna
    
    ldr     r2, [r7, #0]        @  matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    add     r0, r2, r3
    ldr     r3, [r7, #20]       @  Carrega dado
    lsr     r3, r3, #8          @  Desloca para pegar bits 15:8
    uxtb    r3, r3
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[15:8]
    
    @  Elemento 3: dado[23:16] -> matrizC[(indice+2)/5][(indice+2)%5]
    ldr     r3, [r7, #12]       @  Carrega indice
    add     r2, r3, #2          @  indice + 2
    
    @  Calcula linha e coluna para indice+2
    movw    r3, #26215
    movt    r3, #26214
    smull   r1, r3, r3, r2
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    sub     r5, r2, r3          @  coluna
    
    ldr     r2, [r7, #0]        @  matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    add     r0, r2, r3
    ldr     r3, [r7, #20]       @  Carrega dado
    lsr     r3, r3, #16         @  Desloca para pegar bits 23:16
    uxtb    r3, r3
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[23:16]
    
    @  Incrementa indice em 3
    ldr     r3, [r7, #12]
    add     r3, r3, #3
    str     r3, [r7, #12]
    
    b       confirma_recebimento

processa_ultimo_elemento:
    @  Processa último elemento: matrizC[4][4] = dado[7:0]
    ldr     r3, [r7, #0]        @  matrizC
    add     r3, r3, #20         @  Vai para última linha (4*5)
    ldr     r2, [r7, #20]       @  Carrega dado
    uxtb    r2, r2              @  Extrai byte inferior
    strb    r2, [r3, #4]        @  matrizC[4][4] = dado[7:0]
    
    @  Incrementa indice
    ldr     r3, [r7, #12]
    add     r3, r3, #1
    str     r3, [r7, #12]

confirma_recebimento:
    @  Confirma recebimento (seta bit 30)
    ldr     r3, [r7, #4]        @  LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    orr     r2, r3, #0x40000000 @  Seta bit 30
    ldr     r3, [r7, #4]        @  LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Aguarda FPGA confirmar (bit 30 do RETURN_ptr == 0)
espera_ack_fpga:
    ldr     r3, [r7, #16]       @  RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x40000000     @  Testa bit 30
    bne     espera_ack_fpga     @  Se bit 30 = 1, continua esperando
    
    @  Limpa confirmação (bit 30 = 0)
    ldr     r3, [r7, #4]        @  LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    bic     r2, r3, #0x40000000 @  Limpa bit 30
    ldr     r3, [r7, #4]        @  LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Atualiza barra de progresso
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #25             @  Se indice > 25
    it      ge
    movge   r3, #25             @  Limita a 25
    mov     r0, r3              @  Progresso atual
    mov     r1, #25             @  Total
    bl      print_progress_bar
    
    @  Delay
    movw    r0, #34464          @  100ms
    movt    r0, #1
    @bl      usleep
    
    b       loop_recebimento    @  Volta para o loop

fim_recebimento:
    @  Imprime mensagem final
    ldr     r0, =msg_dados_recebidos
    bl      puts
    
    @  Restaura stack e retorna
    add     sp, sp, #24
    pop     {r4-r7, pc}

@.end

















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

.end
