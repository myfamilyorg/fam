#include <alloc.h>
#include <format.h>
#include <object.h>

void object_cleanup(const ObjectImpl *obj) {
	if (obj && obj->data) {
		ObjectImpl *mutable_obj = (ObjectImpl *)obj;
		mutable_obj->descriptor.drop(obj);
		release(mutable_obj->data);
		mutable_obj->data = NULL;
	}
}

void object_set_vtable(const ObjectImpl *obj, void *vtable) {
	if (obj) {
		ObjectImpl *mutable_obj = (ObjectImpl *)obj;
		mutable_obj->vtable = vtable;
	}
}
