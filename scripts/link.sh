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

    COMMAND="${CC} \
${STATIC} \
${FLAGS} \
${LINK_FLAGS} \
${CCFLAGS} \
${FAM_BASE}/resources/fam.c \
-o ${DIRECTORY}/target/out/${OUTPUT} \
-L${DIRECTORY}/target/lib \
-DCRATE_NAME=${OUTPUT}";
    if [ ${VERBOSE} -eq 1 ]; then
        echo ${COMMAND};
    fi
    ${COMMAND}
}
