#!/bin/bash

cd $(dirname $0)

SERVER_NM_DIR="../server_nm/"
SERVER_SL_DIR="../server_sl/"
SERVER_MT_DIR="../server_mt/"
SERVER_MP_DIR="../server_mp/"

SERVER_NM="server_nm.out"
SERVER_SL="server_sl.out"
SERVER_MT="server_mt.out"
SERVER_MP="server_mp.out"

OUT_NM="./server_nm.test.csv"
OUT_SL="./server_sl.test.csv"
OUT_MT="./server_mt.test.csv"
OUT_MP="./server_mp.test.csv"

MAX_EXP=6 # Up to 1s

SLEEP=3

trapped=0

trap "trapped=1; echo 'Quit while'" SIGINT # Quit while loop with Ctrl+C

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
		[ -e /proc/$pid/status ] && [ $vmpeak_tmp -gt $vmpeak ] && vmpeak=$vmpeak_tmp && echo "VmPeak: $vmpeak"

		# update max sockets
		max_sockets_tmp=$(lsof -p $pid | grep TCP | wc -l)
		[ -e /proc/$pid/status ] && [ $max_sockets_tmp -gt $max_sockets ] && max_sockets=$max_sockets_tmp && echo "Max sockets: $max_sockets"
	done

	[ -e /proc/$pid/status ] && kill $pid

	echo "$3,$vmpeak,$max_sockets" | tee -a "$4"
}

[ $# -ne 2 ] && echo "Usage: $0 <NM/SL/MT/MP> <sleep>" && exit 1

case $1 in
	NM)
		dir="$SERVER_NM_DIR"
		server="$SERVER_NM"
		out="$OUT_NM"
		;;
	SL)
		dir="$SERVER_SL_DIR"
		server="$SERVER_SL"
		out="$OUT_SL"
		;;
	MT)
		dir="$SERVER_MT_DIR"
		server="$SERVER_MT"
		out="$OUT_MT"
		;;
	MP)
		dir="$SERVER_MP_DIR"
		server="$SERVER_MP"
		out="$OUT_MP"
		;;
	*)
		echo "Invalid argument: $1"
		exit 1
		;;
esac

pushd "$dir"
make
popd

echo "Sleep us,VmPeak,Max Sockets" > "$out"

run "$dir" "$server" $2 "$out"
