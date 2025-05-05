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
echo "extern crate ${CRATE_NAME};" > /tmp/linker_lib.rs

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
	COMMAND="rustc -C panic=abort --crate-name=${CRATE_NAME}_linker --crate-type=staticlib -o ${DIRECTORY}/target/objs/${CRATE_NAME}.o /tmp/linker_lib.rs --extern ${CRATE_NAME}=${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib"
	echo ${COMMAND}
	${COMMAND}
fi

