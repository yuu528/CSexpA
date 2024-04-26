#include "exp1.h"
#include "exp1lib.h"

int main(int argc, char** argv) {
  int sock_listen;
  int sock_client;
  struct sockaddr addr;
  int len = 0;
  int ret = 0;
  int buf_size;
  FILE* fp;

  if(argc != 2) {
    printf("usage: %s [buffer size]\n", argv[0]);
    exit(-1);
  }

  buf_size = atoi(argv[1]);
  char buf[buf_size];

  sock_listen = exp1_tcp_listen(11111);
  sock_client = accept(sock_listen, &addr, (socklen_t*) &len);

  fp = fopen("tmp.txt", "w");

	double t1 = get_current_timecount();

  ret = recv(sock_client, buf, buf_size, 0);
  while (ret > 0) {
    fwrite(buf, sizeof(char), ret, fp);
    ret = recv(sock_client, buf, buf_size, 0);
  }

  double t2 = get_current_timecount();

  close(sock_client);
  close(sock_listen);

	printf("%d,%lf\n", buf_size, t2 - t1);

  return 0;
}
