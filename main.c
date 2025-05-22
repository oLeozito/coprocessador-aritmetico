#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <unistd.h>
#include "package.h"
#include <unistd.h>



#define LW_BRIDGE_BASE   0xFF200000
#define LW_BRIDGE_SPAN   0x00005000
#define LEDR_BASE        0x00000000
#define RETURN_BASE      0x00000010

void print_progress_bar(int current, int total) {
    int width = 25;
    int filled;
    int i;

    if (total == 0) total = 1;
    filled = (current * width) / total;

    printf("\r[");
    for (i = 0; i < width; i++) {
        if (i < filled)
            printf("#");
        else
            printf(" ");
    }
    printf("] %d%%", (current * 100) / total);
    fflush(stdout);
}

void* configurar_mapeamento(int *fd) {
    *fd = open("/dev/mem", (O_RDWR | O_SYNC));
    if (*fd == -1) {
        printf("ERRO: não foi possível abrir \"/dev/mem\"...\n");
        return NULL;
    }

    void *virtual = mmap(NULL, LW_BRIDGE_SPAN, (PROT_READ | PROT_WRITE),
                         MAP_SHARED, *fd, LW_BRIDGE_BASE);
    if (virtual == MAP_FAILED) {
        printf("ERRO: mmap() falhou...\n");
        close(*fd);
        return NULL;
    }

    return virtual;
}


void imprimir_matriz_resultado(uint8_t matrizC[5][5]) {
    printf("Matriz Resultante:\n");
    for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
            printf("%3d ", matrizC[i][j]);
        }
        printf("\n");
    }
}

int main(void) {
    int fd = -1;
    void *LW_virtual = configurar_mapeamento(&fd);
    if (LW_virtual == NULL) return -1;

    // Ponteiro base da FPGA (LEDR)
    volatile uint32_t *LEDR_ptr = (uint32_t *)(LW_virtual + LEDR_BASE);

    // Configura os sinais de controle
    *LEDR_ptr |= (1 << 29);     // (ex: ativa coprocessador)
    *LEDR_ptr &= ~(1 << 31);    // Garante que o bit de "start" esteja zerado

    // Matrizes de entrada
    uint8_t matrizA[5][5] = {
        {1, 2, 3, 4, 5},
        {6, 7, 8, 9, 10},
        {11, 12, 13, 14, 15},
        {16, 17, 18, 19, 20},
        {21, 22, 23, 24, 25}
    };

    uint8_t matrizB[5][5] = {
        {25, 24, 23, 22, 21},
        {20, 19, 18, 17, 16},
        {15, 14, 13, 12, 11},
        {10, 9, 8, 7, 6},
        {5, 4, 3, 2, 1}
    };

    uint8_t matrizC[5][5]; // Resultado

    // Define o valor de "data"
    // Exemplo: tamanho = 0b000 (5x5 = fixo), opcode = 0b010 (multiplicação)
    // Então: data = (tamanho << 3) | opcode
    uint8_t tamanho = 0b000;  // 3 bits
    uint8_t opcode  = 0b010;  // 3 bits
    uint8_t data = (tamanho << 3) | (opcode & 0b111);

    // Envia dados para a FPGA (apenas ponteiro base e data são passados)
    enviar_dados_para_fpga(LEDR_ptr, matrizA, matrizB, data);
    receber_dados_da_fpga(LEDR_ptr, matrizC);
    imprimir_matriz_resultado(matrizC);

    // Finaliza mapeamento
    munmap(LW_virtual, LW_BRIDGE_SPAN);
    close(fd);
    return 0;
}