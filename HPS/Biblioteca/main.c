#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include "package.h"

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

void imprimir_matriz_resultado(uint8_t vetorC[25], uint8_t matrix_size_bits) {
    printf("Matriz Resultante:\n");

    int tamanho = matrix_size_bits + 2; // 00->2x2, 01->3x3, 10->4x4, 11->5x5
    for (int linha = 0; linha < tamanho; linha++) {
        for (int coluna = 0; coluna < tamanho; coluna++) {
            // Cast para int8_t para interpretar corretamente valores negativos
            printf("%4d ", (int8_t)vetorC[linha * 5 + coluna]);
        }
        printf("\n");
    }
}

int main(void) {
    int fd = -1;
    void *LW_virtual = configurar_mapeamento(&fd);
    if (LW_virtual == NULL) return -1;

    volatile uint32_t *LEDR_ptr = (uint32_t *)(LW_virtual + LEDR_BASE);

    *LEDR_ptr |= (1 << 29);
    *LEDR_ptr &= ~(1 << 31);

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

    uint8_t vetorC[25]; // Resultado linearizado

    printf("Selecione a operação desejada:\n");
    printf("0 = Soma\n");
    printf("1 = Subtração\n");
    printf("2 = Oposta\n");
    printf("3 = Multiplicação\n");
    printf("4 = Transposição\n");
    printf("5 = Determinante\n");
    printf("6 = Multiplicação por inteiro\n");
    printf("Digite o código da operação (0-6): ");

    int op;
    scanf("%d", &op);

    if (op < 0 || op > 6) {
        printf("Operação inválida.\n");
        munmap(LW_virtual, LW_BRIDGE_SPAN);
        close(fd);
        return -1;
    }

    uint8_t matrix_size_bits = 0b00;       // 5x5 (00->2x2, ..., 11->5x5)
    uint8_t opcode = (uint8_t)op;
    uint8_t data = (matrix_size_bits << 3) | (opcode & 0b111);

    enviar_dados_para_fpga(LEDR_ptr, matrizA, matrizB, data);
    receber_dados_da_fpga(LEDR_ptr, vetorC);
    imprimir_matriz_resultado(vetorC, matrix_size_bits);

    munmap(LW_virtual, LW_BRIDGE_SPAN);
    close(fd);
    return 0;
}
