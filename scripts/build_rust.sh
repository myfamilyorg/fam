#!/bin/sh

DIRECTORY=$1
CRATE_NAME=$2
RUSTC=rustc
NEED_UPDATE=1


# rustc -C panic=abort --crate-name=crate1 --crate-type=lib -o ../crate1/target/libcrate1.rlib ../crate1/rust/lib.rs

if [ ${NEED_UPDATE} -eq 1 ]; then
	if [ -f ${DIRECTORY}/rust/lib.rs ]; then
		COMMAND="${RUSTC} \
-C panic=abort \
--crate-name=${CRATE_NAME} \
--crate-type=lib \
-o ${DIRECTORY}/target/objs/${CRATE_NAME}.rlib \
${DIRECTORY}/rust/lib.rs"
		echo ${COMMAND}
		${COMMAND} || exit 1;
	fi
fi
