#!/bin/bash

compile_rust() {
    NEED_UPDATE=0;
    if [ -e ${RUSTC_SRC} ]; then
        for file in `find ${RUSTC_SRC} | grep "\.rs$"`
        do
                if [ ! -e ${RUSTC_OUT} ] || [ ${file} -nt ${RUSTC_OUT} ]; then
                        NEED_UPDATE=1;
                        break;
                fi
        done
fi

    if [ "${NEED_UPDATE}" = "1" ]; then
        COMMAND="${RUSTC} \
-C panic=abort \
--crate-name=${RUSTC_CRATE_NAME} \
--crate-type=${RUSTC_CRATE_TYPE} \
-o ${RUSTC_OUT} \
${RUSTC_EXTERN} \
${RUSTC_SRC}/lib.rs \
${RUSTC_LIBS}";
        if [ "${VERBOSE}" = "1" ]; then
            echo ${COMMAND}
        fi
        ${COMMAND} || exit 1;
    fi
}

compile_c() {
    for file in ${C_DIRECTORY}/*.c
    do
        if [ -f "${file}" ]; then
            BASENAME=$(basename "$file" .c);
            OBJ=${C_OUTPUT}/${BASENAME}.o;
            if [ ! -e ${OBJ} ] || [ ${file} -nt ${OBJ} ]; then
                COMMAND="${CC} ${CCFLAGS} -o ${OBJ} -c ${file}";
                if [ "${VERBOSE}" = "1" ]; then
                    echo ${COMMAND}
                fi
		${COMMAND}
            fi
	fi
    done
}
