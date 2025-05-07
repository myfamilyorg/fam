#!/bin/bash

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null)
if [ -z "$SCRIPT_PATH" ]; then
	SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
fi
FAM_BASE=$(dirname "$(dirname "$SCRIPT_PATH")")

TOML=`${FAM_BASE}/bin/famtoml $1` || exit 1;
CRATE_INDEX=`expr 2 + $2 \* 3`
CRATE_NAME=`echo ${TOML} | cut -d ' ' -f ${CRATE_INDEX}`
echo ${CRATE_NAME}


