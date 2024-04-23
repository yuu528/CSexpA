#include "exp1.h"
#include "exp1lib.h"

int main(int argc, char** argv) {
	FILE* fpr;
	FILE* fpw;
	int ret;
	int buf_size;

	if(argc != 3) {
		printf("usage: %s [filename] [buffer size]\n", argv[0]);
		exit(-1);
	}

	buf_size = atoi(argv[2]);
	char buf[buf_size];

	fpr = fopen(argv[1], "r");
	fpw = fopen("tmp.txt", "w");

	double t1 = get_current_timecount();

	ret = fread(buf, sizeof(char), buf_size, fpr);
	while (ret > 0) {
		fwrite(buf, sizeof(char), ret, fpw);
		ret = fread(buf, sizeof(char), buf_size, fpr);
	}

	double t2 = get_current_timecount();

	fclose(fpr);
	fclose(fpw);

	printf("%d,%lf\n", buf_size, t2 - t1);

	return 0;
}
