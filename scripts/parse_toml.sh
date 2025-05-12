#!/bin/bash

parse_toml() {
    VALUES=$(${FAM_BASE}/bin/famparse toml $1);
    if [ $? -ne 0 ]; then
	    echo "toml parse failed";
	    exit 1;
    fi

    CRATE_TYPE=$(echo "${VALUES}" | cut -d ' ' -f 1)
    if [ -z "${CRATE_TYPE}" ]; then
        echo "Error: Failed to extract CRATE_TYPE from VALUES: ${VALUES}" >&2
        exit 1;
    fi

    CRATE_NAME=$(echo "${VALUES}" | cut -d ' ' -f 2)
    if [ -z "${CRATE_TYPE}" ]; then
        echo "Error: Failed to extract CRATE_TYPE from VALUES: ${VALUES}" >&2
        exit 1;
    fi

    CRATE_DEP_COUNT=$(echo "${VALUES}" | cut -d ' ' -f 3)
    if [ -z "${CRATE_TYPE}" ]; then
        echo "Error: Failed to extract CRATE_TYPE from VALUES: ${VALUES}" >&2
        exit 1;
    fi

    local i=1;
    DEP_SUMMARY="";
    while [ $i -le ${CRATE_DEP_COUNT} ]; do
	NAME=$(echo "${VALUES}" | cut -d ' ' -f $(expr 1 + $i \* 3));
	TYPE=$(echo "${VALUES}" | cut -d ' ' -f $(expr 2 + $i \* 3));
	LOCATION=$(echo "${VALUES}" | cut -d ' ' -f $(expr 3 + $i \* 3));
        if [ -z "${NAME}" ]; then
            echo "Error: Failed to extract DEP_NAME from VALUES: '${VALUES}' INDEX: ${i}" >&2
            exit 1;
        fi
	if [ -z "${TYPE}" ]; then
            echo "Error: Failed to extract DEP_TYPE from VALUES: '${VALUES}' INDEX: ${i}" >&2
            exit 1;
        fi
	if [ -z "${NAME}" ]; then
            echo "Error: Failed to extract DEP_LOCATION from VALUES: '${VALUES}' INDEX: ${i}" >&2
            exit 1;
        fi

	if [ $i -eq 1 ]; then
            DEP_SUMMARY="${NAME} ${TYPE} ${LOCATION}";
        else
            DEP_SUMMARY="${DEP_SUMMARY} ${NAME} ${TYPE} ${LOCATION}";
	fi

	i=$(expr $i + 1);
    done
}
