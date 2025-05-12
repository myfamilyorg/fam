#!/bin/bash

# Pull in scripts
. ${FAM_BASE}/scripts/parse_toml.sh
. ${FAM_BASE}/scripts/dl_deps.sh
. ${FAM_BASE}/scripts/dep.sh
. ${FAM_BASE}/scripts/compile.sh
. ${FAM_BASE}/scripts/link.sh

parse_toml "${DIRECTORY}/fam.toml";
OUTPUT_NAME=${CRATE_NAME};
OUTPUT_TYPE=${CRATE_TYPE};

mkdir -p ${DIRECTORY}/target/deps;
mkdir -p ${DIRECTORY}/target/lib;
mkdir -p ${DIRECTORY}/target/out;

dl_deps ${DIRECTORY}/target/deps ${CRATE_DEP_COUNT} ${DEP_SUMMARY} 0;
clean_locks ${DL_BASE}
fam_dep ${DIRECTORY} ${DIRECTORY}/target/deps ${DIRECTORY}/target/lib 0
link ${OUTPUT_NAME}
