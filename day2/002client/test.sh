#!/bin/bash

EXE="./002client.out"
TARGET_IP="192.168.1.101"
TARGET_FILE="../10MB.txt"

OUT="./client.test.csv"
GRAPH_OUT="./client.test.png"

MAX_EXP=18
SLEEP=5

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE $TARGET_IP $TARGET_FILE $i >> $OUT
	sleep $SLEEP
done

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2

plot "$OUT" using 1:2 with linespoints pt 7 notitle
EOF
