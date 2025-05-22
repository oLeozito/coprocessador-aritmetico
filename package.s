.global enviar_dados_para_fpga
.global receber_dados_da_fpga
.global imprimir_matriz_resultado

.section .text

@ void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizA[5][5], uint8_t matrizB[5][5], uint8_t data)
enviar_dados_para_fpga:
    push    {r4-r11, lr}
    mov     r4, r0              @ LEDR_ptr
    mov     r5, r1              @ matrizA
    mov     r6, r2              @ matrizB
    uxtb    r7, r3             @ data (8 bits)
    add     r8, r4, #16         @ RETURN_ptr = LEDR_ptr + 16 bytes
    mov     r9, #0              @ i = 0

send_loop:
    cmp     r9, #25
    bge     send_done

wait_send_ready:
    ldr     r10, [r8]
    tst     r10, #0x80000000    @ Verifica bit 31
    bne     wait_send_ready

    ldrb    r0, [r5, r9]        @ valA = matrizA[i]
    ldrb    r1, [r6, r9]        @ valB = matrizB[i]

    orr     r10, r0, r1, lsl #8 @ valA | (valB << 8)
    orr     r10, r10, r7, lsl #16 @ Adiciona data (bits 16-21)

    str     r10, [r4]           @ Escreve no LEDR
    ldr     r10, [r4]
    orr     r10, r10, #0x80000000 @ Seta bit 31
    str     r10, [r4]

wait_send_done:
    ldr     r10, [r8]
    tst     r10, #0x80000000
    bne     wait_send_done

    ldr     r10, [r4]
    bic     r10, r10, #0x80000000 @ Limpa bit 31
    str     r10, [r4]

    add     r0, r9, #1          @ current = i + 1
    mov     r1, #25             @ total = 25
    bl      print_progress_bar

    ldr     r0, =100000
    bl      usleep

    add     r9, r9, #1          @ i++
    b       send_loop

send_done:
    pop     {r4-r11, pc}

@ void receber_dados_da_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizC[5][5])
receber_dados_da_fpga:
    push    {r4-r11, lr}
    mov     r4, r0              @ LEDR_ptr
    mov     r5, r1              @ matrizC
    add     r6, r4, #16         @ RETURN_ptr
    mov     r7, #0              @ indice = 0

receive_loop:
    cmp     r7, #25
    bge     receive_done

wait_receive_ready:
    ldr     r8, [r6]
    tst     r8, #0x40000000     @ Verifica bit 30
    beq     wait_receive_ready

    ldr     r8, [r6]            @ dado = *RETURN_ptr

    cmp     r7, #21
    bgt     handle_last

    ubfx    r0, r8, #0, #8      @ Extrai byte 0
    strb    r0, [r5, r7]        @ matrizC[indice]
    add     r9, r7, #1
    ubfx    r0, r8, #8, #8      @ Extrai byte 1
    strb    r0, [r5, r9]
    add     r9, r7, #2
    ubfx    r0, r8, #16, #8     @ Extrai byte 2
    strb    r0, [r5, r9]
    add     r7, r7, #3
    b       update_progress

handle_last:
    mov     r0, #24             @ matrizC[4][4]
    ubfx    r1, r8, #0, #8
    strb    r1, [r5, r0]
    add     r7, r7, #1

update_progress:
    ldr     r0, [r4]
    orr     r0, r0, #0x40000000 @ Seta bit 30
    str     r0, [r4]

wait_clear:
    ldr     r0, [r6]
    tst     r0, #0x40000000
    bne     wait_clear

    ldr     r0, [r4]
    bic     r0, r0, #0x40000000 @ Limpa bit 30
    str     r0, [r4]

    cmp     r7, #25
    movgt   r0, #25
    movle   r0, r7
    mov     r1, #25
    bl      print_progress_bar

    ldr     r0, =100000
    bl      usleep

    b       receive_loop

receive_done:
    pop     {r4-r11, pc}

@ void imprimir_matriz_resultado(uint8_t matrizC[5][5])
imprimir_matriz_resultado:
    push    {r4-r6, lr}
    mov     r4, r0              @ matrizC
    mov     r5, #0              @ i = 0

outer_loop:
    cmp     r5, #5
    bge     print_done
    mov     r6, #0              @ j = 0

inner_loop:
    cmp     r6, #5
    bge     inner_done

    mov     r0, r5
    mov     r1, #5
    mla     r0, r0, r1, r6      @ i*5 + j
    ldrb    r1, [r4, r0]        @ matrizC[i][j]

    ldr     r0, =format_str
    bl      printf

    add     r6, r6, #1
    b       inner_loop

inner_done:
    ldr     r0, =newline_str
    bl      printf

    add     r5, r5, #1
    b       outer_loop

print_done:
    pop     {r4-r6, pc}

.section .rodata
format_str: .asciz "%3d "
newline_str: .asciz "\n"