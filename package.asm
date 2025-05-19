.section .data
delay_microseconds:
    .word 100000

.section .text
.global enviar_dados_para_fpga
.global print_progress_bar
.extern printf
.extern usleep
.type enviar_dados_para_fpga, %function


enviar_dados_para_fpga:
    push {r4-r12, lr}              @ Salva registradores

    mov r3, #0                     @ i = 0
loop_i:
    cmp r3, #25
    bge fim_envio

aguarda_bit_liberado:
    ldr r4, [r1]                   @ r4 = *RETURN_ptr
    tst r4, #(1 << 31)             @ Verifica se bit 31 está setado
    bne aguarda_bit_liberado       @ Se estiver, espera

@ Calcular índice das matrizes
    mov r5, r3
    mov r6, #5
    udiv r7, r5, r6                @ r7 = i / 5
    mul r8, r7, r6                 @ r8 = (i / 5) * 5
    sub r9, r5, r8                 @ r9 = i % 5

@ Carregar valA = matrizA[i/5][i%5]
    mov r10, r2             @ matrizA (4 primeiros args -> r0-r3, o 5º está na pilha)
    add r11, r7, r7, LSL #2        @ r11 = row * 5
    add r11, r11, r9               @ r11 = offset
    ldrb r12, [r10, r11]           @ r12 = valA

@ Carregar valB = matrizB[i/5][i%5]
    mov r10, r3            @ matrizB
    add r11, r7, r7, LSL #2        @ r11 = row * 5
    add r11, r11, r9
    ldrb r7, [r10, r11]            @ r7 = valB

@ word = (valB << 8) | valA | (0b111 << 16)
    mov r6, r12                    @ r6 = valA
    orr r6, r6, r7, LSL #8         @ r6 |= (valB << 8)
    orr r6, r6, #(0b111 << 16)     @ r6 |= 0b111 << 16

@ *LEDR_ptr = word
    str r6, [r0]

@ *LEDR_ptr |= (1 << 31)
    ldr r4, [r0]
    orr r4, r4, #(1 << 31)
    str r4, [r0]

@ Espera até RETURN_ptr[31] == 1
espera_confirma_envio:
    ldr r4, [r1]
    tst r4, #(1 << 31)
    beq espera_confirma_envio

@ *LEDR_ptr &= ~(1 << 31)
    ldr r4, [r0]
    bic r4, r4, #(1 << 31)
    str r4, [r0]

@ Chama print_progress_bar(i+1, 25)
    add r0, r3, #1
    mov r1, #25
    bl print_progress_bar

@ usleep(100000)
    ldr r0, =delay_microseconds
    bl usleep

    add r3, r3, #1
    b loop_i

fim_envio:
    pop {r4-r12, pc}



@ Funções Redirecionadas Abaixo !!!!!!!!!!!

print_progress_bar:
    push {r4-r7, lr}

    mov r4, #25               @ width = 25

    cmp r1, #0                @ if total == 0, total = 1
    bne skip_total_fix
    mov r1, #1
skip_total_fix:

    @ filled = (current * width) / total
    mul r5, r0, r4            @ r5 = current * width
    udiv r5, r5, r1           @ r5 = filled

    @ Imprime "\r[" (return carriage + [ )
    ldr r0, =str_start
    bl printf

    mov r6, #0                @ i = 0
print_loop:
    cmp r6, r4                @ i < width?
    bge print_loop_end

    cmp r6, r5                @ i < filled?
    blt print_hash

    @ print space
    ldr r0, =str_space
    bl printf
    b print_loop_next

print_hash:
    ldr r0, =str_hash
    bl printf

print_loop_next:
    add r6, r6, #1
    b print_loop

print_loop_end:

    @ Calcula porcentagem = (current * 100) / total
    mul r6, r0, #100          @ r6 = current * 100
    udiv r6, r6, r1           @ r6 = porcentagem

    @ imprime "] %d%%" com porcentagem
    ldr r0, =str_end_format   @ string "] %d%%"
    mov r1, r6                @ argumento da porcentagem no r1
    bl printf

    pop {r4-r7, pc}

.data
str_start:
    .asciz "\r["

str_hash:
    .asciz "#"

str_space:
    .asciz " "

str_end_format:
    .asciz "] %d%%"
