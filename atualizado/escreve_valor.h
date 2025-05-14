// escreve_valor.h
#ifndef ESCREVE_VALOR_H
#define ESCREVE_VALOR_H

#include <stdint.h>
#include <sys/mman.h>

typedef struct {
    void* map_base;
    int fd;
} memoria_mapeada;

// Declaração corrigida (adicione 'extern' se necessário)
extern memoria_mapeada* mapear_memoria(void);
extern void liberar_memoria(memoria_mapeada* mem);
extern void escreve_valor(uint32_t* ponte);

#endif