/********************************************************************************
 * MIT License
 *
 * Copyright (c) 2025 Christopher Gilliard
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 *******************************************************************************/

#include <misc.h>
#include <types.h>

size_t strlen(const char *X) {
	const char *Y;
	if (X == NULL) return 0;
	Y = X;
	while (*X) X++;
	return X - Y;
}

int strcmp(const char *X, const char *Y) {
	if (X == NULL || Y == NULL) {
		if (X == Y) return 0;
		return X == NULL ? -1 : 1;
	}
	while (*X == *Y && *X) {
		X++;
		Y++;
	}
	if ((byte)*X > (byte)*Y) return 1;
	if ((byte)*Y > (byte)*X) return -1;
	return 0;
}

int strcmpn(const char *X, const char *Y, size_t n) {
	while (n > 0 && *X == *Y && *X != '\0' && *Y != '\0') {
		X++;
		Y++;
		n--;
	}
	if (n == 0) return 0;
	return (byte)*X - (byte)*Y;
}

const char *strstr(const char *s, const char *sub) {
	if (s == NULL || sub == NULL) return NULL;
	for (; *s; s++) {
		const char *tmps = s, *tmpsub = sub;
		while (*(byte *)tmps == *(byte *)tmpsub && *tmps) {
			tmps++;
			tmpsub++;
		}
		if (*tmpsub == '\0') return s;
	}
	return NULL;
}

void *memset(void *dest, int c, size_t n) {
	__attribute__((aligned(16))) byte *s = (byte *)dest;
	__attribute__((aligned(16))) size_t i;

	if (dest == NULL || n == 0) {
		return dest;
	}

	for (i = 0; i < n; i++) {
		s[i] = (byte)c;
	}
	return dest;
}

void *memcpy(void *dest, const void *src, size_t n) {
	__attribute__((aligned(16))) byte *d = (byte *)dest;
	__attribute__((aligned(16))) const byte *s = (byte *)src;
	__attribute__((aligned(16))) size_t i;

	if (dest == NULL || src == NULL || n == 0) {
		return dest;
	}

	for (i = 0; i < n; i++) {
		d[i] = s[i];
	}
	return dest;
}

void bzero(void *s, size_t len) { memset(s, 0, len); }

size_t uint128_t_to_string(char *buf, __uint128_t v) {
	char temp[40];
	int i = 0, j = 0;

	if (v == 0) {
		buf[0] = '0';
		buf[1] = '\0';
		return 1;
	}

	while (v > 0) {
		temp[i++] = '0' + (v % 10);
		v /= 10;
	}

	for (; i > 0; j++) {
		buf[j] = temp[--i];
	}
	buf[j] = '\0';
	return j;
}

size_t int128_t_to_string(char *buf, __int128_t v) {
	int is_negative = v < 0;
	size_t len = 0;
	__uint128_t abs_v;

	const __int128_t int128_min = -((__int128_t)1 << 127);
	const __uint128_t int128_min_abs = (__uint128_t)1 << 127;

	if (is_negative) {
		buf[0] = '-';
		buf++;
		abs_v = v == int128_min ? int128_min_abs : (__uint128_t)(-v);
	} else {
		abs_v = (__uint128_t)v;
	}

	len = uint128_t_to_string(buf, abs_v);
	return is_negative ? len + 1 : len;
}

/* Convert a double to a decimal string in buf.
 * Caller must provide a buffer of at least 41 bytes (sign + 17 digits + point +
 * 17 digits + null). Returns the length of the string (excluding null
 * terminator).
 */
size_t double_to_string(char *buf, double v) {
	char temp[41];
	size_t len, i, pos = 0, frac_start, int_start;
	int digits, is_negative;
	unsigned long long int_part;
	double frac_part;

	/* Handle special cases: NaN, infinity */
	if (v != v) { /* NaN: v != v is true */
		temp[0] = 'n';
		temp[1] = 'a';
		temp[2] = 'n';
		len = 3;
		memcpy(buf, temp, len);
		buf[len] = '\0';
		return len;
	}
	if (v > 1.7976931348623157e308 || v < -1.7976931348623157e308) {
		/* Infinity */
		if (v < 0) {
			buf[pos++] = '-';
		}
		temp[0] = 'i';
		temp[1] = 'n';
		temp[2] = 'f';
		len = 3;
		memcpy(buf + pos, temp, len);
		len += pos;
		buf[len] = '\0';
		return len;
	}

	/* Handle sign */
	is_negative = v < 0;
	if (is_negative) {
		buf[pos++] = '-';
		v = -v;
	}

	/* Handle zero */
	if (v == 0.0) {
		buf[pos++] = '0';
		buf[pos] = '\0';
		return pos;
	}

	/* Integer part */
	int_part = (unsigned long long)v;
	frac_part = v - (double)int_part;
	int_start = pos;

	/* Convert integer part (in reverse) */
	if (int_part == 0) {
		buf[pos++] = '0';
	} else {
		while (int_part > 0) {
			temp[pos++ - int_start] = '0' + (int_part % 10);
			int_part /= 10;
		}
		/* Reverse integer digits */
		for (i = 0; i < pos - int_start; i++) {
			buf[int_start + i] = temp[pos - int_start - 1 - i];
		}
	}

	/* Decimal point */
	if (frac_part > 0) {
		buf[pos++] = '.';

		/* Fractional part (up to 17 digits for precision) */
		frac_start = pos;
		digits = 0;
		while (frac_part > 0 && digits < 17) {
			int digit;
			frac_part *= 10;
			digit = (int)frac_part;
			buf[pos++] = '0' + digit;
			frac_part -= digit;
			digits++;
		}

		/* Trim trailing zeros */
		while (pos > frac_start && buf[pos - 1] == '0') {
			pos--;
		}
		/* Remove decimal point if no fractional digits remain */
		if (pos == frac_start) {
			pos--; /* Remove '.' */
		}
	}

	buf[pos] = '\0';
	return pos;
}
