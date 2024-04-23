#!/bin/bash

EXE="./001.out"
TARGET_FILE="../10MB.txt"

OUT="./data.test.csv"

MAX_EXP=20

echo "Buffer size,Time" > $OUT

for i in $(seq 0 20 | xargs -n1 echo "2 ^" | bc); do
	$EXE $TARGET_FILE $i >> $OUT
done
