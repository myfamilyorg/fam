#![no_std]

extern "C" {
    fn my_fun() -> i32;
}

pub fn do_other_stuff() -> i32 {
    unsafe { my_fun() }
}
