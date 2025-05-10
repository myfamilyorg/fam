#!/bin/bash

. ${FAM_BASE}/scripts/color.sh

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
        printf "${GREEN}Compiling${RESET}   Crate ${RUSTC_CRATE_NAME}\n"
        COMMAND="${RUSTC} \
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
    ARCHIVE_FILE="${C_OUTPUT}/lib${C_ARCHIVE}.a";
    NEED_UPDATE=0;
    for file in ${C_DIRECTORY}/*.c
    do
	    if [ -f "${file}" ]; then
		    C_ARCHIVE_LINKS="-l${C_ARCHIVE} ${C_ARCHIVE_LINKS}";
		    if [ ! -e ${ARCHIVE_FILE} ] || [ ${file} -nt ${ARCHIVE_FILE} ]; then
			    NEED_UPDATE=1;
			    break;
		    fi
	    fi
    done

    if [ "${NEED_UPDATE}" = "1" ]; then
        printf "${GREEN}Compiling${RESET}   C Archive ${C_ARCHIVE}\n"
        TMP_DIR=${C_OUTPUT}/${C_ARCHIVE}.tmp
        mkdir -p ${TMP_DIR}
        for file in ${C_DIRECTORY}/*.c
        do
            if [ -f "${file}" ]; then
                BASENAME=$(basename "$file" .c);
                OBJ=${C_DIRECTORY}/${BASENAME}.o
                COMMAND="${CC} ${CCFLAGS} -o ${TMP_DIR}/${BASENAME}.o -c ${file}";
                if [ "${VERBOSE}" = "1" ]; then
                    echo "${COMMAND}"
                fi
		${COMMAND}
	    fi
        done

        COMMAND="ar rcs ${C_OUTPUT}/lib${C_ARCHIVE}.a ${TMP_DIR}/*.o";
	if [ "${VERBOSE}" = "1" ]; then
        	echo ${COMMAND};
	fi
        ${COMMAND} || exit 1;
        rm -rf ${TMP_DIR}
    fi
}
