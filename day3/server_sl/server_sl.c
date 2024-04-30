#include "mylib.h"

#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/select.h>
#include <sys/socket.h>

#define MAXCHILD 2000

int sleep_us = 0;

bool echoBack(int acc) {
	char buf[512];
	ssize_t len = 0;

	// get data from client
	if((len = recv(acc, buf, sizeof(buf), 0)) == -1) {
		perror("recv");
		return false;
	}

	usleep(sleep_us);

	// check EOF
	if(len == 0) {
		fprintf(stderr, "recv:EOF\n");
		return false;
	}

	// add return
	buf[len] = '\r';
	buf[len + 1] = '\n';
	buf[len + 2] = '\0';

	fprintf(stderr, "[client]%s\n", buf);	// コンソールに出力
	len = strlen(buf);
	if((len = send(acc, buf, len, 0)) == -1) {		// クライアントに送信
		perror("send");
		return false;
	}

	return true;
}

void acceptLoop(int sock) {
	// クライアント管理配列
	int childNum = 0;
	int child[MAXCHILD];
	int i = 0;
	for(i = 0; i < MAXCHILD; i++) {
		child[i] = -1;
	}

	while(true) {
		// select用マスクの初期化
		fd_set mask;
		FD_ZERO(&mask);
		FD_SET(sock, &mask);  // ソケットの設定
		int width = sock + 1;
		int i = 0;
		for(i = 0; i < childNum; i++) {
			if(child[i] != -1) {
				FD_SET(child[i], &mask);  // クライアントソケットの設定
				if( width <= child[i] ) {
					width = child[i] + 1;
				}
			}
		}

		// マスクを設定
		fd_set ready = mask;

		// タイムアウト値のセット
		struct timeval timeout;
		timeout.tv_sec = 600;
		timeout.tv_usec = 0;

		switch(select(width, (fd_set *) &ready, NULL, NULL, &timeout)) {
			case -1:
				// エラー処理
				perror("select");
				break;

			case 0:
				// タイムアウト
				break;

			default:
				// I/Oレディあり

				if(FD_ISSET(sock, &ready)) {
					// サーバソケットレディの場合
					struct sockaddr_storage from;
					socklen_t len = sizeof(from);
					int acc = 0;
					if((acc = accept(sock, (struct sockaddr *) &from, &len))
						== -1) {
						// エラー処理
						if (errno != EINTR) {
							perror("accept");
						}
					} else {
						// クライアントからの接続が行われた場合
						char hbuf[NI_MAXHOST];
						char sbuf[NI_MAXSERV];
						getnameinfo(
							(struct sockaddr *) &from, len, hbuf,
							sizeof(hbuf), sbuf, sizeof(sbuf),
							NI_NUMERICHOST | NI_NUMERICSERV
						);
						fprintf(stderr, "accept:%s:%s\n", hbuf, sbuf);

						// クライアント管理配列に登録
						int pos = -1;
						int i = 0;
						for(i = 0; i < childNum; i++) {
							if(child[i] == -1) {
								pos = i;
								break;
							}
						}

						if(pos == -1) {
							if(childNum >= MAXCHILD) {
								// 並列数が上限に達している場合は切断する
								fprintf(stderr, "child is full.\n");
								close(acc);
							} else {
								pos = childNum;
								childNum = childNum + 1;
							}
						}

						if(pos != -1) {
							child[pos] = acc;
						}
					}
				}

				// アクセプトしたソケットがレディの場合を確認する
				int i = 0;
				for(i = 0; i < childNum; i++) {
					if(child[i] != -1 && FD_ISSET(child[i], &ready)) {
						// クライアントとの通信処理
						// エコーバックを行う（echoBack関数は自分で作成すること）
						if(echoBack(child[i]) == false) {
							close(child[i]);
							child[i] = -1;
						}
					}
				}
		}
	}
}

int main(int argc, char** argv) {
	int sock_listen;

	if(argc != 2) {
		fprintf(stderr, "Usage: %s <sleep us>\n", argv[0]);
		exit(1);
	}

	sleep_us = atoi(argv[1]);

	sock_listen = tcp_listen(11111);
	acceptLoop(sock_listen);

	close(sock_listen);

	return 0;
}
