CC=gcc
C++=g++
LD=g++
CFLAGS=-c -Wall -pedantic-errors -O3 -std=gnu11 -I../
LDFLAGS=
OBJECTS=001b.o ../exp1lib.o
EXECUTABLE=001b.out

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(C++) $(CFLAGS) $< -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm -f ${EXECUTABLE} *.out *.o tmp.txt core

