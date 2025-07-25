#ifndef _TEST_MAIN_H
#define _TEST_MAIN_H

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wvariadic-macros"
#pragma GCC diagnostic ignored "-Wpedantic"

#define UNIQUE_ID __COUNTER__
#define STRINGIFY(x) #x
#define EXPAND(x) x
#define EXPAND_ALL(...) __VA_ARGS__
#define CATI(x, y) x##y
#define CAT(x, y) CATI(x, y)
#define PAREN (
#define PAREN_END )

#define NONE(...)
#define FIRST(x, y) x
#define SECOND(x, y) y
#define FIRST_STRINGIFY(x, y) #x
#define SECOND_STRINGIFY(x, y) #y
#define BOTH(x, y) x y

#define loop while (true)

#define EMPTY()
#define DEFER1(m) m EMPTY()

#define EVAL(...) EVAL1024(__VA_ARGS__)
#define EVAL1024(...) EVAL512(EVAL512(__VA_ARGS__))
#define EVAL512(...) EVAL256(EVAL256(__VA_ARGS__))
#define EVAL256(...) EVAL128(EVAL128(__VA_ARGS__))
#define EVAL128(...) EVAL64(EVAL64(__VA_ARGS__))
#define EVAL64(...) EVAL32(EVAL32(__VA_ARGS__))
#define EVAL32(...) EVAL16(EVAL16(__VA_ARGS__))
#define EVAL16(...) EVAL8(EVAL8(__VA_ARGS__))
#define EVAL8(...) EVAL4(EVAL4(__VA_ARGS__))
#define EVAL4(...) EVAL2(EVAL2(__VA_ARGS__))
#define EVAL2(...) EVAL1(EVAL1(__VA_ARGS__))
#define EVAL1(...) __VA_ARGS__

#define MAP(m, arg, delim, first, ...) \
	m(arg, first) __VA_OPT__(      \
	    EXPAND_ALL delim DEFER1(_MAP)()(m, arg, delim, __VA_ARGS__))
#define _MAP() MAP

#define FOR_EACH(m, arg, delim, ...) \
	EVAL(__VA_OPT__(MAP(m, arg, delim, __VA_ARGS__)))

#define offsetof(type, member) ((u64) & (((type *)0)->member))

#pragma GCC diagnostic pop

unsigned char *strcpy(unsigned char *dest, const unsigned char *src);
void *memset(void *ptr, int x, unsigned long n);
int strcmp(const unsigned char *s1, const unsigned char *s2);
unsigned long double_to_string(unsigned char *buf, double v, int max_decimals);
long micros(void);

int cur_tests = 0;
int exe_test = 0;

TestEntry tests[MAX_TESTS];

extern void (*__init_array_start[])(void);
extern void (*__init_array_end[])(void);

void call_constructors(void) {
	void (**func)(void);
	for (func = __init_array_start; func < __init_array_end; func++) {
		(*func)();
	}
}

void add_test_fn(void (*test_fn)(void), const unsigned char *name) {
	if (strlen(name) > MAX_TEST_NAME) panic("test name too long!");
	if (cur_tests >= MAX_TESTS) panic("too many tests!");
	tests[cur_tests].test_fn = test_fn;
	memset(tests[cur_tests].name, 0, MAX_TEST_NAME);
	strcpy(tests[cur_tests].name, name);
	cur_tests++;
}

int main(int argc, char *argv[], unsigned char *envp[]);

#ifdef __aarch64__
__asm__(
    ".section .text\n"
    ".global _start\n"
    "_start:\n"
    "    ldr x0, [sp]\n"
    "    add x1, sp, #8\n"
    "    add x3, x0, #1\n"
    "    lsl x3, x3, #3\n"
    "    add x2, x1, x3\n"
    "    sub sp, sp, x3\n"
    "    bl main\n"
    "    mov x8, #93\n"
    "    svc #0\n");
#endif /* __aarch64__ */

int main(int argc __attribute__((unused)), char **argv __attribute__((unused)),
	 unsigned char **envp) {
	int test_count = 0, len;
	char *tp;
	u64 total;
	char buf[128];
	double ms;

	reset_allocated_bytes();
#ifndef COVERAGE
	call_constructors();
#endif

	environ = envp;
	init_environ();

	tp = getenv("TEST_PATTERN");
	if (!tp || !strcmp(tp, "*")) {
		println("{}Running {} tests{} ...", CYAN, cur_tests, RESET);
	} else {
		println("{}Running test{}: '{}' ...", CYAN, RESET, tp);
	}

	println(
	    "------------------------------------------------------------------"
	    "--------------------------");

	total = micros();

	for (exe_test = 0; exe_test < cur_tests; exe_test++) {
		if (!tp || !strcmp(tp, "*") ||
		    !strcmp(tests[exe_test].name, tp)) {
			u64 start;
			print("{}Running test{} {} [{}{}{}]", YELLOW, RESET,
			      1 + test_count, DIMMED, tests[exe_test].name,
			      RESET);
			start = micros();
			tests[exe_test].test_fn();
			println(" {}[{} {}s]{}", GREEN, (int)(micros() - start),
				"µ", RESET);
			test_count++;
		}
	}

	ms = (double)(micros() - total) / (double)1000;

	println(
	    "------------------------------------------------------------------"
	    "--------------------------");
	len = double_to_string(buf, ms, 3);
	buf[len] = 0;
	println("{}Success{}! {} {}tests passed!{} {}[{} ms]{}", GREEN, RESET,
		test_count, CYAN, RESET, GREEN, buf, RESET);

	return 0;
}

#endif /* _TEST_MAIN_H */
