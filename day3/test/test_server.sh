#!/bin/bash

cd $(dirname $0)

SERVER_SL_DIR="../server_sl/"
SERVER_MT_DIR="../server_mt/"
SERVER_MP_DIR="../server_mp/"

SERVER_SL="server_sl.out"
SERVER_MT="server_mt.out"
SERVER_MP="server_mp.out"

OUT_SL="./server_sl.test.csv"
OUT_MT="./server_mt.test.csv"
OUT_MP="./server_mp.test.csv"

MAX_EXP=6 # Up to 1s

SLEEP=3

trapped=0

trap "trapped=1; echo 'Quit while'" SIGQUIT # Quit while loop with Ctrl+\

function run() {
	# $1 = dir, $2 = bin, $3 = sleep, $4 = log

	trapped=0

	"$1$2" $3 &

	pid=$!

	echo "Testing $2 with sleep $3 us [PID: $pid]"

	vmpeak=0
	max_sockets=0
	while [ $trapped -eq 0 ] && [ -e /proc/$pid/status ]; do
		# update VmPeak
		vmpeak_tmp=$(cat /proc/$pid/status | grep VmPeak | cut -f2 | tr -d ' kB')
		[ -e /proc/$pid/status ] && [ $vmpeak_tmp -gt $vmpeak ] && vmpeak=$vmpeak_tmp

		# update max sockets
		max_sockets_tmp=$(lsof -p $pid | grep TCP | wc -l)
		[ -e /proc/$pid/status ] && [ $max_sockets_tmp -gt $max_sockets ] && max_sockets=$max_sockets_tmp
	done

	[ -e /proc/$pid/status ] && kill $pid

	echo "$3,$vmpeak,$max_sockets" >> "$4"

	sleep $SLEEP
}

pushd "$SERVER_SL_DIR"
make
popd

pushd "$SERVER_MT_DIR"
make
popd

pushd "$SERVER_MP_DIR"
make
popd

echo "Sleep us,VmPeak,Max Sockets" > "$OUT_SL"
echo "Sleep us,VmPeak,Max Sockets" > "$OUT_MT"
echo "Sleep us,VmPeak,Max Sockets" > "$OUT_MP"

for i in $(cat <(echo 0) <(seq $MAX_EXP | xargs -n1 echo "10 ^" | bc)); do
	run "$SERVER_SL_DIR" "$SERVER_SL" $i "$OUT_SL"
	run "$SERVER_MT_DIR" "$SERVER_MT" $i "$OUT_MT"
	run "$SERVER_MP_DIR" "$SERVER_MP" $i "$OUT_MP"
done
