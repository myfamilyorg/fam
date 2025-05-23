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
#include <error.h>
#include <types.h>

typedef enum {
	ObjectTypeUint,
	ObjectTypeInt,
	ObjectTypeFloat,
	ObjectTypeBool,
	ObjectTypeErr,
	ObjectTypeBox
} ObjectType;

typedef uint128_t ObjectImpl;
void object_cleanup(const ObjectImpl *obj);
#define Object ObjectImpl __attribute((cleanup(object_cleanup)))

typedef struct {
	const char *type_name;
	void (*drop)(const ObjectImpl *);
} TypeDescriptor;

typedef struct {
	TypeDescriptor descriptor;
	void *table;
} Vtable;

ObjectType object_type(const ObjectImpl *obj);
ObjectImpl object_create_uint(uint64_t value);
ObjectImpl object_create_int(int64_t value);
ObjectImpl object_create_float(double value);
ObjectImpl object_create_bool(bool value);
ObjectImpl object_create_err(int code);
ObjectImpl object_create_boxed(Vtable *vtable, void *data);
void object_set_vtable(const ObjectImpl *obj, void *table);
void *object_get_vtable(const ObjectImpl *obj);
void *object_get_data(const ObjectImpl *obj);
void *resize_data(const ObjectImpl *obj, size_t nsize);

#define let const Object
#define var Object

#define CATI(x, y) x##y
#define CAT(x, y) CATI(x, y)

#define $object(type, ...)                                                     \
	({                                                                     \
		typeof(__VA_ARGS__) *_data__ = alloc(sizeof(type));            \
		ObjectImpl _ret__;                                             \
		if (_data__) {                                                 \
			*_data__ = (type)(__VA_ARGS__);                        \
			_ret__ =                                               \
			    object_create_boxed(&CAT(type, _Vtable), _data__); \
		} else {                                                       \
			_ret__ = object_create_err(ENOMEM);                    \
		}                                                              \
		_ret__;                                                        \
	})

#endif /* _OBJECT_H__ */

