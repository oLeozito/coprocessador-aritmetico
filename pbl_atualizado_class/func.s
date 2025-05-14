.section .text
.global escreve_valor
.type escreve_valor, %function

escreve_valor:
    PUSH    {r1-r3}           @ Salva registradores temporários

    MOV     r1, #1            @ flag = 1 (bit 0)

    MOV     r2, #0b101        @ opcode
    LSL     r2, r2, #1
    ORR     r1, r1, r2

    MOV     r2, #0x22         @ valor A
    LSL     r2, r2, #4
    ORR     r1, r1, r2

    MOV     r3, #0x44         @ valor B
    LSL     r3, r3, #12
    ORR     r1, r1, r3

    STR     r1, [r0]          @ escreve no ponteiro passado (r0 = ponte)

    POP     {r1-r3}
    BX      lr
