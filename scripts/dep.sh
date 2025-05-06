#!/bin/bash

# Input:
# $1 - location of source project.
# $2 - base directory where the deps are built.
DEST_PATH=$1
DEST_BASE=$2

mkdir -p ${DEST_BASE}/rlibs

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null)
if [ -z "$SCRIPT_PATH" ]; then
    SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
fi
FAM_BASE=$(dirname "$(dirname "$SCRIPT_PATH")")

CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${DEST_PATH}/fam.toml`
SHASUM=`${FAM_BASE}/scripts/shasum.sh ${DEST_PATH}/fam.toml` || exit 1;

if [ ! -e ${DEST_BASE}/${SHASUM}/complete ]; then
	# Only execute if we haven't already completed
	
	# First handle deps
	TOML=${DEST_PATH}/fam.toml
	DEP_COUNT=`${FAM_BASE}/scripts/dep_count.sh ${TOML}`;
	i=1;

	DEP_RLIBS="";
	while [ $i -le ${DEP_COUNT} ]
	do
		DEP_PATH=${DEST_PATH}/`${FAM_BASE}/scripts/dep_path.sh ${TOML} ${i}`;
		DEP_NAME=`${FAM_BASE}/scripts/dep_crate.sh ${TOML} ${i}`;
		DEP_RLIBS="${DEP_RLIBS} --extern ${DEP_NAME}=${DEST_BASE}/rlibs/lib${DEP_NAME}.rlib";
		${FAM_BASE}/scripts/dep.sh ${DEP_PATH} ${DEST_BASE} || exit 1;
		i=`expr $i + 1`
	done

	# Now install project in our DEST_BASE
	mkdir -p ${DEST_BASE}/${SHASUM}/c || exit 1;
	mkdir -p ${DEST_BASE}/${SHASUM}/rust || exit 1;
	mkdir -p ${DEST_BASE}/${SHASUM}/objs || exit 1;

	echo "${CRATE_NAME}" > ${DEST_BASE}/${SHASUM}/crate_name

	if [ -e ${DEST_PATH}/c ]; then
		cp ${DEST_PATH}/c/* ${DEST_BASE}/${SHASUM}/c || exit 1;
	fi
	if [ -e ${DEST_PATH}/rust ]; then
		cp ${DEST_PATH}/rust/* ${DEST_BASE}/${SHASUM}/rust || exit 1;
	fi

	for file in ${DEST_BASE}/${SHASUM}/c/*.c
	do
		if [ -f "$file" ]; then
			BASENAME=$(basename "$file" .c);
			OBJ=${DEST_BASE}/${SHASUM}/objs/${BASENAME}.o;
			if [ ! -e ${OBJ} ] || [ ${file} -nt ${OBJ} ]; then
				COMMAND="${CC} ${CCFLAGS} -o ${OBJ} -c ${file}";
				echo ${COMMAND};
				${COMMAND} || exit 1;
			fi
		fi
	done

	if [ -e ${DEST_PATH}/rust/lib.rs ]; then
		#COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DEST_BASE}/${SHASUM}/objs/lib${CRATE_NAME}.rlib ${DEP_RLIBS} ${DEST_PATH}/rust/lib.rs"
		COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DEST_BASE}/rlibs/lib${CRATE_NAME}.rlib ${DEP_RLIBS} ${DEST_PATH}/rust/lib.rs -L${DEST_BASE}/rlibs"
        	echo ${COMMAND}
        	${COMMAND} || exit 1;
		#cp ${DEST_BASE}/${SHASUM}/objs/lib${CRATE_NAME}.rlib ${DEST_BASE}/rlibs
	fi

	touch ${DEST_BASE}/${SHASUM}/complete;
fi
