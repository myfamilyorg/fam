#!/bin/bash

link() {
    local OUTPUT=$1
    local FLAGS=""
    for file in ${DIRECTORY}/target/lib/*.a; do
        if [ -e "$file" ]; then
            local filename=$(basename "$file")
            if [[ "$filename" =~ ^lib(.*)\.a$ ]]; then
                local libname="${BASH_REMATCH[1]}"
                FLAGS="$FLAGS -l$libname"
            fi
        fi
    done

    if [ "${OUTPUT_TYPE}" = "bin" ]; then
        COMMAND="${CC} \
${STATIC} \
${CCFLAGS} \
${FAM_BASE}/resources/fam.c \
-o ${DIRECTORY}/target/out/${OUTPUT} \
${FLAGS} \
${LINK_FLAGS} \
-L${DIRECTORY}/target/lib \
-DCRATE_NAME=${OUTPUT}";
        if [ ${VERBOSE} -eq 1 ]; then
            echo ${COMMAND};
        fi

	${COMMAND} || exit 1;
    else
	if [ "$(uname -s)" = "Linux" ]; then
            FINAL_OUTPUT="${DIRECTORY}/target/out/lib${OUTPUT}.so"
            SHARED="-shared"
        elif [ "$(uname -s)" = "Darwin" ]; then
            FINAL_OUTPUT="${DIRECTORY}/target/out/lib${OUTPUT}.dylib"
            SHARED="-dynamiclib -Wl,-install_name,@rpath/lib${OUTPUT}.dylib"
        else
            echo "Supported platforms [Linux, Darwin]. $(uname -s) is currently not supported.";
            exit 1;
	fi

        COMMAND="${CC} \
${CCFLAGS} \
${SHARED} \
-o ${FINAL_OUTPUT} \
-L${DIRECTORY}/target/lib \
${FLAGS} \
${LINK_FLAGS}"
	if [ ${VERBOSE} -eq 1 ]; then
            echo ${COMMAND};
        fi
	${COMMAND} || exit 1;
    fi

}
