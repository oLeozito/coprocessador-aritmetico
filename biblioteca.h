// biblioteca.h
#ifndef BIBLIOTECA_H
#define BIBLIOTECA_H

#include <stdint.h>

// Endereços de ponte HPS-FPGA (exemplos, ajuste conforme seu mapeamento)
#define FPGA_BASE     0x00000000  // Endereço para enviar dados para a FPGA
#define FPGA_RETORNO  0x00000010  // Endereço para ler dados da FPGA

// Envia uma matriz para a FPGA (endereço de destino especificado)
void envia_matriz(uint8_t* matriz, int tamanho, volatile uint32_t* endereco);

// Envia os parâmetros da operação: tamanho e opcode
void envia_parametros(int tamanho, int opcode, volatile uint32_t* endereco);

// Recebe uma matriz da FPGA (endereço de origem especificado)
void recebe_matriz(uint8_t* resultado, int tamanho, volatile uint32_t* endereco);

#endif // BIBLIOTECA_H
