#ifndef _FOR_EACH__
#define _FOR_EACH__

#define EXPAND(x) x
#define EXPAND_ALL(...) __VA_ARGS__

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

#endif /* _FOR_EACH__ */
