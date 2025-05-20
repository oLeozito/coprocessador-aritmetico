.section .text
.global enviar_dados_para_fpga
.global receber_dados_da_fpga
.global imprimir_matriz_resultado

@ --- enviar_dados_para_fpga ---
@ Argumentos:
@   r0: LEDR_ptr (ponteiro para o registrador do FPGA)
@   r1: matrizA (ponteiro para a matriz 5x5)
@   r2: matrizB (ponteiro para a matriz 5x5)
@   r3: data (8 bits)
enviar_dados_para_fpga:
    PUSH    {r4-r11, lr}          @ Salva registradores

    MOV     r4, r0                 @ r4 = LEDR_ptr
    ADD     r5, r4, #16            @ r5 = RETURN_ptr (LEDR_ptr + 4 words)
    MOV     r6, #0                 @ i = 0

send_loop:
    @ Aguarda FPGA pronto (bit 31 de RETURN_ptr == 0)
    wait_ready:
        LDR     r7, [r5]
        TST     r7, #(1 << 31)     @ Testa bit 31
        BNE     wait_ready

    @ Carrega valA e valB das matrizes
    LDRB    r8, [r1, r6]           @ r8 = matrizA[i]
    LDRB    r9, [r2, r6]           @ r9 = matrizB[i]

    @ Monta a palavra (valA | valB << 8 | data << 16)
    ORR     r10, r8, r9, LSL #8
    ORR     r10, r10, r3, LSL #16

    @ Escreve e aciona bit 31
    STR     r10, [r4]
    ORR     r10, r10, #(1 << 31)
    STR     r10, [r4]

    @ Aguarda operação concluída (bit 31 de RETURN_ptr == 1)
    wait_done:
        LDR     r7, [r5]
        TST     r7, #(1 << 31)
        BEQ     wait_done

    @ Limpa bit de start
    BIC     r10, r10, #(1 << 31)
    STR     r10, [r4]

    @ Incrementa índice (i++)
    ADD     r6, r6, #1
    CMP     r6, #25
    BLT     send_loop

    POP     {r4-r11, pc}           @ Retorna

@ --- receber_dados_da_fpga ---
@ Argumentos:
@   r0: LEDR_ptr
@   r1: matrizC (ponteiro para a matriz de saída)
receber_dados_da_fpga:
    PUSH    {r4-r10, lr}
    MOV     r4, r0                 @ r4 = LEDR_ptr
    ADD     r5, r4, #16            @ r5 = RETURN_ptr
    MOV     r6, #0                 @ indice = 0

receive_loop:
    @ Aguarda dado válido (bit 30 de RETURN_ptr == 1)
    wait_valid:
        LDR     r7, [r5]
        TST     r7, #(1 << 30)
        BEQ     wait_valid

    @ Lê dado e processa
    LDR     r8, [r5]               @ r8 = dado
    CMP     r6, #21
    BGT     last_elements

    @ Escreve 3 elementos de uma vez (bits 0-7, 8-15, 16-23)
    STRB    r8, [r1, r6]           @ matrizC[indice] = dado[0-7]
    ADD     r6, r6, #1
    MOV     r9, r8, LSR #8
    STRB    r9, [r1, r6]           @ matrizC[indice+1] = dado[8-15]
    ADD     r6, r6, #1
    MOV     r9, r8, LSR #16
    STRB    r9, [r1, r6]           @ matrizC[indice+2] = dado[16-23]
    ADD     r6, r6, #1
    B       ack

last_elements:
    @ Último elemento (indice 24)
    STRB    r8, [r1, #24]          @ matrizC[4][4] = dado[0-7]
    ADD     r6, r6, #1

ack:
    @ Confirma recebimento (ativa bit 30)
    LDR     r9, [r4]
    ORR     r9, r9, #(1 << 30)
    STR     r9, [r4]

    @ Aguarda FPGA limpar bit 30
    wait_ack:
        LDR     r7, [r5]
        TST     r7, #(1 << 30)
        BNE     wait_ack

    @ Limpa bit de confirmação
    BIC     r9, r9, #(1 << 30)
    STR     r9, [r4]

    CMP     r6, #25
    BLT     receive_loop

    POP     {r4-r10, pc}

@ --- imprimir_matriz_resultado ---
@ Argumentos:
@   r0: matrizC (ponteiro para a matriz 5x5)
imprimir_matriz_resultado:
    PUSH    {r4-r6, lr}
    MOV     r4, r0                 @ r4 = matrizC
    MOV     r5, #0                 @ i = 0

print_loop:
    MOV     r6, #0                 @ j = 0
    row_loop:
        @ Calcula endereço do elemento matrizC[i][j]
        MLA     r0, r5, #5, r6     @ r0 = i*5 + j
        LDRB    r0, [r4, r0]       @ r0 = matrizC[i][j]

        @ Imprime valor (chamada ao printf em C)
        LDR     r1, =format_str
        BL      printf
        ADD     r6, r6, #1
        CMP     r6, #5
        BLT     row_loop

    @ Imprime nova linha
    LDR     r0, =newline
    BL      puts

    ADD     r5, r5, #1
    CMP     r5, #5
    BLT     print_loop

    POP     {r4-r6, pc}

.section .rodata
format_str: .asciz "%3d "
newline:    .asciz ""