#!/bin/bash

EXE="./001.out"
TARGET_FILE="../10MB.txt"

OUT="./data.test.csv"
GRAPH_OUT="./data.test.png"

MAX_EXP=18

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE $TARGET_FILE $i >> $OUT
done

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2
set logscale y

plot "$OUT" using 1:2 with linespoints pt 7 notitle
EOF
