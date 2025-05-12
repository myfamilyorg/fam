#!/bin/bash

fam_dep() {
    local C_SRC=$1/src;
    local TOML_FILE="$1/fam.toml";
    local DEP_BASE=$2;
    local OUTPUT_LIBS=$3;
    local DEPTH=$4;

    parse_toml ${TOML_FILE};
    local DEP_CRATE_NAME=${CRATE_NAME};
    local DEP_DEP_COUNT=${CRATE_DEP_COUNT};
    local DEP_DEP_SUMMARY=${DEP_SUMMARY};

    local i=1;
    while [ $i -le ${DEP_DEP_COUNT} ]; do
	    local INDEX=$(expr $i - 1);
	    local CRATE_INDEX=`expr 1 + $INDEX \* 3`;
            local TYPE_INDEX=`expr 2 + $INDEX \* 3`;
            local LOC_INDEX=`expr 3 + $INDEX \* 3`;
            local CRATE=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $CRATE_INDEX);
            local TYPE=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $TYPE_INDEX);
            local LOC=$(echo "${DEP_DEP_SUMMARY}" | cut -d ' ' -f $LOC_INDEX);

            if [ "$TYPE" = "path" ]; then

		if [[ "${LOC}" == /* ]]; then
                    LOC_CPY="${LOC}";
                else
                    LOC_CPY="${DIRECTORY}/${LOC}";
                fi

		if [ ! -e ${DEP_BASE}/$CRATE/src ]; then
                    mkdir -p "${DEP_BASE}/$CRATE/src" || exit 1;

                    cp -rp $LOC_CPY/src/* ${DEP_BASE}/$CRATE/src || exit 1;
                    cp -rp $LOC_CPY/fam.* ${DEP_BASE}/$CRATE/ || exit 1;
		fi

	    else
		    echo "git"
	    fi

	    DEPTH=$(expr $DEPTH + 1);
	    fam_dep ${DEP_BASE}/${CRATE} ${DEP_BASE} ${OUTPUT_LIBS} ${DEPTH}
	    DEPTH=$(expr $DEPTH - 1);

	    i=$(expr $i + 1);
    done

    compile ${C_SRC} ${DEP_CRATE_NAME} ${OUTPUT_LIBS}
}
