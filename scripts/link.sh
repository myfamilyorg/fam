#!/bin/bash

fam_link() {
    rm -f ${DIRECTORY}/target/deps/lib.rs ${DIRECTORY}/target/deps/link.c
    cat << EOM >> ${DIRECTORY}/target/deps/lib.rs
#![no_std]

extern crate ${BUILD_CRATE_NAME};
#[no_mangle]
fn panic_impl() {}
use core::panic::PanicInfo;
extern "C" { fn write(fd: i32, buf: *const u8, len: usize) -> i32; fn exit(code: i32); }
#[panic_handler]
fn fam_panic(_info: &PanicInfo) -> ! {
        unsafe {
                let s = "Panic occurred! Halting!\n";
                write(2, s.as_ptr(), s.len());
                exit(-1);
                loop {}
        }
}
#[no_mangle]
fn rust_eh_personality() {}
EOM

    if [ "${BUILD_CRATE_TYPE}" = "bin" ]; then
        cat << EOM >> ${DIRECTORY}/target/deps/lib.rs
pub use ${BUILD_CRATE_NAME}::real_main;
#[no_mangle]
pub extern "C" fn real_main_impl(argc: i32, argv: *const *const i8) -> i32 { real_main(argc, argv) }
EOM
else
	cat << EOM >> ${DIRECTORY}/target/deps/lib.rs
#[no_mangle]
pub extern "C" fn real_main_impl(_argc: i32, _argv: *const *const i8) -> i32 { 0 }
EOM
    fi


    cat << EOM >> ${DIRECTORY}/target/deps/link.c
extern int real_main_impl(int, char **);
int main(int argc, char **argv) {
    return real_main_impl(argc, argv);
}
EOM

    CC=clang
    VERBOSE=1
    C_DIRECTORY=${DIRECTORY}/target/deps
    C_ARCHIVE=${BUILD_CRATE_NAME}_link
    C_OUTPUT=${DIRECTORY}/target/rlibs
    compile_c "$@"

    RUSTC_OUT=${DIRECTORY}/target/rlibs/${BUILD_CRATE_NAME}.o
    RUSTC_SRC=${DIRECTORY}/target/deps
    RUSTC_CRATE_TYPE=staticlib
    RUSTC_CRATE_NAME=${BUILD_CRATE_NAME}_link
    RUSTC_EXTERN="--extern ${BUILD_CRATE_NAME}=${DIRECTORY}/target/rlibs/lib${BUILD_CRATE_NAME}.rlib"
    RUSTC_LIBS=-L${DIRECTORY}/target/rlibs
    compile_rust "$@"
}
