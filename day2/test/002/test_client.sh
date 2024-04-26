#!/bin/bash

cd $(dirname $0)

pushd "../../002client"
make
popd

EXE="../../002client/002client.out"
TARGET_FILE="../../10MB.txt"

TARGET_IP="192.168.100.1"
TARGET_USER="pi"
TARGET_CSV_PATH="~/git/yuu528/CSexpA/day2/test/002/server.test.csv"

OUT="./client.test.csv"
SERVER_OUT="./server.test.csv"
GRAPH_OUT="./002.test.png"

MAX_EXP=18
SLEEP=5

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE $TARGET_IP $TARGET_FILE $i >> $OUT
	sleep $SLEEP
done

scp "$TARGET_USER@$TARGET_IP:$TARGET_CSV_PATH" "./" &&

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2
set logscale y

plot "$OUT" using 1:2 with linespoints pt 7 title "Client", \
	"$SERVER_OUT" using 1:2 with linespoints pt 5 title "Server"
EOF
