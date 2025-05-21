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

/* Convert a 128-bit unsigned integer to a decimal string in buf.
 * Caller must provide a buffer of at least 40 bytes (39 digits + null).
 * Returns the length of the string (excluding null terminator).
 */
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

/* Convert a 128-bit signed integer to a decimal string in buf.
 * Caller must provide a buffer of at least 41 bytes (sign + 39 digits + null).
 * Returns the length of the string (excluding null terminator).
 */
size_t int128_t_to_string(char *buf, __int128_t v) {
	int is_negative = v < 0;
	size_t len = 0;
	__uint128_t abs_v;

	/* Define INT128_MIN as a signed 128-bit constant */
	const __int128_t int128_min = -((__int128_t)1 << 127);	  /* -2^127 */
	const __uint128_t int128_min_abs = (__uint128_t)1 << 127; /* 2^127 */

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
