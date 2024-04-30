#!/bin/bash

cd $(dirname $0)

pushd "../../002servera"
make
popd

pushd "../../002serverb"
make
popd

EXE_A="../../002servera/002servera.out"
EXE_B="../../002serverb/002serverb.out"

COPIED_FILE="tmp.txt"

OUT_A="./server.a.test.csv"
OUT_B="./server.b.test.csv"

MAX_EXP=18
SLEEP=3

rm $COPIED_FILE

echo "Buffer size,Time" > $OUT_A
echo "Buffer size,Time" > $OUT_B

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i with recv"
	$EXE_A $i >> $OUT_A
	du -b $COPIED_FILE
	sleep $SLEEP

	rm $COPIED_FILE

	echo "Testing buffer size $i with read"
	$EXE_B $i >> $OUT_B
	du -b $COPIED_FILE
	sleep $SLEEP

	rm $COPIED_FILE
done
