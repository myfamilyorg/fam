#ifndef _PRINT_H__
#define _PRINT_H__

#include <for_each.h>
#include <types.h>

#define FORMATTER_INIT {.buf = NULL, .capacity = 0, .size = 0}

#define TO_PRINTABLE(ignore, arg)                                       \
	_Generic((arg),                                                 \
	    uint32_t: (Printable){UINT32, {.uint32 = ((uint64_t)arg)}}, \
	    int: (Printable){INT64, {.int64 = ((int64_t)arg)}},         \
	    int64_t: (Printable){INT64, {.int64 = ((int64_t)arg)}},     \
	    char *: (Printable){CSTR, {.cstring = ((char *)arg)}},      \
	    const char *: (Printable){CSTR, {.cstring = ((char *)arg)}})

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
	UINT8,
	UINT16,
	UINT32,
	UINT64,
	CSTR
} PrintType;

typedef struct {
	PrintType pt;
	union {
		int8_t int8;
		int16_t int16;
		int32_t int32;
		int64_t int64;
		uint8_t uint8;
		uint16_t uint16;
		uint32_t uint32;
		uint64_t uint64;
		uint128_t uint128;
		int128_t int128;
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
