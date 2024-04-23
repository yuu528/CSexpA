#!/bin/bash

EXE="./002server.out"

OUT="./server.test.csv"
GRAPH_OUT="./server.test.png"

MAX_EXP=18
SLEEP=3

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE $i >> $OUT
	sleep $SLEEP
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
