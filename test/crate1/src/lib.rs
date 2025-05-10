#![no_std]

extern crate crate2;
use crate2::do_stuff;

#[allow(dead_code)]
extern "C" {
    fn fff() -> i32;
}

//#[no_mangle]
pub fn real_main(_argc: i32, _argv: *const *const i8) -> i32 {
    do_stuff()
    //unsafe { fff() }
}
