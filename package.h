#ifndef PACKAGE_H
#define PACKAGE_H

#include <stdint.h>

// Declaração das funções implementadas em Assembly
void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, volatile uint32_t *RETURN_ptr,
                            uint8_t matrizA[5][5], uint8_t matrizB[5][5]);

void print_progress_bar(int current, int total);

#endif // PACKAGE_H
