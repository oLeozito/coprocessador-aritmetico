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
    int filled;
    int i;

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

int main(void) {
    volatile uint32_t *LEDR_ptr;
    volatile uint32_t *RETURN_ptr;
    int fd = -1;
    void *LW_virtual;

    uint8_t matrizA[5][5] = {
        {1, 2, 3, 4, 5},
        {6, 7, 1, 2, 3},
        {4, 5, 6, 7, 1},
        {2, 3, 4, 5, 6},
        {7, 1, 2, 3, 4}
    };

    uint8_t matrizB[5][5] = {
        {5, 4, 3, 2, 1},
        {7, 6, 5, 4, 3},
        {2, 1, 7, 6, 5},
        {4, 3, 2, 1, 7},
        {6, 5, 4, 3, 2}
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

    *LEDR_ptr |= (1 << 29);
    *LEDR_ptr &= ~(1 << 31);

    int i;
    uint8_t valA;
    uint8_t valB;
    uint32_t word;

    printf("Enviando dados para o coprocessador:\n");

    for (i = 0; i < 25; i++) {
        while (((*RETURN_ptr) & (1 << 31)) == 1);

        valA = matrizA[i / 5][i % 5];
        valB = matrizB[i / 5][i % 5];

        word = 0;
        word |= (valA & 0xFF);
        word |= ((valB & 0xFF) << 8);
        word |= (0b111 << 16);

        *LEDR_ptr = word;
        *LEDR_ptr |= (1 << 31);

        while (((*RETURN_ptr) & (1 << 31)) == 0) {};
        *LEDR_ptr &= ~(1 << 31);

        print_progress_bar(i + 1, 25);
        usleep(100000);
    }

    printf("\nDados enviados com sucesso!\n");

    printf("\n(Processando dados)\n\n");

    printf("Recebendo dados de volta:\n");

    uint8_t matrizC[5][5];
    int indice = 0;
    uint32_t dado;
    uint8_t val1, val2, val3, val;

    while (indice < 25) {
        while (((*RETURN_ptr) & (1 << 30)) == 0);

        dado = *RETURN_ptr;

        if (indice <= 21) {
            val1 = (dado >> 0) & 0xFF;
            val2 = (dado >> 8) & 0xFF;
            val3 = (dado >> 16) & 0xFF;

            matrizC[indice / 5][indice % 5] = val1;
            matrizC[(indice + 1) / 5][(indice + 1) % 5] = val2;
            matrizC[(indice + 2) / 5][(indice + 2) % 5] = val3;

            indice += 3;
        } else {
            val = (dado >> 0) & 0xFF;
            matrizC[4][4] = val;
            indice++;
        }

        *LEDR_ptr |= (1 << 30);
        while (((*RETURN_ptr) & (1 << 30)) != 0);
        *LEDR_ptr &= ~(1 << 30);

        print_progress_bar(indice > 25 ? 25 : indice, 25);
        usleep(100000);
    }

    printf("\nDados recebidos com sucesso!\n\n");

    printf("Matriz Resultante:\n");
    int k = 0;
    int j;
    for (k = 0; k < 5; k++) {
        j = 0;
        for (j = 0; j < 5; j++) {
            printf("%3d ", matrizC[k][j]);
        }
        printf("\n");
    }

    munmap(LW_virtual, LW_BRIDGE_SPAN);
    close(fd);

    return 0;
}
