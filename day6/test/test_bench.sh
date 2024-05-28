#!/bin/bash

NM_DATA_CSV='nm.test.csv'
SL_DATA_CSV='sl.test.csv'
MP_DATA_CSV='mp.test.csv'
TH_DATA_CSV='th.test.csv'
AP_DATA_CSV='ap.test.csv'

TIME_DATA_PNG='time.test.png'
ERROR_DATA_PNG='error.test.png'

PROGRAM_DIR='../../day5/bench/'
PROGRAM_EXE='bench.out'

SLEEP=1
SLEEP_RETRY=5
RETRY=5

IP='192.168.100.1'
PORT='10028'
PORT_APACHE='80'
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

function wait_enter() {
	print_msg "Run $1 on target server and press [Enter] key."
	read
}

function run_test() {
	TARGET_CSV="$1"
	TARGET_PROGRAM="$2"
	TARGET_PORT="$3"

	wait_enter "\"$TARGET_PROGRAM\" program"

	echo 'threads,time,error_ratio' > "$TARGET_CSV"

	print_msg "Testing $TARGET_PROGRAM"

	for thread in ${THREADS[@]}; do
		try=0
		while [ $try -lt $RETRY ]; do
			print_msg "Testing with $thread threads"

			result=$("$PROGRAM_DIR$PROGRAM_EXE" "$IP" "$thread" "$TARGET_PORT" 2>&1)

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

		echo -n "$thread," >> "$TARGET_CSV"

		# get time
		# rev | cut -f1 | rev: get last field in the line
		echo "$result" | tee >(cat 1>&2) | tail -2 | head -1 | rev | cut -d' ' -f1 | rev | paste -sd, | tr -d '\n' >> "$TARGET_CSV"

		echo -n ',' >> "$TARGET_CSV"

		# error data rate (include size: 0)
		zero_b_cnt=$(echo "$result" | grep -c 'Recieved Size: 0 bytes')

		if [ $zero_b_cnt -eq 0 ]; then
			echo '0' >> "$TARGET_CSV"
		else
			echo "$zero_b_cnt / $thread" | bc -l >> "$TARGET_CSV"
		fi

		echo -e "\nZero Byte Count: $zero_b_cnt / $thread"

		sleep $SLEEP
	done
}

function plot_data() {
	gnuplot <<EOF
set terminal pngcairo
set output "$TIME_DATA_PNG"

set mono

set datafile separator ","

set logscale x
set logscale y

set key left top

set xlabel "Client Threads"
set ylabel "Time (sec.)"

plot "$NM_DATA_CSV" using 1:2 with linespoints pt 2 title "No multiplexing", \
	"$SL_DATA_CSV" using 1:2 with linespoints pt 7 title "select", \
	"$MP_DATA_CSV" using 1:2 with linespoints pt 5 title "fork", \
	"$TH_DATA_CSV" using 1:2 with linespoints pt 13 title "pthread", \
	"$AP_DATA_CSV" using 1:2 with linespoints pt 1 title "Apache"
EOF

	gnuplot <<EOF
set terminal pngcairo
set output "$ERROR_DATA_PNG"

set mono

set datafile separator ","

set logscale x

set key left top

set yrange [0:1]

set xlabel "Client Threads"
set ylabel "Error Rate"

plot "$NM_DATA_CSV" using 1:3 with linespoints pt 2 title "No multiplexing", \
	"$SL_DATA_CSV" using 1:3 with linespoints pt 7 title "select", \
	"$MP_DATA_CSV" using 1:3 with linespoints pt 5 title "fork", \
	"$TH_DATA_CSV" using 1:3 with linespoints pt 13 title "pthread", \
	"$AP_DATA_CSV" using 1:3 with linespoints pt 1 title "Apache"
EOF
}

cd $(dirname $0)

pushd "$PROGRAM_DIR"
make || exit 1
popd

if [ $# -ne 1 ]; then
	cat <<EOF
Usage: $0 <NM/SL/MP/TH/AP/PLOT>
	NM: No multiplexing
	SL: select
	MP: fork
	TH: pthread
	AP: Apache
	PLOT: plot data from NM, SL, MP and TH csv data files
EOF
	exit 1
fi

case "$1" in
	NM) run_test "$NM_DATA_CSV" 'normal' "$PORT";;
	SL) run_test "$SL_DATA_CSV" 'select' "$PORT";;
	MP) run_test "$MP_DATA_CSV" 'fork' "$PORT";;
	TH) run_test "$TH_DATA_CSV" 'pthread' "$PORT";;
	AP) run_test "$AP_DATA_CSV" 'apache' "$PORT_APACHE";;
	PLOT) plot_data;;
	*) echo "Invalid argument"; exit 1;;
esac
