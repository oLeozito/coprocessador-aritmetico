// biblioteca.h
#ifndef BIBLIOTECA_H
#define BIBLIOTECA_H

#include <stdint.h>

// Endereços fixos (usados apenas internamente pelo Assembly)
#define FPGA_BASE     0x00000000  // Endereço para enviar dados para a FPGA
#define FPGA_RETORNO  0x00000010  // Endereço para ler dados da FPGA

// Envia uma matriz para a FPGA
void envia_matriz(uint8_t* matriz, int tamanho);

// Envia os parâmetros da operação: tamanho e opcode
void envia_parametros(int tamanho, int opcode);

// Recebe uma matriz da FPGA
void recebe_matriz(uint8_t* resultado, int tamanho);

#endif // BIBLIOTECA_H
