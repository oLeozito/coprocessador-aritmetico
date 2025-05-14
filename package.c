#include <stdint.h>

// Ponteiros para os registradores (já mapeados)
volatile uint32_t *reg_status;
volatile uint32_t *reg_dados;

// Máscaras
#define FLAG_ESCREVEU 0x1   // Bit 0
#define FLAG_LEU      0x2   // Bit 1

void enviar_dado(uint32_t dado) {
    // 1. Escreve o dado
    *reg_dados = dado;

    // 2. Seta o bit 0 (flag de escrita)
    *reg_status |= FLAG_ESCREVEU;

    // 3. Aguarda FPGA sinalizar que leu (bit 1 setado)
    while ((*reg_status & FLAG_LEU) == 0);

    // 4. Zera o bit 0
    *reg_status &= ~FLAG_ESCREVEU;

    // 5. Aguarda FPGA zerar o bit 1
    while ((*reg_status & FLAG_LEU) != 0);
}


#define OPCODE_SHIFT  28
#define VALOR_A_SHIFT 20
#define VALOR_B_SHIFT 12

void enviar_valores_AB(uint8_t valorA, uint8_t valorB, uint8_t opcode) {
    uint32_t dado = 0;

    // Monta o pacote
    dado |= (opcode & 0x7) << OPCODE_SHIFT;   // 3 bits para opcode
    dado |= (valorA & 0xFF) << VALOR_A_SHIFT; // 8 bits para A
    dado |= (valorB & 0xFF) << VALOR_B_SHIFT; // 8 bits para B
    dado |= FLAG_ESCREVEU;                    // Bit 31 = 1 (escreveu)

    // Handshake padrão
    *reg_dados = dado;
    *reg_status |= 0x1; // Set bit 0: "escreveu"

    // Espera FPGA ler (bit 1 = 1)
    while ((*reg_status & 0x2) == 0);

    // Zera bit de "escreveu"
    *reg_status &= ~0x1;

    // Espera FPGA zerar bit de "leu"
    while ((*reg_status & 0x2) != 0);
}

// extern void enviar_valores_AB(uint8_t valorA, uint8_t valorB, uint8_t opcode);

void enviar_matrizes_completas(uint8_t A[25], uint8_t B[25], uint8_t opcode) {
    for (int i = 0; i < 25; i++) {
        enviar_valores_AB(A[i], B[i], opcode);
    }
}


