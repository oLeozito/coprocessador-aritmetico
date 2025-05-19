CC = gcc
CFLAGS = -Wall -O2

TARGET = main
OBJS = main.o package.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

main.o: main.c package.h
	$(CC) $(CFLAGS) -c main.c

package.o: package.c package.h
	$(CC) $(CFLAGS) -c package.c

clean:
	rm -f *.o $(TARGET)
