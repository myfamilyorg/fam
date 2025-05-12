#!/bin/bash

compile() {
    local SRC=$1;
    local CRATE=$2;
    local OUTPUT=$3;

    local ARCHIVE_FILE="${OUTPUT}/lib${CRATE}.a";
    local NEED_UPDATE=0;

    for file in ${SRC}/*.c
    do
        if [ ! -e ${ARCHIVE_FILE} ] || [ ${file} -nt ${ARCHIVE_FILE} ]; then
            NEED_UPDATE=1;
            break;
        fi
    done

    if [ "${NEED_UPDATE}" = "1" ]; then
        printf "${GREEN}Compiling${RESET} ${CRATE}\n"
	local TMP_DIR=${OUTPUT}/${CRATE}.tmp
	mkdir -p ${TMP_DIR}

	for file in ${SRC}/*.c
	do
            if [ -f "${file}" ]; then
                local BASENAME=$(basename "$file" .c);
		local COMMAND="${CC} -I${SRC} ${FLAGS} ${CCFLAGS} -o ${TMP_DIR}/${BASENAME}.o -c ${file}";
		if [ "${VERBOSE}" = "1" ]; then
                    echo "${COMMAND}"
                fi
                ${COMMAND} || exit 1;
	    fi
        done

	local COMMAND="ar rcs ${ARCHIVE_FILE}  ${TMP_DIR}/*.o";
        if [ "${VERBOSE}" = "1" ]; then
                echo ${COMMAND};
        fi
        ${COMMAND} || { rm -rf ${TMP_DIR}; exit 1; }
        rm -rf ${TMP_DIR}
    fi
}
