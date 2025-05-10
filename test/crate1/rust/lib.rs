#![no_std]

extern crate crate2;

extern "C" {
    fn fff() -> i32;
}

pub fn real_main(_argc: i32, _argv: *const *const i8) -> i32 {
    //do_stuff()
    unsafe { fff() }
}
