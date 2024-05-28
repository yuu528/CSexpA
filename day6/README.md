# Day6プログラム
## 内容
### shserv_{sl,mp,th}
それぞれ
- sl: select使用
- mp: fork使用 (Multi Process)
- th: pthread使用

### test
テスト用スクリプト

使用方法:
```
./test_bench.sh <NM/SL/MP/TH/PLOT>
```

1. スクリプトの`PROGRAM_DIR`、`PROGRAM_EXE`変数にベンチマークプログラムの場所を指定する
2. NM、SL、MP、THで非多重化、select多重化、fork多重化、pthread多重化サーバのデータを取る
3. PLOTで1のデータを全部まとめたグラフを作る

