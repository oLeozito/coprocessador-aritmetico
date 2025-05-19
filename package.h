#ifndef PACKAGE_H
#define PACKAGE_H

#include <stdint.h>

void print_progress_bar(int current, int total);
void* configurar_mapeamento(int *fd);
void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, volatile uint32_t *RETURN_ptr,
                            uint8_t matrizA[5][5], uint8_t matrizB[5][5]);
void receber_dados_da_fpga(volatile uint32_t *LEDR_ptr, volatile uint32_t *RETURN_ptr,
                            uint8_t matrizC[5][5]);
void imprimir_matriz_resultado(uint8_t matrizC[5][5]);

#endif
