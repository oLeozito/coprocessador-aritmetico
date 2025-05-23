"""
*******************************************************************************************
Autores: João Gabriel, João Marcelo e Leonardo

Componente Curricular: TEC 499 - MI Sistemas Digitais
********************************************************************************************
"""


#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define LW_BRIDGE_BASE   0xFF200000
#define LW_BRIDGE_SPAN   0x00005000
#define LEDR_BASE        0x00000000
#define RETURN_BASE      0x00000010

void print_progress_bar(int current, int total) {
    int width = 25;
    int filled = (current * width) / total;
    int i;

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

int main(void) {
    volatile uint32_t *LEDR_ptr;
    volatile uint32_t *RETURN_ptr;
    int fd = -1;
    void *LW_virtual;

    // Variáveis de controle para testes
    uint8_t matrix_size_bits = 0b00; // tamanho da matriz (2 bits)
    // 00 = 2x2
    // 01 = 3x3
    // 10 = 4x4
    // 11 = 5x5
    uint8_t opcode_bits = 0b010;  // operação desejada (3 bits)
    // 000 = Soma OK
    // 001 = Subtração OK
    // 010 = Oposta 
    // 011 = Multiplicação
    // 100 = Transposta OK
    // 101 = Determinante
    // 110 = Multiplicação por Inteiro OK

    uint8_t matrizA[5][5] = {
        {1, 2, 3, 4, 5},
        {6, 7, 8, 9, 10},
        {11, 12, 13, 14, 15},
        {16, 17, 18, 19, 20},
        {21, 22, 23, 24, 25}
    };

    uint8_t matrizB[5][5] = {
        {50, 2, 2, 2, 2},
        {4, 4, 4, 2, 2},
        {5, 5, 5, 2, 2},
        {2, 2, 2, 2, 2},
        {2, 2, 2, 2, 2}
    };

    if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1) {
        printf("ERRO: não foi possível abrir \"/dev/mem\"...\n");
        return -1;
    }

    LW_virtual = mmap(NULL, LW_BRIDGE_SPAN, (PROT_READ | PROT_WRITE),
                      MAP_SHARED, fd, LW_BRIDGE_BASE);
    if (LW_virtual == MAP_FAILED) {
        printf("ERRO: mmap() falhou...\n");
        close(fd);
        return -1;
    }

    LEDR_ptr   = (uint32_t *) (LW_virtual + LEDR_BASE);
    RETURN_ptr = (uint32_t *) (LW_virtual + RETURN_BASE);

    *LEDR_ptr |= (1 << 29);  // sinalização inicial
    *LEDR_ptr &= ~(1 << 31); // desativa envio

    int i;
    uint8_t valA, valB;
    uint32_t word;

    printf("Enviando dados para o coprocessador:\n");

    for (i = 0; i < 25; i++) {
        while (((*RETURN_ptr) & (1 << 31)) == 1);

        valA = matrizA[i / 5][i % 5];
        valB = matrizB[i / 5][i % 5];

        word = 0;
        word |= (valA & 0xFF);
        word |= ((valB & 0xFF) << 8);
        word |= ((opcode_bits & 0x7) << 16);       // Bits 18:16 - opcode
        word |= ((matrix_size_bits & 0x3) << 19);  // Bits 20:19 - tamanho da matriz (agora 2 bits)

        *LEDR_ptr = word;
        *LEDR_ptr |= (1 << 31);

        while (((*RETURN_ptr) & (1 << 31)) == 0) {};
        *LEDR_ptr &= ~(1 << 31);

        print_progress_bar(i + 1, 25);
    }

    printf("\nDados enviados com sucesso!\n");
    printf("\n(Processando dados)\n\n");

    printf("Recebendo dados de volta:\n");

    uint8_t vetorC[25];
    int indice = 0;
    uint32_t dado;
    uint8_t val1, val2, val3, val;
    uint8_t overflow = 0;

    while (indice < 25) {
        while (((*RETURN_ptr) & (1 << 30)) == 0);

        dado = *RETURN_ptr;
        overflow = (dado >> 29) & 0x1;

        if (indice <= 21) {
            val1 = (dado >> 0) & 0xFF;
            val2 = (dado >> 8) & 0xFF;
            val3 = (dado >> 16) & 0xFF;

            vetorC[indice++] = val1;
            vetorC[indice++] = val2;
            vetorC[indice++] = val3;
        } else {
            val = (dado >> 0) & 0xFF;
            vetorC[indice++] = val;
        }

        *LEDR_ptr |= (1 << 30);
        while (((*RETURN_ptr) & (1 << 30)) != 0);
        *LEDR_ptr &= ~(1 << 30);

        print_progress_bar(indice > 25 ? 25 : indice, 25);
    }

    printf("\nDados recebidos com sucesso!\n\n");

    if (overflow)
        printf("Aviso: ocorreu overflow durante a operação!\n");

    printf("Matriz Resultante:\n");

    int tamanho = matrix_size_bits + 2; // 00->2x2, 01->3x3, 10->4x4, 11->5x5
    int linha, coluna;

    for (linha = 0; linha < tamanho; linha++) {
        for (coluna = 0; coluna < tamanho; coluna++) {
            // Cast para int8_t para interpretar corretamente valores negativos
            printf("%4d ", (int8_t)vetorC[linha * 5 + coluna]);
        }
        printf("\n");
    }

    return 0;
}
