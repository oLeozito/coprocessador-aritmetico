# Nome do executável final
TARGET = programa

# Arquivos-fonte
C_SRC = main.c
ASM_SRC = func.s

# Objetos gerados
OBJ = main.o func.o

# Compiladores
CC = gcc
AS = as

# Flags
CFLAGS = -Wall -O2 -g
LDFLAGS = -g

# Regra padrão
debug: $(TARGET)
		gdb --args ./$(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $(TARGET) $(LDFLAGS)

main.o: main.c escreve_valor.h
	$(CC) $(CFLAGS) -c main.c -o main.o

func.o: func.s
	$(AS) func.s -o func.o

clean:
	rm -f *.o $(TARGET)