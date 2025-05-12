#include <unistd.h>

int x1();

int main(int argc, char **argv) {
	write(2, "hi\n", 3);
	return x1();
}
