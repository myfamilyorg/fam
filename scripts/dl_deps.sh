#!/bin/bash

. ${FAM_BASE}/scripts/color.sh

clean_locks() {
    for file in ${DL_BASE}/*.lock
    do
        if [ -e "${file}" ]; then
            rmdir ${file}
        fi
    done
}

git_dl() {
    CRATE=$1;
    GIT_URL=$2;
    DL_BASE=$3;
    GIT_TAG=$4;
    GIT_DIR=${DL_BASE}/${CRATE}
    LOCK_DIR="${GIT_DIR}.lock"

    if mkdir "${LOCK_DIR}" 2>/dev/null; then
	if [ ! -e ${GIT_DIR} ]; then
            printf "${CYAN}Downloading${RESET} ${CRATE}\n"
            COMMAND="git clone ${GIT_URL} --no-checkout --depth 1 --single-branch ${GIT_DIR} -q";
            ${COMMAND} || exit 1;
	    if [ "${TAG}" = "" ]; then
                GIT_COMMIT=`git -C ${GIT_DIR} rev-parse HEAD`;
                git -C ${GIT_DIR} fetch --depth 1 origin ${GIT_COMMIT} -q;
                COMMAND="git -C ${GIT_DIR} checkout ${GIT_COMMIT} -q";
                ${COMMAND} || exit 1;
                parse_toml ${GIT_DIR}/fam.toml;
                dl_deps $DL_BASE ${CRATE_DEP_COUNT} ${DEP_SUMMARY};
            else
		COMMAND="git -C ${GIT_DIR} fetch --depth 1 origin refs/tags/${TAG} -q";
                if [ "${VERBOSE}" = "1" ]; then
                    echo $COMMAND;
                fi
                ${COMMAND} || exit 1;

                COMMAND="git -C ${GIT_DIR} checkout FETCH_HEAD -q";
                if [ "${VERBOSE}" = "1" ]; then
                    echo $COMMAND;
                fi
                ${COMMAND} || exit 1;
	    fi
	fi
    fi
}

dl_deps() {
    DL_BASE=$1;
    local i=1;
    while [ $i -le $2 ]; do
	local NAME=$(echo "$@" | cut -d ' ' -f $(expr 0 + $i \* 3));
	local TYPE=$(echo "$@" | cut -d ' ' -f $(expr 1 + $i \* 3));
        local LOCATION=$(echo "$@" | cut -d ' ' -f $(expr 2 + $i \* 3));
	local LOC;
	local TAG;
        if [[ "${LOCATION}" == *#* ]]; then
            LOC="${LOCATION%%#*}"
            TAG="${LOCATION#*#}"
        else
            LOC="${LOCATION}"
            TAG=""
        fi

	if [ "$TYPE" = "git" ]; then
		git_dl $NAME $LOC $DL_BASE $TAG&
	fi
        i=$(expr $i + 1);
    done
    wait
}
