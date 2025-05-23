#ifndef PACKAGE_H
#define PACKAGE_H

#include <stdint.h>

void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizA[5][5], uint8_t matrizB[5][5], uint8_t data);
void receber_dados_da_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizC[5][5]);
void* configurar_mapeamento(int *fd);


void print_progress_bar(int current, int total);  // Se essa função estiver em outro .c, inclua o .h correto

#endif
