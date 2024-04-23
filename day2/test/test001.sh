#!/bin/bash

EXE_A="../001a/001a.out"
EXE_B="../001b/001b.out"
TARGET_FILE="../10MB.txt"

OUT_A="./001.a.test.csv"
OUT_B="./001.b.test.csv"
GRAPH_OUT="./001.test.png"

MAX_EXP=18

echo "Buffer size,Time" > $OUT_A
echo "Buffer size,Time" > $OUT_B

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE_A $TARGET_FILE $i >> $OUT_A
	$EXE_B $TARGET_FILE $i >> $OUT_B
done

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2
set logscale y

plot "$OUT_A" using 1:2 with linespoints pt 7 title "fread, fwrite", \
	"$OUT_B" using 1:2 with linespoints pt 7 title "read, write"
EOF
