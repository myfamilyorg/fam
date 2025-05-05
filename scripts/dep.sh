#!/bin/sh

# Input:
# $1 - location of source project.
# $2 - base directory where the deps are built.
DEST_PATH=$1
DEST_BASE=$2

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null)
if [ -z "$SCRIPT_PATH" ]; then
    SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
fi
FAM_BASE=$(dirname "$(dirname "$SCRIPT_PATH")")

SHASUM=`${FAM_BASE}/scripts/shasum.sh ${DEST_PATH}/fam.toml`;

if [ ! -e ${DEST_PATH}/${SHASUM}/complete ]; then
	# Only execute if we haven't already completed
	COUNT=`${FAM_BASE}/scripts/dep_count.sh ${DEST_PATH}/fam.toml`;
	echo $COUNT
fi
