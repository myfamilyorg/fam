#!/bin/bash
TOML=${DIRECTORY}/fam.toml

CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${TOML}` || { echo "Error parsing $1"; exit 1; }
CRATE_TYPE=`${FAM_BASE}/scripts/crate_type.sh ${TOML}` || { echo "Error parsing $1"; exit 1; }


mkdir -p ${DIRECTORY}/target/objs
mkdir -p ${DIRECTORY}/target/out
mkdir -p ${DIRECTORY}/target/deps
mkdir -p ${DIRECTORY}/target/deps/dl

DEST_PATH=${DIRECTORY}/target/deps
DEP_COUNT=`${FAM_BASE}/scripts/dep_count.sh ${TOML}` || exit 1;
CRATE_TYPE=`${FAM_BASE}/scripts/crate_type.sh ${TOML}` || exit 1;
i=1;

while [ "$i" -le ${DEP_COUNT} ]
do
	DEP_NAME=`${FAM_BASE}/scripts/dep_crate.sh ${TOML} ${i}` || exit 1;
	DEP_METHOD=`${FAM_BASE}/scripts/dep_method.sh ${TOML} ${i}` || exit 1;

	if [ "${DEP_METHOD}" = "git" ]; then
		GIT_PATH=`${FAM_BASE}/scripts/dep_path.sh ${TOML} ${i}` || exit 1;
		#GIT_COMMIT=$(echo "$GIT_PATH" | cut -d'#' -f2)
		GIT_PATH=$(echo "$GIT_PATH" | cut -d'#' -f1)
		GIT_DIR="${DIRECTORY}/target/deps/dl/${DEP_NAME}";
		if [ ! -e ${GIT_DIR} ]; then
			git clone $GIT_PATH ${GIT_DIR} || exit 1;
			HEAD=`git -C ${GIT_DIR} rev-parse HEAD` || exit 1;
			touch ${DIRECTORY}/fam.lock
			CUR_REV=`${FAM_BASE}/bin/locktoml ${DIRECTORY}/fam.lock ${DEP_NAME} ${HEAD}`
			if [ "${CUR_REV}" != "" ]; then
				git -C ${GIT_DIR} checkout ${CUR_REV} || exit 1;
			fi
		fi
		CONFIG_PATH="target/deps/dl/${DEP_NAME}"
	else
		CONFIG_PATH=`${FAM_BASE}/scripts/dep_path.sh ${TOML} ${i}` || exit 1;
	fi

	if [[ "${CONFIG_PATH}" == /* ]]; then
		# Absolute path: use CONFIG_PATH directly
		DEP_PATH="${CONFIG_PATH}"
	else
		# Relative path: prepend DIRECTORY
		DEP_PATH="${DIRECTORY}/${CONFIG_PATH}"
	fi


	#DEP_PATH="${DIRECTORY}/${CONFIG_PATH}";
	${FAM_BASE}/scripts/dep.sh ${DEP_PATH} ${DEST_PATH} || exit 1;
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
	# Initialize the extern flags for dependencies
	EXTERN_FLAGS=""

	# Find all dependency directories in ${DIRECTORY}/target/deps/
	DEP_DIRS=$(find "${DIRECTORY}/target/deps" -maxdepth 1 -type d -not -path "${DIRECTORY}/target/deps")

	if [ "${CRATE_TYPE}" = "bin" ]; then
		CT="lib";
	elif [ "${CRATE_TYPE}" = "proc-macro" ]; then
		CT="proc-macro";
	else
		CT="lib"
	fi


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
				fi
			fi
		done
	fi

	if [ "${CRATE_TYPE}" = "proc-macro" ]; then
		EXT=${MACRO_EXT}
		PANIC_ABORT=""
	else
		PANIC_ABORT="-C panic=abort"
		EXT=rlib
	fi

	COMMAND="${RUSTC} ${PANIC_ABORT} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=${CT} -o ${DIRECTORY}/target/objs/lib${CRATE_NAME}.${EXT} ${EXTERN_FLAGS} ${DIRECTORY}/rust/lib.rs -L${DIRECTORY}/target/deps/rlibs"


	echo ${COMMAND}
	${COMMAND} || exit 1;
fi

. ${FAM_BASE}/scripts/linker.sh ${DIRECTORY}

CRATE_TYPE=`${FAM_BASE}/scripts/crate_type.sh ${TOML}` || { echo "Error parsing $1"; exit 1; }
if [ "${CRATE_TYPE}" = "lib" ]; then
	if [ "$OS" = "Linux" ]; then
		FINAL_OUTPUT=${DIRECTORY}/target/out/lib${CRATE_NAME}.so
	elif [ "$OS" = "Darwin" ]; then
		FINAL_OUTPUT=${DIRECTORY}/target/out/lib${CRATE_NAME}.dylib
	fi
else
	FINAL_OUTPUT=${DIRECTORY}/target/out/${CRATE_NAME}
fi

NEED_UPDATE=0
for file in `find ${DIRECTORY}/target/objs/*.o`
do
	if [ ! -e ${FINAL_OUTPUT} ] || [ $file -nt ${FINAL_OUTPUT} ]; then
		NEED_UPDATE=1
		break
	fi
done

if [ ${NEED_UPDATE} -eq 1 ]; then
	COUNT=$(find "${DIRECTORY}/target/deps" -maxdepth 1 -type d -not -path "${DIRECTORY}/target/deps" | wc -l);
	if [ $COUNT -ne 0 ]; then
		OBJ_COUNT=$(find "${DIRECTORY}/target/deps" -maxdepth 3 -type f -path "*/objs/*.o" 2>/dev/null | wc -l)
		if [ "${OBJ_COUNT}" -ne 0 ]; then
			DEPS_OBJS=${DIRECTORY}/target/deps/*/objs/*.o
		else
			DEPS_OBJS=
		fi
	else
		DEPS_OBJS=
	fi
	SRC_OBJS=${DIRECTORY}/target/objs/*.o

	RLIB_OBJS=
	if [ -d "${DIRECTORY}/target/deps/rlibs" ]; then
		OBJ_COUNT=$(find "${DIRECTORY}/target/deps/rlibs" -maxdepth 1 -type f -name "*.o" 2>/dev/null | wc -l)
		if [ "${OBJ_COUNT}" -gt 0 ]; then
			# Use wildcard to include all .o files
        		RLIB_OBJS="${DIRECTORY}/target/deps/rlibs/*.o"
    		fi
	fi

	if [ "${CRATE_TYPE}" = "lib" ]; then
		if [ "$OS" = "Linux" ]; then
			SHARED=-shared
		elif [ "$OS" = "Darwin" ]; then
			SHARED="-dynamiclib -Wl,-install_name,@rpath/lib${CRATE_NAME}.dylib"
		fi
	else
		SHARED=
	fi

	COMMAND="${CC} ${SHARED} -o ${FINAL_OUTPUT} ${DIRECTORY}/target/linker_main.o ${LINKEXTRA} ${DEPS_OBJS} ${RLIB_OBJS} ${SRC_OBJS} ${LINK}"
	echo "${COMMAND}";
	${COMMAND} || exit 1;
fi
