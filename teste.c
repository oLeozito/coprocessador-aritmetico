// main.c
#include "biblioteca.h"
#include <stdio.h>
#include <stdint.h>

#define TAMANHO_MAX 5
#define TOTAL_ELEMENTOS 25

void preencher_matriz(uint8_t matriz[TOTAL_ELEMENTOS], int tamanho) {
    for (int i = 0; i < TAMANHO_MAX; i++) {
        for (int j = 0; j < TAMANHO_MAX; j++) {
            int idx = i * TAMANHO_MAX + j;
            if (i < tamanho && j < tamanho) {
                int valor;
                do {
                    printf("Digite o valor da posicao [%d][%d] (0-255): ", i, j);
                    scanf("%d", &valor);
                } while (valor < 0 || valor > 255);
                matriz[idx] = (uint8_t)valor;
            } else {
                matriz[idx] = 0;
            }
        }
    }
}

int main() {
    uint8_t matrizA[TOTAL_ELEMENTOS] = {0};
    uint8_t matrizB[TOTAL_ELEMENTOS] = {0};
    int tamanho;
    int opcao;

    printf("Digite o tamanho da matriz (2 a 5): ");
    scanf("%d", &tamanho);
    if (tamanho < 2 || tamanho > 5) {
        printf("Tamanho invalido. Encerrando.\n");
        return 1;
    }

    printf("Escolha a operacao:\n");
    printf("0 - Soma\n1 - Subtracao\n2 - Multiplicacao de matrizes\n");
    printf("3 - Multiplicacao por inteiro\n4 - Oposta\n5 - Determinante\n6 - Transposta\n");
    scanf("%d", &opcao);
    if (opcao < 0 || opcao > 6) {
        printf("Operacao invalida. Encerrando.\n");
        return 1;
    }

    printf("Preencha a matriz A:\n");
    preencher_matriz(matrizA, tamanho);

    if (opcao <= 2) {  // Operacoes com duas matrizes
        printf("Preencha a matriz B:\n");
        preencher_matriz(matrizB, tamanho);
    } else if (opcao == 3) {  // Multiplicacao por inteiro^^
        int escalar;
        do {
            printf("Digite o escalar (0-255): ");
            scanf("%d", &escalar);
        } while (escalar < 0 || escalar > 255);
        matrizB[0] = (uint8_t)escalar;
        for (int i = 1; i < TOTAL_ELEMENTOS; i++) matrizB[i] = 0;
    } else {
        for (int i = 0; i < TOTAL_ELEMENTOS; i++) matrizB[i] = 0;
    }

    // Envia matrizes para a FPGA
    envia_matriz(matrizA, TOTAL_ELEMENTOS, FPGA_BASE);
    envia_matriz(matrizB, TOTAL_ELEMENTOS, FPGA_BASE);

    // Envia tamanho e operacao (opcode)
    envia_parametros(tamanho, opcao, FPGA_BASE);

    // Recebe resultado da FPGA
    uint8_t resultado[TOTAL_ELEMENTOS] = {0};
    recebe_matriz(resultado, TOTAL_ELEMENTOS, FPGA_RETORNO);

    printf("\nMatriz resultado:\n");
    for (int i = 0; i < tamanho; i++) {
        for (int j = 0; j < tamanho; j++) {
            printf("%3d ", resultado[i * TAMANHO_MAX + j]);
        }
        printf("\n");
    }

    return 0;
}
