#include "mylib.h"

#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#include <sys/select.h>
#include <sys/socket.h>
#include <sys/wait.h>

#define MAXCHILD 2000

int sleep_us = 0;

void echoBackLoop(int acc) {
	char buf[512];
	ssize_t len = 0;

	while(true) {
		// get data from client
		if((len = recv(acc, buf, sizeof(buf), 0)) == -1) {
			perror("recv");
			return;
		}

		usleep(sleep_us);

		// check EOF
		if(len == 0) {
			fprintf(stderr, "recv:EOF\n");
			return;
		}

		// add return
		buf[len] = '\r';
		buf[len + 1] = '\n';
		buf[len + 2] = '\0';

		fprintf(stderr, "[client]%s\n", buf);	// コンソールに出力
		len = strlen(buf);
		if((len = send(acc, buf, len, 0)) == -1) {		// クライアントに送信
			perror("send");
			return;
		}
	}
}

void printChildProcessStatus(pid_t pid, int status) {
	fprintf(stderr, "sig_chld_handler:wait:pid=%d,status=%d\n", pid, status);
	fprintf(stderr, "  WIFEXITED:%d,WEXITSTATUS:%d,WIFSIGNALED:%d,"
		 "WTERMSIG:%d,WIFSTOPPED:%d,WSTOPSIG:%d\n", WIFEXITED(status),
		 WEXITSTATUS(status), WIFSIGNALED(status), WTERMSIG(status),
		 WIFSTOPPED(status),
		 WSTOPSIG(status));
}

// シグナルハンドラによって子プロセスのリソースを回収する
void sigChldHandler(int sig) {
	// 子プロセスの終了を待つ
	int status = -1;
	pid_t pid = wait(&status);

	// 非同期シグナルハンドラ内でfprintfを使うことは好ましくないが，
	// ここではプロセスの状態表示に簡単のため使うことにする
	printChildProcessStatus(pid, status);
}

void acceptLoop(int sock) {
	// 子プロセス終了時のシグナルハンドラを指定
	struct sigaction sa;
	sigaction(SIGCHLD, NULL, &sa);
	sa.sa_handler = sigChldHandler;
	sa.sa_flags = SA_NODEFER;
	sigaction(SIGCHLD, &sa, NULL);

	while (true) {
		struct sockaddr_storage from;
		socklen_t len = sizeof(from);
		int acc = 0;
		if ((acc = accept(sock, (struct sockaddr *) &from, &len)) == -1) {
			// エラー処理
			if (errno != EINTR) {
				perror("accept");
			}
		} else {
			// クライアントからの接続が行われた場合
			char hbuf[NI_MAXHOST];
			char sbuf[NI_MAXSERV];
			getnameinfo((struct sockaddr *) &from, len, hbuf, sizeof(hbuf),
			   sbuf, sizeof(sbuf),
			   NI_NUMERICHOST | NI_NUMERICSERV);
			fprintf(stderr, "accept:%s:%s\n", hbuf, sbuf);

			// プロセス生成
			pid_t pid = fork();
			if (pid == -1) {
				// エラー処理
				perror("fork");
				close(acc);
			} else if (pid == 0) {
				// 子プロセス
				close(sock);  // サーバソケットクローズ
				echoBackLoop(acc);
				close(acc);    // アクセプトソケットクローズ
				acc = -1;
				_exit(1);
			} else {
				// 親プロセス
				close(acc);    // アクセプトソケットクローズ
				acc = -1;
			}

			// 子プロセスの終了処理
			int status = -1;
			while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
				// 終了した(かつSIGCHLDでキャッチできなかった)子プロセスが存在する場合
				// WNOHANGを指定してあるのでノンブロッキング処理
				// 各子プロセス終了時に確実に回収しなくても新規クライアント接続時に回収できれば十分なため．
				printChildProcessStatus(pid, status);
			}
		}
	}
}

int main(int argc, char** argv) {
	int sock_listen;

	if(argc != 2) {
		fprintf(stderr, "Usage: %s <sleep>\n", argv[0]);
		exit(1);
	}

	sleep_us = atoi(argv[1]);

	sock_listen = tcp_listen(11111);
	acceptLoop(sock_listen);

	close(sock_listen);

	return 0;
}
