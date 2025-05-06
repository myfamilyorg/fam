#!/bin/bash

TOML=${DIRECTORY}/fam.toml

CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${TOML}`


mkdir -p ${DIRECTORY}/target/objs
mkdir -p ${DIRECTORY}/target/out
mkdir -p ${DIRECTORY}/target/deps

DEST_PATH=${DIRECTORY}/target/deps
DEP_COUNT=`${FAM_BASE}/scripts/dep_count.sh ${TOML}`
i=1;
while [ "$i" -le ${DEP_COUNT} ]
do
	DEP_NAME=`${FAM_BASE}/scripts/dep_crate.sh ${TOML} ${i}`
	DEP_PATH=`${FAM_BASE}/scripts/dep_path.sh ${TOML} ${i}`;
	${FAM_BASE}/scripts/dep.sh ${DEP_PATH} ${DEST_PATH}
	i=`expr $i + 1`
done

for file in ${DIRECTORY}/c/*.c
do
        if [ -f "$file" ]; then
                BASENAME=$(basename "$file" .c);
                OBJ=${DIRECTORY}/target/objs/${BASENAME}.o;
                if [ ! -e ${OBJ} ] || [ ${file} -nt ${OBJ} ]; then
                        COMMAND="${CC} ${CCFLAGS} -o ${OBJ} -c ${file}";
                        echo ${COMMAND};
                        ${COMMAND} || exit 1;
                fi
        fi
done

NEED_UPDATE=0;
if [ -e ${DIRECTORY}/rust ]; then
        for file in `find ${DIRECTORY}/rust | grep "\.rs$"`
        do
                OBJ=${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib
                if [ ! -e ${OBJ} ] || [ ${file} -nt ${OBJ} ]; then
                        NEED_UPDATE=1;
                        break;
                fi
        done
fi

if [ ${NEED_UPDATE} -eq 1 ]; then
	#DEP_CRATE_NAME=`cat ${DIRECTORY}/target/deps/*/crate_name`
	#COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib --extern ${DEP_CRATE_NAME}=${DIRECTORY}/target/deps/a84859f52e51f868a15694dd4f5cf5a7a887357a/objs/libcrate4.rlib ${DIRECTORY}/rust/lib.rs"
	#COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib ${DIRECTORY}/rust/lib.rs"


	# Initialize the extern flags for dependencies
	EXTERN_FLAGS=""

	# Find all dependency directories in ${DIRECTORY}/target/deps/
	DEP_DIRS=$(find "${DIRECTORY}/target/deps" -maxdepth 1 -type d -not -path "${DIRECTORY}/target/deps")

	# Check if there are any dependency directories
	if [ -n "${DEP_DIRS}" ]; then
		for DEP_DIR in ${DEP_DIRS}; do
			# Extract the crate name from the crate_name file
			CRATE_NAME_FILE="${DEP_DIR}/crate_name"
			if [ -f "${CRATE_NAME_FILE}" ]; then
				DEP_CRATE_NAME=$(cat "${CRATE_NAME_FILE}")
				# Find the rlib file in the dependency's objs directory
				DEP_RLIB=$(find "${DEP_DIR}/objs" -type f -name "lib${DEP_CRATE_NAME}.rlib" | head -n 1)
				if [ -n "${DEP_RLIB}" ]; then
					# Add --extern flag for this dependency
					EXTERN_FLAGS="${EXTERN_FLAGS} --extern ${DEP_CRATE_NAME}=${DEP_RLIB}"
				else
					echo "Warning: No lib${DEP_CRATE_NAME}.rlib found in ${DEP_DIR}/objs"
				fi
			else
				echo "Warning: No crate_name file found in ${DEP_DIR}"
			fi
		done
	fi

	COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib ${EXTERN_FLAGS} ${DIRECTORY}/rust/lib.rs"


	echo ${COMMAND}
	${COMMAND} || exit 1;
fi

. ${FAM_BASE}/scripts/linker.sh ${DIRECTORY}

NEED_UPDATE=0
for file in `find ${DIRECTORY}/target/objs/*.o`
do
	if [ ! -e ${DIRECTORY}/target/out/${CRATE_NAME} ] || [ $file -nt ${DIRECTORY}/target/out/${CRATE_NAME} ]; then
		NEED_UPDATE=1
		break
	fi
done

if [ ${NEED_UPDATE} -eq 1 ]; then
	COMMAND="${CC} -o ${DIRECTORY}/target/out/${CRATE_NAME} ${DIRECTORY}/target/linker_main.o ${LINKEXTRA} ${DIRECTORY}/target/deps/*/objs/*.o ${DIRECTORY}/target/objs/*.o ${LINK}"
	echo ${COMMAND}
	${COMMAND} || exit 1;
fi
