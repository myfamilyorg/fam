#!/bin/bash

parse_toml() {
    COMMAND="${FAM_BASE}/bin/famparse toml ${TOML_FILE}";
    if [ "${VERBOSE}" = "1" ]; then
        echo ${COMMAND}
    fi
    VALUES=$(${COMMAND})
    if [ $? -ne 0 ]; then
        echo "Error: Command failed: ${COMMAND}" >&2
        exit 1
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

    i=1;
    DEP_SUMMARY="";
    while [ "$i" -le ${CRATE_DEP_COUNT} ]
    do
        index=`expr $i - 1`;
        DEP_INDEX=`expr 1 + $i \* 3`;
        DEP_NAMES[$index]=$(echo "${VALUES}" | cut -d ' ' -f ${DEP_INDEX})
        if [ -z "${DEP_NAMES[$index]}" ]; then
            echo "Error: Failed to extract DEP_NAME from VALUES: '${VALUES}' INDEX: ${DEP_INDEX}" >&2
            exit 1;
        fi
	DEP_INDEX=`expr 2 + $i \* 3`;
        DEP_TYPES[$index]=$(echo "${VALUES}" | cut -d ' ' -f ${DEP_INDEX})
        if [ -z "${DEP_TYPES[$index]}" ]; then
            echo "Error: Failed to extract DEP_TYPE from VALUES: '${VALUES}' INDEX: ${DEP_INDEX}" >&2
            exit 1;
        fi
	DEP_INDEX=`expr 3 + $i \* 3`;
        LOCATION=$(echo "${VALUES}" | cut -d ' ' -f ${DEP_INDEX})
        if [ -z "${LOCATION}" ]; then
            echo "Error: Failed to extract DEP_LOCATION from VALUES: '${VALUES}' INDEX: ${DEP_INDEX}" >&2
            exit 1;
        fi

	if [[ "${LOCATION}" == *#* ]]; then
            DEP_LOCATIONS[$index]="${LOCATION%%#*}"
            DEP_TAGS[$index]="${LOCATION#*#}"
        else
            DEP_LOCATIONS[$index]="${LOCATION}"
            DEP_TAGS[$index]=""
        fi
	if [ $i -eq 1 ]; then
            DEP_SUMMARY="${DEP_NAMES[$index]} ${DEP_TYPES[$index]} ${DEP_LOCATIONS[$index]}#${DEP_TAGS[$index]}"
        else
            DEP_SUMMARY="${DEP_SUMMARY} ${DEP_NAMES[$index]} ${DEP_TYPES[$index]} ${DEP_LOCATIONS[$index]}#${DEP_TAGS[$index]}"
	fi

        i=`expr $i + 1`;
    done
}
