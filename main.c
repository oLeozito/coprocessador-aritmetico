#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define LW_BRIDGE_BASE   0xFF200000
#define LW_BRIDGE_SPAN   0x00005000
#define LEDR_BASE        0x00000000
#define RETURN_BASE      0x00000010

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
    int i = 0;

    *LEDR_ptr |= (0 << 31); // Zera o bit 31 antes de começar, pra evitar erros.

    for (i; i < 25; i++) {

        while (((*RETURN_ptr) & (1 << 31)) == 1);

        uint8_t valA = matrizA[i / 5][i % 5];
        uint8_t valB = matrizB[i / 5][i % 5];

        uint32_t word = 0;
        word |= (valA & 0xFF);            // bits 7:0
        word |= ((valB & 0xFF) << 8);     // bits 15:8
        word |= (0b111 << 16);            // bits 18:16 = opcode

        *LEDR_ptr = word;  // Envia dados (sem bit 31)
        printf("LEDR_ptr = 0x%08X\n", *LEDR_ptr);
        printf("indice: %d\n",i);

        // Agora ativa o bit 31 separadamente
        *LEDR_ptr |= (1 << 31);
        printf("flag = 1\n");
        // Espera resposta do coprocessador (bit 31 de retorno = 1)
        while (((*RETURN_ptr) & (1 << 31)) == 0){};

        // Limpa bit 31 do LEDR
        *LEDR_ptr &= ~(1 << 31);
        printf("flag = 0\n");

        usleep(100000); // pequena pausa
    }

    // AQUI
    uint8_t matrizC[5][5];
    int indice = 0;

    while (indice < 25) {
        while (((*RETURN_ptr) & (1 << 30)) == 0); // Espera bit 30 setado

        uint32_t dado = *RETURN_ptr;

        if (indice <= 21) {
            uint8_t val1 = (dado >> 0) & 0xFF;
            uint8_t val2 = (dado >> 8) & 0xFF;
            uint8_t val3 = (dado >> 16) & 0xFF;

            matrizC[indice / 5][indice % 5] = val1;
            matrizC[(indice + 1) / 5][(indice + 1) % 5] = val2;
            matrizC[(indice + 2) / 5][(indice + 2) % 5] = val3;

            indice += 3;
        } else {
            uint8_t val = (dado >> 0) & 0xFF;
            matrizC[4][4] = val;
            indice++;
        }

        *LEDR_ptr |= (1 << 30); // Sinaliza para a FPGA que já leu

        while (((*RETURN_ptr) & (1 << 30)) != 0); // Espera a FPGA limpar

        *LEDR_ptr &= ~(1 << 30); // Limpa flag do HPS
    }

    printf("Matriz C recebida com sucesso:\n");
    
    // AQUI

    munmap(LW_virtual, LW_BRIDGE_SPAN);
    close(fd);

    return 0;
}
