#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#define LW_BRIDGE_BASE 0xFF200000
#define LW_BRIDGE_SPAN 0x00005000

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

// void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizA[5][5], uint8_t matrizB[5][5], uint8_t data) {
//     volatile uint32_t *RETURN_ptr = LEDR_ptr + 4;

//     printf("Enviando dados para o coprocessador:\n");

//     for (int i = 0; i < 25; i++) {
//         while (((*RETURN_ptr) & (1 << 31)) == 1);

//         uint8_t valA = matrizA[i / 5][i % 5];
//         uint8_t valB = matrizB[i / 5][i % 5];

//         uint32_t word = 0;
//         word |= (valA & 0xFF);
//         word |= ((valB & 0xFF) << 8);
//         word |= ((data & 0x3F) << 16);

//         *LEDR_ptr = word;
//         *LEDR_ptr |= (1 << 31);

//         while (((*RETURN_ptr) & (1 << 31)) == 0);
//         *LEDR_ptr &= ~(1 << 31);

//         print_progress_bar(i + 1, 25);
//         usleep(100000);
//     }

//     printf("\nDados enviados com sucesso!\n");
// }

// void receber_dados_da_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizC[5][5]) {
//     volatile uint32_t *RETURN_ptr = LEDR_ptr + 4;

//     printf("\n(Processando dados)\n\n");
//     printf("Recebendo dados de volta:\n");

//     int indice = 0;
//     while (indice < 25) {
//         while (((*RETURN_ptr) & (1 << 30)) == 0);

//         uint32_t dado = *RETURN_ptr;

//         if (indice <= 21) {
//             matrizC[indice / 5][indice % 5]         = (dado >> 0) & 0xFF;
//             matrizC[(indice + 1) / 5][(indice + 1) % 5] = (dado >> 8) & 0xFF;
//             matrizC[(indice + 2) / 5][(indice + 2) % 5] = (dado >> 16) & 0xFF;
//             indice += 3;
//         } else {
//             matrizC[4][4] = (dado >> 0) & 0xFF;
//             indice++;
//         }

//         *LEDR_ptr |= (1 << 30);
//         while (((*RETURN_ptr) & (1 << 30)) != 0);
//         *LEDR_ptr &= ~(1 << 30);

//         print_progress_bar(indice > 25 ? 25 : indice, 25);
//         usleep(100000);
//     }

//     printf("\nDados recebidos com sucesso!\n\n");
// }
