#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include "escreve_valor.h"


#define LW_BRIDGE_BASE  0xFF200000
#define MAP_SIZE        0x1000


int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open");
        return -1;
    }

    void *map_base = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, LW_BRIDGE_BASE);
    if (map_base == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return -1;
    }

    uint32_t *ponte = (uint32_t *)map_base;
    escreve_valor(ponte);

    munmap(map_base, MAP_SIZE);
    close(fd);
    return 0;
}
