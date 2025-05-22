#include <alloc.h>
#include <criterion/criterion.h>
#include <format.h>
#include <object.h>

Test(core, test) {
	char *x = alloc(100);
	strcpy(x, "test");
	cr_assert_eq(1, 1);
	release(x);
}

Test(core, test_fmt1) {
	char buf[1024];

	Formatter f = FORMATTER_INIT;
	Printable p1 = {.pt = UINT32, .value.uint128 = 123};
	Printable p2 = {.pt = INT64, .value.int128 = -10};
	Printable p3 = {.pt = CSTR, .value.cstring = "abcdef"};
	format_impl(&f, "abc {} def {} ghi \n{} xyz\n", p1, p2, p3);
	ssize_t len = formatter_to_string(&f, buf, sizeof(buf));
	write(2, buf, len);

	Formatter f2 = FORMATTER_INIT;
	format_impl(&f2, "abc {} def {} ghi \n{} xyz\n",
		    TO_PRINTABLE(ign, (uint32_t)123),
		    TO_PRINTABLE(ign, (int64_t)-10),
		    TO_PRINTABLE(ign, "abcdef"));
	len = formatter_to_string(&f2, buf, sizeof(buf));
	write(2, buf, len);
	Formatter f3 = FORMATTER_INIT;
	$format(&f3, "a123bc {} dasdfef {} gaahi \n{} xfyz\n", ((uint32_t)923),
		((int64_t)-11), "xbcdef");
	len = formatter_to_string(&f3, buf, sizeof(buf));
	write(2, buf, len);
	$println("testing123 {} ok", ((uint32_t)921));
	$print("test: ");
	$println("ok");
	Printable p = {.value.d = 12.1234567, .pt = DOUBLE};
	$println("float val = {}. str = {}, int = {}", &p, "test", 123);
}

// Display trait (use macro or external script to generate - inputs are function
// signatures and trait name)
typedef struct {
	void (*doprint)(const ObjectImpl *);
} Display;

void doprint(const ObjectImpl *obj) {
	((Display *)(obj->vtable))->doprint(obj);
}

// Speak trait (use macro or external script to generate)
typedef struct {
	void (*speak)(const ObjectImpl *);
} Speak;

void speak(const ObjectImpl *obj) { ((Speak *)(obj->vtable))->speak(obj); }

// Type def (user defined)
typedef struct {
	int x;
	int y;
} MyType;

// user must declare a drop handler. Can do nothing $drop(MyType) {}.
$drop(MyType) { $println("drop"); }

// Trait impl display (user defined) - will create macros to improve member
// access
void MyType_print(const ObjectImpl *my_type) {
	$println("x={},y={}", ((MyType *)(my_type->data))->x,
		 ((MyType *)(my_type->data))->y);
}

// macro to create based on trait, type and function names ->
// $trait_impl(MyType, Display)
static Display MyTypeDisplay = {.doprint = MyType_print};

// Trait impl speak (user defined)
void MyType_speak(const ObjectImpl *my_type) { $println("woof!"); }

// macro to create based on trait and type
static Speak MyTypeSpeak = {.speak = MyType_speak};

Test(core, test_obj1) {
	let test = $object(MyType, (MyType){.x = 4, .y = 9});
	object_set_vtable(&test, &MyTypeDisplay);
	doprint(&test);
	object_set_vtable(&test, &MyTypeSpeak);
	speak(&test);
}
