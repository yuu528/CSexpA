CC=gcc
C++=g++
LD=g++
CFLAGS=-c -Wall -pedantic-errors -O0 -g3 -I ../
LDFLAGS=-pthread
OBJECTS=server_mt.o ../mylib.o
EXECUTABLE=server_mt.out

all: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

.cpp.o:
	$(C++) $(CFLAGS) $< -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	-rm -f ${EXECUTABLE} ${EXECUTABLE}.exe ${OBJECTS} core tmp.txt

