#![no_std]

use core::slice::from_raw_parts;

fn get_str() -> &'static str {
    "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
}
pub fn real_main(_argc: i32, _argv: *const *const i8) -> i32 {
    let s = get_str();
    if s.len() != 100 {
        return -1;
    }
    let slice = unsafe { from_raw_parts(s.as_ptr(), 50) };

    slice[3] as i32
}
