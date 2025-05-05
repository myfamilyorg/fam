#!/bin/sh

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null)
if [ -z "$SCRIPT_PATH" ]; then
    SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
fi
FAM_BASE=$(dirname "$(dirname "$SCRIPT_PATH")")

DIRECTORY=$1
TOML=${DIRECTORY}/fam.toml


CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${TOML}`

# create a linker lib
cat << EOM > /tmp/linker_lib.rs
extern crate ${CRATE_NAME};
pub use ${CRATE_NAME}::real_main;
#[no_mangle]
fn panic_impl() {}
#[no_mangle]
pub extern "C" fn real_main_impl(argc: i32, argv: *const *const i8) -> i32 { real_main(argc, argv) }
EOM

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
	COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME}_linker --crate-type=${LIB_TYPE} -o ${DIRECTORY}/target/objs/${CRATE_NAME}${EXT_STR} /tmp/linker_lib.rs --extern ${CRATE_NAME}=${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib"
	echo ${COMMAND}
	${COMMAND} || exit 1;
	COMMAND="${CC} -c /tmp/linker_main.c -o ${DIRECTORY}/target/objs/linker_main.o"
	echo ${COMMAND}
        ${COMMAND} || exit 1;
fi

