#include "mylib.h"

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <unistd.h>

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

int main(int argc, char** argv) {
	int sock_listen;
	int sock_client;
	struct sockaddr addr;
	int len = 0;

	if(argc != 2) {
		fprintf(stderr, "Usage: %s <sleep>\n", argv[0]);
		exit(1);
	}

	sleep_us = atoi(argv[1]);

	sock_listen = tcp_listen(11111);

	while(true) {
		sock_client = accept(sock_listen, &addr, (socklen_t*) &len);
		echoBackLoop(sock_client);
		close(sock_client);
	}

	close(sock_listen);

	return 0;
}
