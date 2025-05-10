#!/bin/bash

# Pull in scripts
. ${FAM_BASE}/scripts/parse_toml.sh
. ${FAM_BASE}/scripts/compile.sh
. ${FAM_BASE}/scripts/link.sh
. ${FAM_BASE}/scripts/dep.sh

# Parse fam.toml
TOML_FILE="${DIRECTORY}/fam.toml"
parse_toml
BUILD_CRATE_NAME=${CRATE_NAME};
BUILD_CRATE_TYPE=${CRATE_TYPE};

# Setup target directory
mkdir -p ${DIRECTORY}/target/out
mkdir -p ${DIRECTORY}/target/lib
mkdir -p ${DIRECTORY}/target/deps

# Compile deps
DEP_LOCAL_BASE=${DIRECTORY}
DEP_OUTPUT_LIBS=${DIRECTORY}/target/lib
DEPS_BASE_DIR=${DIRECTORY}/target/deps
C_ARCHIVE_LINKS="";
DEPTH=0;
fam_dep

# Link lib/archives
fam_link "$@"

if [ "${BUILD_CRATE_TYPE}" = "lib" ]; then
    if [ "$(uname -s)" = "Linux" ]; then
        FINAL_OUTPUT="${DIRECTORY}/target/out/lib${BUILD_CRATE_NAME}.so"
        SHARED=-shared
    elif [ "$(uname -s)" = "Darwin" ]; then
        FINAL_OUTPUT="${DIRECTORY}/target/out/lib${BUILD_CRATE_NAME}.dylib"
        SHARED="-dynamiclib -Wl,-install_name,@rpath/lib${BUILD_CRATE_NAME}.dylib"
    fi
else
    FINAL_OUTPUT="${DIRECTORY}/target/out/${BUILD_CRATE_NAME}"
    SHARED=
fi

# Final build
COMMAND="${CC} ${SHARED} -o ${FINAL_OUTPUT} \
${C_ARCHIVE_LINKS} \
${DIRECTORY}/target/lib/*.o \
-L${DIRECTORY}/target/lib"

if [ "${VERBOSE}" = "1" ]; then
    echo ${COMMAND}
fi
${COMMAND} || exit 1;
