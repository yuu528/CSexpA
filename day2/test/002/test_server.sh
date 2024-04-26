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

OUT_A="./server.a.test.csv"
OUT_B="./server.b.test.csv"

MAX_EXP=18
SLEEP=3

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i with recv"
	$EXE_A $i >> $OUT_A
	sleep $SLEEP

	echo "Testing buffer size $i with read"
	$EXE_B $i >> $OUT_B
	sleep $SLEEP
done
