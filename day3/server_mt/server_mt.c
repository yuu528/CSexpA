#include "mylib.h"

#include <errno.h>
#include <netdb.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

#include <sys/select.h>
#include <sys/socket.h>

#define MAXCHILD 2000

void echoBackLoop(int acc) {
	char buf[512];
	ssize_t len = 0;

	while(true) {
		// get data from client
		if((len = recv(acc, buf, sizeof(buf), 0)) == -1) {
			perror("recv");
			return;
		}

		// check EOF
		if(len == 0) {
			fprintf(stderr, "recv:EOF\n");
			return;
		}

		// add return
		buf[len] = '\r';
		buf[len + 1] = '\n';

		fprintf(stderr, "[client]%s\n", buf);	// コンソールに出力
		strncat(buf, ":OK\r\n", sizeof(buf) - strlen(buf) - 1);
		len = strlen(buf);
		if((len = send(acc, buf, len, 0)) == -1) {		// クライアントに送信
			perror("send");
			return;
		}
	}
}

void* thread_func(void *arg) {
	int* accP = (int*)arg;
	int acc = *accP;
	free(accP);

	pthread_detach(pthread_self());

	// echoBackLoop関数は自分で作成すること
	echoBackLoop(acc);
	close(acc);

	pthread_exit(NULL);
}

void acceptLoop(int sock) {
	while(true) {
		struct sockaddr_storage from;
		socklen_t len = sizeof(from);
		int acc = 0;

		if((acc = accept(sock, (struct sockaddr *) &from, &len)) == -1) {
			// エラー処理
			if(errno != EINTR) {
				perror("accept");
			}
		} else {
			// クライアントからの接続が行われた場合
			char hbuf[NI_MAXHOST];
			char sbuf[NI_MAXSERV];
			getnameinfo((struct sockaddr *) &from, len, hbuf,
			   sizeof(hbuf), sbuf, sizeof(sbuf),
			   NI_NUMERICHOST | NI_NUMERICSERV);
			fprintf(stderr, "accept:%s:%s\n", hbuf, sbuf);

			// スレッド生成
			int* param = (int*)malloc(sizeof(int));
			*param = acc;
			pthread_t th;
			if(pthread_create(&th, NULL, thread_func, param) != 0) {
				perror("pthread_create");
				close(acc); // 切断
			}
		}
	}
}

int main(int argc, char** argv) {
	int sock_listen;

	sock_listen = tcp_listen(11111);
	acceptLoop(sock_listen);

	close(sock_listen);

	return 0;
}
