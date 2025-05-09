#!/bin/bash

fam_dep() {
    TOML_FILE="${DEP_LOCAL_BASE}/fam.toml";
    parse_toml
    local LOCAL_CRATE_NAME=${CRATE_NAME};
    local LOCAL_DEP_LOCAL_BASE=${DEP_LOCAL_BASE};
    local LOCAL_CRATE_DEP_COUNT[$DEPTH]=${CRATE_DEP_COUNT};
    local LOCAL_DEP_SUMMARY[$DEPTH]=${DEP_SUMMARY};
    local LOCAL_EXTERN="";

    # Handle dependencies
    local i=1;
    while [ $i -le ${LOCAL_CRATE_DEP_COUNT[$DEPTH]} ]; do
	    local itt=$i
	    local INDEX=`expr $itt - 1`;
	    local SUMMARY=${LOCAL_DEP_SUMMARY[$DEPTH]};
	    local CRATE_INDEX=`expr 1 + $INDEX \* 3`;
	    local TYPE_INDEX=`expr 2 + $INDEX \* 3`;
	    local LOC_INDEX=`expr 3 + $INDEX \* 3`;
	    local CRATE=$(echo "${SUMMARY}" | cut -d ' ' -f $CRATE_INDEX)
	    local TYPE=$(echo "${SUMMARY}" | cut -d ' ' -f $TYPE_INDEX)
	    local LOC=$(echo "${SUMMARY}" | cut -d ' ' -f $LOC_INDEX)

	    if [ "$TYPE" = "path" ]; then
	        mkdir -p "${DEPS_BASE_DIR}/$CRATE/c" || exit 1;
	        mkdir -p "${DEPS_BASE_DIR}/$CRATE/src" || exit 1;

                if [ -d "${LOC}/c" ]; then
                    if ls ${LOC}/c/* >/dev/null 2>&1; then
                        cp -rp ${LOC}/c/* ${DEPS_BASE_DIR}/${CRATE}/c || exit 1
                    fi
                fi

	        cp -rp $LOC/src/* ${DEPS_BASE_DIR}/$CRATE/src || exit 1;
	        cp -rp $LOC/fam.* ${DEPS_BASE_DIR}/$CRATE/ || exit 1;
            else
                GIT_DIR="${DEPS_BASE_DIR}/$CRATE";
		if [ ! -e $GIT_DIR ]; then
                    COMMAND="git clone $LOC $GIT_DIR";
                    echo $COMMAND;
		    ${COMMAND}
	        else
			break;
		fi
	    fi

	    LOCAL_EXTERN="--extern ${CRATE}=${DEP_OUTPUT_LIBS}/lib${CRATE}.rlib  ${LOCAL_EXTERN}";
	    DEP_LOCAL_BASE=${DEPS_BASE_DIR}/$CRATE
	    DEPTH=$((DEPTH + 1));
	    fam_dep
	    DEPTH=$((DEPTH - 1))
		
	    i=`expr $itt + 1`;
    done

    # Compile c
    CC=clang
    C_DIRECTORY="${LOCAL_DEP_LOCAL_BASE}/c";
    C_ARCHIVE="${LOCAL_CRATE_NAME}";
    C_OUTPUT="${DEP_OUTPUT_LIBS}";
    compile_c "$@"

    # Compile rust
    RUSTC_OUT="${DEP_OUTPUT_LIBS}/lib${LOCAL_CRATE_NAME}.rlib";
    RUSTC_SRC="${LOCAL_DEP_LOCAL_BASE}/src";
    RUSTC_CRATE_TYPE="lib";
    RUSTC_CRATE_NAME="${LOCAL_CRATE_NAME}";
    RUSTC_EXTERN="${LOCAL_EXTERN}";
    RUSTC_LIBS="-L${DEP_OUTPUT_LIBS}";
    compile_rust "$@"
}
