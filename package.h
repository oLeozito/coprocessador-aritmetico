#ifndef PACKAGE_H
#define PACKAGE_H

#include <stdint.h>

// Funções em Assembly
extern void enviar_dados_para_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizA[5][5], uint8_t matrizB[5][5], uint8_t data);
extern void receber_dados_da_fpga(volatile uint32_t *LEDR_ptr, uint8_t matrizC[5][5]);
extern void imprimir_matriz_resultado(uint8_t matrizC[5][5]);

// Funções em C (auxiliares)
void print_progress_bar(int current, int total);
void* configurar_mapeamento(int *fd);

#endif