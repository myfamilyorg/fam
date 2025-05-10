#!/bin/bash

fam_dep() {
    TOML_FILE="${DEP_LOCAL_BASE}/fam.toml";
    parse_toml
    local LOCAL_CRATE_NAME=${CRATE_NAME};
    local LOCAL_DEP_LOCAL_BASE=${DEP_LOCAL_BASE};
    local LOCAL_CRATE_DEP_COUNT=${CRATE_DEP_COUNT};
    local LOCAL_DEP_NAMES=${DEP_NAMES};
    local LOCAL_DEP_LOCATIONS=${DEP_LOCATIONS};
    local LOCAL_EXTERN="";
 

    # Handle dependencies
    local i=1;
    while [ $i -le ${LOCAL_CRATE_DEP_COUNT} ]; do
	    local INDEX=`expr $i - 1`;
	    local CRATE=${LOCAL_DEP_NAMES[$INDEX]};
	    local LOC=${LOCAL_DEP_LOCATIONS[$INDEX]};

	    mkdir -p "${DEPS_BASE_DIR}/$CRATE/c" || exit 1;
	    mkdir -p "${DEPS_BASE_DIR}/$CRATE/rust" || exit 1;

            if [ -d "${LOC}/c" ]; then
                if ls ${LOC}/c/* >/dev/null 2>&1; then
                    cp -rp ${LOC}/c/* ${DEPS_BASE_DIR}/${CRATE}/c || exit 1
                fi
            fi

	    cp -rp $LOC/rust/* ${DEPS_BASE_DIR}/$CRATE/rust || exit 1;
	    cp -rp $LOC/fam.* ${DEPS_BASE_DIR}/$CRATE/ || exit 1;

	    LOCAL_EXTERN="--extern ${CRATE}=${DEP_OUTPUT_RLIBS}/lib${CRATE}.rlib  ${LOCAL_EXTERN}";
	    DEP_LOCAL_BASE=${DEPS_BASE_DIR}/$CRATE
	    fam_dep
		
	    i=`expr $i + 1`;
    done

    # Compile c
    CC=clang
    VERBOSE=1
    C_DIRECTORY="${LOCAL_DEP_LOCAL_BASE}/c";
    C_ARCHIVE="${LOCAL_CRATE_NAME}";
    C_OUTPUT="${DEP_OUTPUT_RLIBS}";
    compile_c "$@"

    # Compile rust
    RUSTC="rustc";
    RUSTC_OUT="${DEP_OUTPUT_RLIBS}/lib${LOCAL_CRATE_NAME}.rlib";
    RUSTC_SRC="${LOCAL_DEP_LOCAL_BASE}/rust";
    RUSTC_CRATE_TYPE="lib";
    RUSTC_CRATE_NAME="${LOCAL_CRATE_NAME}";
    RUSTC_EXTERN="${LOCAL_EXTERN}";
    RUSTC_LIBS="-L${DEP_OUTPUT_RLIBS}";
    VERBOSE=1
    compile_rust "$@"
}
