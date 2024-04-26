#include "exp1.h"
#include "exp1lib.h"

int main(int argc, char** argv) {
  int sock;
  FILE* fp;
  int ret;
  int buf_size;

  if(argc != 4) {
    printf("usage: %s [ip address] [filename] [buffer size]\n", argv[0]);
    exit(-1);
  }

  buf_size = atoi(argv[3]);
  char buf[buf_size];


  sock = exp1_tcp_connect(argv[1], 11111);
  fp = fopen(argv[2], "r");

	double t1 = get_current_timecount();

  ret = fread(buf, sizeof(char), buf_size, fp);
  while(ret > 0) {
    send(sock, buf, ret, 0);
    ret = fread(buf, sizeof(char), buf_size, fp);
  }

  double t2 = get_current_timecount();

  close(sock);

	printf("%d,%lf\n", buf_size, t2 - t1);

  return 0;
}
