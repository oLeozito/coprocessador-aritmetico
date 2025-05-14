#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/mman.h>
#include "escreve_valor.h"

int main() {
    printf("Iniciando mapeamento de memoria...\n");
    
    memoria_mapeada* mem = mapear_memoria();
    
    if (mem == NULL) {
        perror("Erro ao alocar estrutura de mapeamento");
        printf("Errno: %d\n", errno);
        return EXIT_FAILURE;
    }
    
    if (mem->map_base == MAP_FAILED) {
        perror("Erro no mapeamento de memoria");
        printf("Endereço retornado :%p\n", mem->map_base);
        liberar_memoria(mem);
        return EXIT_FAILURE;
    }

    printf("Memoria mapeada com sucesso!\n");
    printf("Endereco: %p\n", mem->map_base);
    printf("File descriptor: %d\n", mem->fd);

    liberar_memoria(mem);
    return EXIT_SUCCESS;
}