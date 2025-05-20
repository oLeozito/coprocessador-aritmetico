CC = arm-linux-gnueabihf-gcc
CFLAGS = -Wall
ASFLAGS = -mcpu=cortex-a9

all: main

main: main.o package.o
    $(CC) $(CFLAGS) -o $@ $^

main.o: main.c package.h
    $(CC) $(CFLAGS) -c $<

package.o: package.s
    $(CC) $(ASFLAGS) -c $< -o $@

clean:
    rm -f *.o main