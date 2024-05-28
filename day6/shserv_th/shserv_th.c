#include "../exp1.h"
#include "../exp1lib.h"

void* exp1_thread(void *param) {
	int* psock;
	int sock;

	pthread_detach(pthread_self());
	psock = (int*) param;
	sock = *psock;
	free(psock);

	exp1_http_session(sock);

	close(sock);
	shutdown(sock, SHUT_RDWR);
}

void exp1_create_thread(int sock) {
	int *psock;
	pthread_t th;
	psock = malloc(sizeof(int));
	*psock = sock;

	pthread_create(&th, NULL, exp1_thread, psock);
	printf("thread %d is created\n", sock);
}

int main(int argc, char **argv) {
	int sock_listen;

	sock_listen = exp1_tcp_listen(10028);

	while(1){
		struct sockaddr addr;
		int sock_client;
		int len;

		sock_client = accept(sock_listen, &addr, (socklen_t*) &len);

		exp1_create_thread(sock_client);
	}
}
