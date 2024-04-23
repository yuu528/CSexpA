CC=gcc
C++=g++
LD=g++
CFLAGS=-c -Wall -pedantic-errors -O3 -std=gnu11 -I../
LDFLAGS=
OBJECTS=001.o ../exp1lib.o
EXECUTABLE=001

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@.out

.cpp.o:
	$(C++) $(CFLAGS) $< -o $@.out

.c.o:
	$(CC) $(CFLAGS) $< -o $@.out

clean:
	-rm -f ${EXECUTABLE} *.out *.o tmp.txt core

