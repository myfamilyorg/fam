#include <alloc.h>
#include <error.h>
#include <misc.h>
#include <print.h>

ssize_t snprintf(char *buf, size_t capacity, const char *fmt, ...);

STATIC size_t capacity_for(size_t bytes) {
	if (bytes < 64) return 64;
	bytes--;
	bytes |= bytes >> 4;
	bytes |= bytes >> 8;
	bytes |= bytes >> 16;
	bytes |= bytes >> 32;
	return bytes + 1;
}

STATIC int formatter_append(FormatterImpl *f, const char *s, size_t len) {
	if (f->size + len > f->capacity) {
		size_t ncapacity = capacity_for(f->size + len);
		void *tmp;
		tmp = resize(f->buf, ncapacity);
		if (!tmp) return -1;
		f->capacity = ncapacity;
		f->buf = tmp;
	}
	memcpy(f->buf + f->size, s, len);
	f->size += len;
	return 0;
}

void formatter_clear(FormatterImpl *f) {
	if (f->capacity) {
		release(f->buf);
		f->capacity = 0;
	}
}

int format_impl(FormatterImpl *f, const char *fmt, ...) {
	int ret = 0;
	Printable p;
	const char *ptr;

	__builtin_va_list args;
	__builtin_va_start(args, fmt);

	do {
		ptr = strstr(fmt, "{}");
		if (!ptr) break;
		if (formatter_append(f, fmt, ptr - fmt)) {
			ret = -1;
			break;
		}
		fmt = ptr + 2;
		p = __builtin_va_arg(args, Printable);

		if (p.pt == CSTR) {
			size_t len = strlen(p.value.cstring);
			if (formatter_append(f, p.value.cstring, len)) {
				ret = -1;
				break;
			}
		} else if (p.pt == UINT32) {
			char buf[1024];
			ssize_t len =
			    snprintf(buf, sizeof(buf), "%u", p.value.uint32);
			if (formatter_append(f, buf, len)) {
				ret = -1;
				break;
			}
		} else if (p.pt == INT64) {
			char buf[1024];
			ssize_t len =
			    snprintf(buf, sizeof(buf), "%lld", p.value.int64);
			if (formatter_append(f, buf, len)) {
				ret = -1;
				break;
			}
		}
	} while (true);

	__builtin_va_end(args);

	if (!ret) formatter_append(f, fmt, strlen(fmt));

	return ret;
}

ssize_t formatter_to_string(const FormatterImpl *f, char *out,
			    size_t capacity) {
	if (f == NULL || out == NULL) {
		err = EINVAL;
		return -1;
	}
	if (capacity < f->size)
		memcpy(out, f->buf, capacity);
	else
		memcpy(out, f->buf, f->size);
	return f->size;
}
