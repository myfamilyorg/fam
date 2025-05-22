#include <alloc.h>
#include <criterion/criterion.h>
#include <format.h>

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
	format(&f3, "a123bc {} dasdfef {} gaahi \n{} xfyz\n", ((uint32_t)923),
	       ((int64_t)-11), "xbcdef");
	len = formatter_to_string(&f3, buf, sizeof(buf));
	write(2, buf, len);
	println("testing123 {} ok", ((uint32_t)921));
	print("test: ");
	println("ok");
	Printable p = {.value.d = 12.3, .pt = DOUBLE};
	println("float val = {}.", &p);
}
