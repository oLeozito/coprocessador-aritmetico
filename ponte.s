    .section .text
    .global _start

_start:
    MOV     r0, #1           @ flag = 1 (bit 0)
    MOV     r1, #0b101
    LSL     r1, r1, #1
    ORR     r0, r0, r1

    MOV     r2, #0x22
    LSL     r2, r2, #4
    ORR     r0, r0, r2

    MOV     r3, #0x44
    LSL     r3, r3, #12
    ORR     r0, r0, r3

    LDR     r4, =0xFF200000
    STR     r0, [r4]

    B       .   @ Loop infinito (evita sair do programa)
