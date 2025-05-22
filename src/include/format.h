#ifndef _PRINT_H__
#define _PRINT_H__

#include <for_each.h>
#include <types.h>

#define FORMATTER_INIT {.buf = NULL, .capacity = 0, .size = 0}

#define PRINTABLE_CSTR(arg)                        \
	(Printable) {                              \
		CSTR, { .cstring = (char *)(arg) } \
	}
#define PRINTABLE_DOUBLE(arg)                                             \
	({                                                                \
		Printable _p;                                             \
		_Generic((arg),                                           \
		    double: ({                                            \
				 uint64_t u;                              \
				 memcpy(&u, &(arg), sizeof(uint64_t));    \
				 _p = (Printable){DOUBLE, {.d = u}};      \
				 _p;                                      \
			 }),                                              \
		    default: ({                                           \
				 _p = (Printable){CSTR, {.cstring = ""}}; \
				 _p;                                      \
			 }))                                              \
	})

#define TO_PRINTABLE(ignore, arg)                                           \
	_Generic((arg),                                                     \
	    uint8_t: (Printable){UINT8, {.uint128 = ((uint128_t)arg)}},     \
	    uint16_t: (Printable){UINT16, {.uint128 = ((uint128_t)arg)}},   \
	    uint32_t: (Printable){UINT32, {.uint128 = ((uint128_t)arg)}},   \
	    uint64_t: (Printable){UINT64, {.uint128 = ((uint128_t)arg)}},   \
	    uint128_t: (Printable){UINT128, {.uint128 = ((uint128_t)arg)}}, \
	    int8_t: (Printable){INT8, {.int128 = ((int128_t)arg)}},         \
	    int16_t: (Printable){INT16, {.int128 = ((int128_t)arg)}},       \
	    int32_t: (Printable){INT32, {.int128 = ((int128_t)arg)}},       \
	    int64_t: (Printable){INT64, {.int128 = ((int128_t)arg)}},       \
	    int128_t: (Printable){INT128, {.int128 = ((int128_t)arg)}},     \
	    char *: (Printable){CSTR, {.cstring = (char *)arg}},            \
	    Printable *: arg)

#define format(f, fmt, ...)                                                   \
	do {                                                                  \
		format_impl(f, fmt __VA_OPT__(, ) FOR_EACH(                   \
				   TO_PRINTABLE, ignore, (, ), __VA_ARGS__)); \
	} while (false);

#define print(fmt, ...)                                                       \
	do {                                                                  \
		Formatter __f = FORMATTER_INIT;                               \
		format_impl(&__f,                                             \
			    fmt __VA_OPT__(, ) FOR_EACH(TO_PRINTABLE, ignore, \
							(, ), __VA_ARGS__));  \
		write(1, __f.buf, __f.size);                                  \
	} while (false);

#define println(fmt, ...)                                                     \
	do {                                                                  \
		Formatter __f = FORMATTER_INIT;                               \
		format_impl(&__f,                                             \
			    fmt __VA_OPT__(, ) FOR_EACH(TO_PRINTABLE, ignore, \
							(, ), __VA_ARGS__));  \
		Printable __p = {CSTR, {.cstring = "\n"}};                    \
		format_impl(&__f, "{}", __p);                                 \
		write(1, __f.buf, __f.size);                                  \
	} while (false);

typedef enum {
	INT8,
	INT16,
	INT32,
	INT64,
	INT128,
	UINT8,
	UINT16,
	UINT32,
	UINT64,
	UINT128,
	DOUBLE,
	CSTR
} PrintType;

typedef struct {
	PrintType pt;
	union {
		uint128_t uint128;
		int128_t int128;
		double d;
		char *cstring;
	} value;
} Printable;

typedef struct {
	char *buf;
	size_t capacity;
	size_t size;
} FormatterImpl;

void formatter_clear(FormatterImpl *f);

#define Formatter FormatterImpl __attribute__((cleanup(formatter_clear)))

int format_impl(FormatterImpl *, const char *, ...);
ssize_t formatter_to_string(const FormatterImpl *, char *out, size_t capacity);

#endif /* _PRINT_H__ */
