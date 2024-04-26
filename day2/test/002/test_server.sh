#!/bin/bash

cd $(dirname $0)

pushd "../../002server"
make
popd

EXE="../../002server/002server.out"

OUT="./server.test.csv"

MAX_EXP=18
SLEEP=3

echo "Buffer size,Time" > $OUT

for i in $(seq 0 $MAX_EXP | xargs -n1 echo "2 ^" | bc); do
	echo "Testing buffer size $i"
	$EXE $i >> $OUT
	sleep $SLEEP
done
