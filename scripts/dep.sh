#!/bin/bash

fam_dep() {
    local C_SRC=$1/c;
    local RUST_SRC=$1/src;
    local DEP_BASE=$2;
    local OUTPUT_LIBS=$3;
    local DEPTH=$4;

    local TOML_FILE="$1/fam.toml";
    parse_toml ${TOML_FILE};
    local DEP_CRATE_NAME=${CRATE_NAME};
    local DEP_DEP_COUNT=${CRATE_DEP_COUNT};
    local DEP_DEP_SUMMARY=${DEP_SUMMARY};

    local i=1;
    local LOCAL_EXTERN="";

    while [ $i -le ${DEP_DEP_COUNT} ]; do
	    local INDEX=$(expr $i - 1);
	    local CRATE_INDEX=`expr 1 + $INDEX \* 3`;
            local TYPE_INDEX=`expr 2 + $INDEX \* 3`;
            local LOC_INDEX=`expr 3 + $INDEX \* 3`;
            local CRATE=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $CRATE_INDEX);
            local TYPE=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $TYPE_INDEX);
            local LOC=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $LOC_INDEX);

            if [ "$TYPE" = "path" ]; then

		if [[ "${LOC}" == /* ]]; then
                    LOC_CPY="${LOC}";
                else
                    LOC_CPY="${DIRECTORY}/${LOC}";
                fi

		if [ ! -e ${DEP_BASE}/$CRATE/src ]; then
		    mkdir -p "${DEP_BASE}/$CRATE/c" || exit 1;
                    mkdir -p "${DEP_BASE}/$CRATE/src" || exit 1;

		    if [ -d "${LOC_CPY}/c" ]; then
                        if ls ${LOC_CPY}/c/* >/dev/null 2>&1; then
                            cp -rp ${LOC_CPY}/c/* ${DEP_BASE}/${CRATE}/c || exit 1
                        fi
                    fi

                    cp -rp $LOC_CPY/src/* ${DEP_BASE}/$CRATE/src || exit 1;
                    cp -rp $LOC_CPY/fam.* ${DEP_BASE}/$CRATE/ || exit 1;
		fi

	    else
		    echo "git"
	    fi

	    LOCAL_EXTERN="--extern ${CRATE}=${OUTPUT_LIBS}/lib${CRATE}.rlib  ${LOCAL_EXTERN}";
	    DEPTH=$(expr $DEPTH + 1);
	    fam_dep ${DEP_BASE}/${CRATE} ${DEP_BASE} ${OUTPUT_LIBS} ${DEPTH}
	    DEPTH=$(expr $DEPTH - 1);
	    #fam_dep ${DIRECTORY} ${DIRECTORY}/target/deps ${DIRECTORY}/target/lib 0

	    i=$(expr $i + 1);
    done

    for file in ${C_SRC}/*.c
    do
        if [ -e "${file}" ]; then
            # if one or more c file exists, compile them
            compile_c ${C_SRC} ${DEP_CRATE_NAME} ${OUTPUT_LIBS}
            break;
        fi
    done

    if [ ${DEPTH} -eq 0 ]; then
        if [ ${DEPS_UPDATED} -eq 1 ]; then
		touch ${DIRECTORY}/src/lib.rs
	fi

	if ${RUSTC} --version | grep -q "mrustc"; then
             if [ "$(uname -s)" = "Linux" ]; then
                 RUSTFLAGS="--cfg famc ${C_ARCHIVE_LINKS}"
	     elif [ "$(uname -s)" = "Darwin" ]; then
	         RUSTFLAGS="--cfg famc -lSystem ${C_ARCHIVE_LINKS}"
	     fi
	    RCRATE_TYPE=lib
        else
            if [ "$(uname -s)" = "Linux" ]; then
                 RUSTFLAGS="${C_ARCHIVE_LINKS}"
	    elif [ "$(uname -s)" = "Darwin" ]; then
	        RUSTFLAGS="-lSystem ${C_ARCHIVE_LINKS}"
	    fi
	    RCRATE_TYPE=bin
        fi
	RUSTC_EXTERN=${LOCAL_EXTERN}
        compile_rust ${RUST_SRC} ${DIRECTORY}/target/out/${DEP_CRATE_NAME} ${DEP_CRATE_NAME} ${RCRATE_TYPE} -L${OUTPUT_LIBS}
	if ${RUSTC} --version | grep -q "mrustc"; then
		COMMAND="${CC} -o ${DIRECTORY}/target/out/${DEP_CRATE_NAME} ${DIRECTORY}/target/out/*.o ${FAM_BASE}/resources/famc.c"
		echo "$COMMAND"
		${COMMAND}
	fi
    else
	RUSTC_EXTERN=${LOCAL_EXTERN}
        compile_rust ${RUST_SRC} ${OUTPUT_LIBS}/lib${DEP_CRATE_NAME}.rlib ${DEP_CRATE_NAME} lib -L${OUTPUT_LIBS}
    fi
}
