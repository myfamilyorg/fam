#include <alloc.h>
#include <format.h>
#include <misc.h>
#include <object.h>

#define UINT_MASK 0x1
#define INT_MASK 0x2
#define FLOAT_MASK 0x3
#define BOOL_MASK 0x4
#define ERR_MASK 0x5
#define BOX_MASK 0x0

#define UNMASK 0x7

typedef struct {
	Vtable *vtable;
	union {
		uint64_t uint_value;
		int64_t int_value;
		double float_value;
		bool bool_value;
		int err;
		void *data;
	} value;
} ObjectData;

void object_cleanup(const ObjectImpl *obj) {
	if (obj) {
		ObjectType t = object_type(obj);
		if (t == ObjectTypeBox) {
			void *type_data = NULL;
			ObjectData *data = (ObjectData *)(uint64_t)(obj);
			if (data->value.data) {
				data->vtable->descriptor.drop(obj);
				release(type_data);
				data->value.data = NULL;
			}
		}
	}
}

ObjectType object_type(const ObjectImpl *obj) {
	ObjectData *objdata = (ObjectData *)obj;
	uint64_t tag = (uint64_t)objdata->vtable & 0x7;
	switch (tag) {
		case BOOL_MASK:
			return ObjectTypeBool;
		case UINT_MASK:
			return ObjectTypeUint;
		case INT_MASK:
			return ObjectTypeInt;
		case FLOAT_MASK:
			return ObjectTypeFloat;
		case ERR_MASK:
			return ObjectTypeErr;
		case BOX_MASK:
			return ObjectTypeBox;
		default:
			$println("Unknown type");
			return ObjectTypeBox;
	}
}

ObjectImpl object_create_uint(uint64_t value) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {
	    .data = {.vtable = (void *)UINT_MASK, .value.uint_value = value}};
	return u.impl;
}

ObjectImpl object_create_int(int64_t value) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {.data = {.vtable = (void *)INT_MASK, .value.int_value = value}};
	return u.impl;
}

ObjectImpl object_create_float(double value) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {
	    .data = {.vtable = (void *)FLOAT_MASK, .value.float_value = value}};
	return u.impl;
}

ObjectImpl object_create_bool(bool value) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {
	    .data = {.vtable = (void *)BOOL_MASK, .value.bool_value = value}};
	return u.impl;
}

ObjectImpl object_create_err(int value) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {.data = {.vtable = (void *)ERR_MASK, .value.err = value}};
	return u.impl;
}

ObjectImpl object_create_boxed(Vtable *vtable, void *data) {
	union {
		ObjectData data;
		ObjectImpl impl;
	} u = {.data = {.vtable = vtable, .value.data = data}};
	return u.impl;
}

void object_set_vtable(const ObjectImpl *obj, void *table) {
	ObjectData *data = NULL;
	uint64_t tag;
	if (!obj) return;
	data = (ObjectData *)(uint64_t)(obj);
	tag = (uint64_t)data->vtable->table & 0x7;
	data->vtable->table = (Vtable *)((uint64_t)table | tag);
}

void *object_get_vtable(const ObjectImpl *obj) {
	ObjectData *data = NULL;
	if (!obj) return NULL;
	data = (ObjectData *)(uint64_t)(obj);
	Vtable *vtable = (Vtable *)((uint64_t)data->vtable & ~0x7);
	return vtable->table;
}

void *object_get_data(const ObjectImpl *obj) {
	ObjectData *data = NULL;
	if (!obj) return NULL;
	data = (ObjectData *)(uint64_t)(obj);
	return data->value.data;
}

void *resize_data(const ObjectImpl *obj, size_t nsize) {
	ObjectData *data = (ObjectData *)(uint64_t)(obj);
	void *tmp = resize(data->value.data, nsize);
	if (tmp) {
		data->value.data = tmp;
	}
	return tmp;
}
