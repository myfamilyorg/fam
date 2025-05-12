#include <unistd.h>

int x1();
int x0() { return x1(); }

int crate4(int argc, char **argv) {
	int r = write(2, "hi\n", 3);
	return x1();
}
