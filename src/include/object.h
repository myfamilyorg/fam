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

#ifndef _OBJECT_H__
#define _OBJECT_H__

#include <alloc.h>
#include <types.h>
#include <vtable.h>

typedef struct {
	void *vtable;
	void *data;
} ObjectImpl;

void object_cleanup(const ObjectImpl *obj);
#define Object ObjectImpl __attribute((cleanup(object_cleanup)))

void object_set_vtable(const ObjectImpl *obj, void *vtable);

#define let const Object
#define var Object

#define $object(...)                                    \
	({                                              \
		typeof(__VA_ARGS__) *_data__ =          \
		    alloc(sizeof(typeof(__VA_ARGS__))); \
		*_data__ = __VA_ARGS__;                 \
		ObjectImpl _ret__ = {.data = _data__};  \
		_ret__;                                 \
	})

#endif /* _OBJECT_H__ */
