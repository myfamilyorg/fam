// rustc working:
#![allow(internal_features)]
#![no_std]
#![no_main]
#![feature(lang_items)]
#![feature(alloc_error_handler)]
use core::alloc::Layout;
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[alloc_error_handler]
fn alloc_error(_layout: Layout) -> ! {
    loop {}
}

#[lang = "start"]
fn start<T>(_main: fn() -> T, argc: isize, argv: *const *const u8, _sigpipe: u8) -> isize {
    real_main(argc as i32, argv as *const *const i8) as isize
}

#[no_mangle]
pub extern "C" fn real_main(argc: i32, _argv: *const *const i8) -> i32 {
    argc
}

#[cfg(not(famc))]
#[no_mangle]
fn main() {}
