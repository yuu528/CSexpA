#include "exp1.h"
#include "exp1lib.h"

int main(int argc, char** argv) {
	int fdr;
	int fdw;
	int ret;
	int buf_size;

	if(argc != 3) {
		printf("usage: %s [filename] [buffer size]\n", argv[0]);
		exit(-1);
	}

	buf_size = atoi(argv[2]);
	char buf[buf_size];

	fdr = open(argv[1], O_RDONLY);
	fdw = open("tmp.txt", O_WRONLY);

	double t1 = get_current_timecount();

	ret = read(fdr, buf, buf_size);
	while (ret > 0) {
		write(fdw, buf, ret);
		ret = read(fdr, buf, buf_size);
	}

	double t2 = get_current_timecount();

	close(fdr);
	close(fdw);

	printf("%d,%lf\n", buf_size, t2 - t1);

	return 0;
}
