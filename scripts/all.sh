#!/bin/bash

# Pull in scripts
. ${FAM_BASE}/scripts/parse_toml.sh
. ${FAM_BASE}/scripts/dl_deps.sh
. ${FAM_BASE}/scripts/dep.sh
. ${FAM_BASE}/scripts/compile.sh
. ${FAM_BASE}/scripts/link.sh

parse_toml "${DIRECTORY}/fam.toml";
OUTPUT_NAME=${CRATE_NAME};

mkdir -p ${DIRECTORY}/target/deps;
mkdir -p ${DIRECTORY}/target/lib;
mkdir -p ${DIRECTORY}/target/out;

DL_BASE="${DIRECTORY}/target/deps"
dl_deps ${DL_BASE} ${CRATE_DEP_COUNT} ${DEP_SUMMARY} 0;
for file in ${DL_BASE}/*.lock
do
    if [ -e "${file}" ]; then
        rmdir ${file}
    fi
done

DEPS_UPDATED=0;
fam_dep ${DIRECTORY} ${DIRECTORY}/target/deps ${DIRECTORY}/target/lib 0

link ${OUTPUT_NAME}
