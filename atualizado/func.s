.section .text
.global escreve_valor
.type escreve_valor, %function
.global mapear_memoria
.type mapear_memoria, %function
.global liberar_memoria
.type liberar_memoria, %function

.equ LW_BRIDGE_BASE, 0xFF200
.equ MAP_SIZE, 0x1000
.equ PROT_READ, 1
.equ PROT_WRITE, 2
.equ MAP_SHARED, 1

@ Estrutura memoria_mapeada (8 bytes)
@ offset 0: map_base (4 bytes)
@ offset 4: fd (4 bytes)

mapear_memoria:
    push    {r4-r7, lr}
    
    @ Abre /dev/mem
    ldr     r0, =dev_mem_path
    mov     r1, #0x0002        @ O_RDWR
    orr     r1, #0x4000        @ O_SYNC
    mov     r7, #5             @ syscall open
    svc     #0
    
    cmp     r0, #0             @ Se fd < 0, erro
    blt     mapear_error
    
    mov     r4, r0             @ Salva fd
    
    @ Chama mmap
    mov     r0, #0             @ NULL
    ldr     r1, =MAP_SIZE
    mov     r2, #3             @ PROT_READ|PROT_WRITE
    mov     r3, #1             @ MAP_SHARED
    mov     r5, r4             @ fd
    ldr     r6, =LW_BRIDGE_BASE
    mov     r7, #192           @ syscall mmap2
    svc     #0
    
    cmp     r0, #-1            @ Se mmap falhou
    beq     mapear_close
    
    @ Preenche estrutura de retorno
    ldr     r5, =memoria_buffer
    str     r0, [r5]           @ map_base
    str     r4, [r5, #4]       @ fd
    mov     r0, r5             @ Retorna ponteiro para estrutura
    pop     {r4-r7, pc}
    
mapear_close:
    @ Fecha o arquivo se mmap falhou
    mov     r0, r4
    mov     r7, #6             @ syscall close
    svc     #0
    
mapear_error:
    mov     r0, #0             @ Retorna NULL
    pop     {r4-r7, pc}

liberar_memoria:
    push    {r4, lr}
    mov     r4, r0
    
    @ munmap
    ldr     r0, [r4]            @ map_base
    ldr     r1, =MAP_SIZE
    mov     r7, #91             @ syscall munmap
    svc     #0
    
    @ close
    ldr     r0, [r4, #4]        @ fd
    mov     r7, #6
    svc     #0
    
    pop     {r4, pc}

escreve_valor:
    cmp     r0, #0
    beq     escreve_fim
    push    {r1-r3}
    
    mov     r1, #1
    mov     r2, #0b101
    lsl     r2, r2, #1
    orr     r1, r1, r2
    mov     r2, #0x22
    lsl     r2, r2, #4
    orr     r1, r1, r2
    mov     r3, #0x44
    lsl     r3, r3, #12
    orr     r1, r1, r3
    
    str     r1, [r0]
    pop     {r1-r3}
    
escreve_fim:
    bx      lr

.section .data
memoria_buffer:
    .space 8                   @ Reserva espaço para a estrutura

.section .rodata
dev_mem_path:
    .asciz "/dev/mem"

@ Linha vazia abaixo (adicione esta linha)
