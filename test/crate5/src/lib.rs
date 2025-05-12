#![no_std]

pub fn ok1(x: i32) -> i32 {
    let v = [0u8; 32];
    let _y = &v[5..9];
    x + 10
}
