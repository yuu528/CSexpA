#!/bin/bash

cd $(dirname $0)

CLIENT_DIR="../tcpbenchmark/"
CLIENT="tcpbenchmark"

IP="192.168.100.1"
PORT="11111"

DATA_SIZE=100

MAX_THREAD=100
THREAD_STEP=10

OUT="./client.test.csv"

SLEEP=3

[ $# -ne 1 ] && echo "Usage: $0 <threads>" && exit 1

pushd "$CLIENT_DIR"
make
popd

echo "thread,success,failedConnect,failedSendRecvLoop,failedSendRecv,connectTime(total),connectTime(average),connectTime(sample variance),connectTime(max),sendRecvTime(total),sendRecvTime(average),sendRecvTime(sample variance),sendRecvTime(max),benchmarkTime(include failed)" > "$OUT"

"$CLIENT_DIR$CLIENT" $IP $PORT $1 $DATA_SIZE 1 | tail -2 | head -1 | tee -a "$OUT"
