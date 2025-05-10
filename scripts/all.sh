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
mkdir -p ${DIRECTORY}/target/rlibs
mkdir -p ${DIRECTORY}/target/objs
mkdir -p ${DIRECTORY}/target/src
mkdir -p ${DIRECTORY}/target/deps

# Compile deps
DEP_LOCAL_BASE=${DIRECTORY}
DEP_OUTPUT_RLIBS=${DIRECTORY}/target/rlibs
DEP_OUTPUT_OBJS=${DIRECTORY}/target/objs
DEPS_BASE_DIR=${DIRECTORY}/target/deps
fam_dep

# Link rlibs/archives
fam_link "$@"
COMMAND="${CC} -o ${DIRECTORY}/target/out/${BUILD_CRATE_NAME} \
-l${BUILD_CRATE_NAME}_link \
-l${BUILD_CRATE_NAME} ${DIRECTORY}/target/objs/${BUILD_CRATE_NAME}.o \
-L${DIRECTORY}/target/rlibs"

if [ "${VERBOSE}" = "1" ]; then
	echo ${COMMAND}
fi
${COMMAND} || exit 1;
