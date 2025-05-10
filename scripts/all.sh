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
DEP_OUTPUT_RLIBS=${DIRECTORY}/target/lib
DEP_OUTPUT_OBJS=${DIRECTORY}/target/lib
DEPS_BASE_DIR=${DIRECTORY}/target/deps
C_ARCHIVE_LINKS="";
fam_dep

# Link lib/archives
fam_link "$@"
COMMAND="${CC} -o ${DIRECTORY}/target/out/${BUILD_CRATE_NAME} \
${C_ARCHIVE_LINKS} \
${DIRECTORY}/target/lib/${BUILD_CRATE_NAME}.o \
-L${DIRECTORY}/target/lib"

if [ "${VERBOSE}" = "1" ]; then
	echo ${COMMAND}
fi
${COMMAND} || exit 1;
