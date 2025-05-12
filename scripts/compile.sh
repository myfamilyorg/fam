#!/bin/bash

. ${FAM_BASE}/scripts/color.sh

compile_rust() {
    local RUSTC_SRC=$1
    local RUSTC_OUT=$2
    local RUSTC_CRATE_NAME=$3
    local RUSTC_CRATE_TYPE=$4
    local RUSTC_LIBS=$5

    local NEED_UPDATE=0;
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
        DEPS_UPDATED=1;
        printf "${GREEN}Compiling${RESET}   Crate ${RUSTC_CRATE_NAME}\n"
        local COMMAND="${RUSTC} \
-C panic=abort \
${RUSTFLAGS} \
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
    local C_DIRECTORY=$1;
    local C_ARCHIVE=$2;
    local C_OUTPUT=$3;

    local ARCHIVE_FILE="${C_OUTPUT}/lib${C_ARCHIVE}.a";
    local NEED_UPDATE=0;
    local ARCHIVE_LINK_UPDATED=0;
    for file in ${C_DIRECTORY}/*.c
    do
        if [ -f "${file}" ]; then
            if [ $ARCHIVE_LINK_UPDATED -eq 0 ]; then
                C_ARCHIVE_LINKS="-l${C_ARCHIVE} ${C_ARCHIVE_LINKS}";
            fi
            ARCHIVE_LINK_UPDATED=1;
            if [ ! -e ${ARCHIVE_FILE} ] || [ ${file} -nt ${ARCHIVE_FILE} ]; then
                NEED_UPDATE=1;
                break;
            fi
        fi
    done

    if [ "${NEED_UPDATE}" = "1" ]; then
	DEPS_UPDATED=1;
        printf "${GREEN}Compiling${RESET}   C Archive ${C_ARCHIVE}\n"
        local TMP_DIR=${C_OUTPUT}/${C_ARCHIVE}.tmp
        mkdir -p ${TMP_DIR}
        for file in ${C_DIRECTORY}/*.c
        do
            if [ -f "${file}" ]; then
                local BASENAME=$(basename "$file" .c);
                local OBJ=${C_DIRECTORY}/${BASENAME}.o
                local COMMAND="${CC} ${CCFLAGS} -o ${TMP_DIR}/${BASENAME}.o -c ${file}";
                if [ "${VERBOSE}" = "1" ]; then
                    echo "${COMMAND}"
                fi
		${COMMAND}
	    fi
        done

        local COMMAND="ar rcs ${C_OUTPUT}/lib${C_ARCHIVE}.a ${TMP_DIR}/*.o";
	if [ "${VERBOSE}" = "1" ]; then
        	echo ${COMMAND};
	fi
        ${COMMAND} || exit 1;
        rm -rf ${TMP_DIR}
    fi
}
