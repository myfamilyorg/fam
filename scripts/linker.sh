#!/bin/bash

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null)
if [ -z "$SCRIPT_PATH" ]; then
    SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
fi
FAM_BASE=$(dirname "$(dirname "$SCRIPT_PATH")")

DIRECTORY=$1
TOML=${DIRECTORY}/fam.toml


CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${TOML}`
CRATE_TYPE=`${FAM_BASE}/scripts/crate_type.sh ${TOML}`

# create a linker lib

DEP_DIRS=$(find "${DIRECTORY}/target/deps" -maxdepth 1 -type d -not -path "${DIRECTORY}/target/deps")

rm -f /tmp/linker_lib.rs
echo "#![no_std]" >> /tmp/linker_lib.rs;
if [ -n "${DEP_DIRS}" ]; then
	for DEP_DIR in ${DEP_DIRS}; do
		CRATE_NAME_FILE="${DEP_DIR}/crate_name"
		if [ -f "${CRATE_NAME_FILE}" ]; then
			DEP_CRATE_NAME=$(cat "${CRATE_NAME_FILE}")
			echo "extern crate ${DEP_CRATE_NAME};" >> /tmp/linker_lib.rs;
		fi
	done
fi

cat << EOM >> /tmp/linker_lib.rs
extern crate ${CRATE_NAME};
#[no_mangle]
fn panic_impl() {}
use core::panic::PanicInfo;
#[panic_handler]
fn fam_panic(_info: &PanicInfo) -> ! {
        loop {}
}
EOM

if [ "${CRATE_TYPE}" = "bin" ]; then
	echo "pub use ${CRATE_NAME}::real_main;" >> /tmp/linker_lib.rs
	echo "#[no_mangle]" >> /tmp/linker_lib.rs
	echo "pub extern \"C\" fn real_main_impl(argc: i32, argv: *const *const i8) -> i32 { real_main(argc, argv) }" >> /tmp/linker_lib.rs
else
	echo "#[no_mangle]" >> /tmp/linker_lib.rs
	echo "pub extern \"C\" fn real_main_impl(_argc: i32, _argv: *const *const i8) -> i32 { 0 }" >> /tmp/linker_lib.rs
fi

echo "extern int real_main_impl(int, char **); int main(int argc, char **argv) { return real_main_impl(argc, argv); }" > /tmp/linker_main.c


mkdir -p ${DIRECTORY}/target/objs

STATIC_LIB="${DIRECTORY}/target/objs/${CRATE_NAME}.o"
CRATE_RLIB="${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib"

NEED_UPDATE=0;
for file in `find ${DIRECTORY}/target/objs/*`
do
	if [ ! -e ${STATIC_LIB} ] || [ ${file} -nt ${STATIC_LIB} ]; then
		NEED_UPDATE=1;
		break;
	fi
done

if [ ${NEED_UPDATE} -eq 1 ]; then

 # Initialize the extern flags for dependencies
        EXTERN_FLAGS=""

        # Check if there are any dependency directories
        if [ -n "${DEP_DIRS}" ]; then
                for DEP_DIR in ${DEP_DIRS}; do
                        # Extract the crate name from the crate_name file
                        CRATE_NAME_FILE="${DEP_DIR}/crate_name"
                        if [ -f "${CRATE_NAME_FILE}" ]; then
                                DEP_CRATE_NAME=$(cat "${CRATE_NAME_FILE}")
                                # Find the rlib file in the dependency's objs directory
                                DEP_RLIB=$(find "${DEP_DIR}/objs" -type f -name "lib${DEP_CRATE_NAME}.rlib" | head -n 1)
                                if [ -n "${DEP_RLIB}" ]; then
                                        # Add --extern flag for this dependency
                                        EXTERN_FLAGS="${EXTERN_FLAGS} --extern ${DEP_CRATE_NAME}=${DEP_RLIB}"
                                fi
                        fi
                done
        fi

	if [ "${CRATE_TYPE}" = "proc-macro" ]; then
                EXT=${MACRO_EXT}
        else
                EXT=rlib
        fi

        COMMAND="${RUSTC} -C panic=abort ${RUSTEXTRA} --crate-name=${CRATE_NAME}_linker --crate-type=${LIB_TYPE} -o ${DIRECTORY}/target/objs/${CRATE_NAME}${EXT_STR} --extern ${CRATE_NAME}=${DIRECTORY}/target/objs/lib${CRATE_NAME}.${EXT} ${EXTERN_FLAGS} /tmp/linker_lib.rs -L${DIRECTORY}/target/deps/rlibs"
	echo ${COMMAND}
	${COMMAND} || exit 1;
	COMMAND="${CC} -c /tmp/linker_main.c -o ${DIRECTORY}/target/linker_main.o"
	echo ${COMMAND}
        ${COMMAND} || exit 1;
fi

