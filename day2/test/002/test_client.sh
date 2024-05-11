#!/bin/bash

cd $(dirname $0)

pushd "../../002clienta"
make
popd

pushd "../../002clientb"
make
popd

EXE_A="../../002clienta/002clienta.out"
EXE_B="../../002clientb/002clientb.out"
TARGET_FILE="../../10MB.txt"

TARGET_IP="192.168.100.1"
TARGET_USER="pi"
TARGET_CSV_PATH_A="~/git/yuu528/CSexpA/day2/test/002/server.b.test.csv"
TARGET_CSV_PATH_B="~/git/yuu528/CSexpA/day2/test/002/server.a.test.csv"

OUT_A="./client.a.test.csv"
OUT_B="./client.b.test.csv"
SERVER_OUT_A="./server.a.test.csv"
SERVER_OUT_B="./server.b.test.csv"
GRAPH_OUT="./002.test.png"
SERVER_GRAPH_OUT="./002.server.test.png"

MAX_EXP=18
SLEEP=5

echo "Buffer size,Time" > $OUT_A
echo "Buffer size,Time" > $OUT_B

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i with send"
	$EXE_A $TARGET_IP $TARGET_FILE $i >> $OUT_A
	sleep $SLEEP

	echo "Testing buffer size $i with write"
	$EXE_B $TARGET_IP $TARGET_FILE $i >> $OUT_B
	sleep $SLEEP
done

scp "$TARGET_USER@$TARGET_IP:$TARGET_CSV_PATH_A" "./" &&
scp "$TARGET_USER@$TARGET_IP:$TARGET_CSV_PATH_B" "./" &&

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2
set logscale y

set xlabel "Buffer size"
set ylabel "Time (s)"

plot "$OUT_A" using 1:2 with linespoints pt 7 title "Client(send)", \
	"$OUT_B" using 1:2 with linespoints pt 9 title "Client(write)"

set output "$SERVER_GRAPH_OUT"
plot "$SERVER_OUT_A" using 1:2 with linespoints pt 7 title "Server(recv)", \
	"$SERVER_OUT_B" using 1:2 with linespoints pt 9 title "Server(read)"
EOF
