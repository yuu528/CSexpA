#!/bin/bash

cd $(dirname $0)

pushd "../../001a"
make
popd

pushd "../../001b"
make
popd

EXE_A="../../001a/001a.out"
EXE_B="../../001b/001b.out"
TARGET_FILE="../../10MB.txt"
COPIED_FILE="tmp.txt"

OUT_A="./001.a.test.csv"
OUT_B="./001.b.test.csv"
GRAPH_OUT="./001.test.png"

MAX_EXP=18

rm $COPIED_FILE

echo "Buffer size,Time" > $OUT_A
echo "Buffer size,Time" > $OUT_B

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i with fread/fwrite"
	$EXE_A $TARGET_FILE $i >> $OUT_A
	du -b $COPIED_FILE

	rm $COPIED_FILE

	echo "Testing buffer size $i with read/write"
	$EXE_B $TARGET_FILE $i >> $OUT_B
	du -b $COPIED_FILE

	rm $COPIED_FILE
done

gnuplot <<EOF
set terminal pngcairo
set output "$GRAPH_OUT"

set mono

set datafile separator ","

set logscale x 2
set logscale y

plot "$OUT_A" using 1:2 with linespoints pt 7 title "fread, fwrite", \
	"$OUT_B" using 1:2 with linespoints pt 5 title "read, write"
EOF
