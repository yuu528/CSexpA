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

function print_msg() {
	sep=$(echo "$1" | wc -L | awk '{for(i=0;i<$1;i++) printf "="}')

	echo -e "\n$sep"
	echo "$1"
	echo -e "$sep\n"
}

cd $(dirname $0)

pushd "$TARGET_PROGRAM_DIR"
make || exit 1
popd

echo 'threads,time,error_ratio' > $DATA_CSV

for thread in ${THREADS[@]}; do
	try=0
	while [ $try -lt $RETRY ]; do
		print_msg "Testing with $thread threads"

		result=$("$TARGET_PROGRAM_DIR$TARGET_PROGRAM_EXE" "$IP" "$thread" 2>&1)

		exit_code=$?

		if [ $exit_code -eq 0 ]; then
			break
		else
			print_msg "Error! ($exit_code) Retrying..."

			sleep $SLEEP_RETRY
		fi

		try=$(($try + 1))
	done

	if [ $try -ge $RETRY ]; then
		print_msg "Failed to get result for $thread threads"
		continue
	fi

	echo -n "$thread," >> $DATA_CSV

	# get time
	# rev | cut -f1 | rev: get last field in the line
	echo "$result" | tee >(cat 1>&2) | tail -2 | head -1 | rev | cut -d' ' -f1 | rev | paste -sd, | tr -d '\n' >> $DATA_CSV

	echo -n ',' >> $DATA_CSV

	# error data rate (include size: 0)
	zero_b_cnt=$(echo "$result" | grep -c 'Recieved Size: 0 bytes')

	if [ $zero_b_cnt -eq 0 ]; then
		echo '0' >> $DATA_CSV
	else
		echo "$zero_b_cnt / $thread" | bc -l >> $DATA_CSV
	fi

	echo -e "\nZero Byte Count: $zero_b_cnt / $thread"

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
