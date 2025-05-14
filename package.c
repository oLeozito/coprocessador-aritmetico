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


