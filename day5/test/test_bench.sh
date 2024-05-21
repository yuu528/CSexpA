#!/bin/bash

DATA_CSV='bench.test.csv'
DATA_PNG='bench.test.png'

TARGET_PROGRAM_DIR='../bench/'
TARGET_PROGRAM_EXE='bench.out'

SLEEP=1
SLEEP_RETRY=5
RETRY=5

IP='192.168.100.1'
THREADS=(
	1
	2
	5
	10
	20
	50
	100
	200
	500
	1000
)

cd $(dirname $0)

pushd "$TARGET_PROGRAM_DIR"
make || exit 1
popd

echo 'threads,time,error_ratio' > $DATA_CSV

for thread in ${THREADS[@]}; do
	echo -e "\n============================"
	echo "Testing with $thread threads"
	echo -e "============================\n"

	try=0
	while [ $try -lt $RETRY ]; do
		result=$("$TARGET_PROGRAM_DIR$TARGET_PROGRAM_EXE" "$IP" "$thread" 2>&1)

		exit_code=$?

		if [ $exit_code -eq 0 ]; then
			break
		else
			echo -e "\n============================"
			echo "Error! ($exit_code) Retrying..."
			echo -e "============================\n"

			sleep $SLEEP_RETRY
		fi

		try=$(($try + 1))
	done

	if [ $try -ge $RETRY ]; then
		echo -e "\n============================"
		echo "Failed to get result for $thread threads"
		echo -e "============================\n"
		continue
	fi

	echo -n "$thread," >> $DATA_CSV

	# rev | cut -f1 | rev: get last field in the line
	echo "$result" | tee >(cat 1>&2) | tail -2 | rev | cut -d' ' -f1 | rev | paste -sd, >> $DATA_CSV

	sleep $SLEEP
done

gnuplot <<EOF
set terminal pngcairo
set output "$DATA_PNG"

set mono

set datafile separator ","

set ytics nomirror
set y2tics

set y2range [0:1]

set logscale x
set logscale y

set xlabel "Client Threads"
set ylabel "Time (sec.)"
set y2label "Error Ratio"

plot "$DATA_CSV" using 1:2 with linespoints pt 7 title "Total Time", \
	"$DATA_CSV" using 1:3 with linespoints pt 5 title "Error Ratio" axes x1y2
EOF
