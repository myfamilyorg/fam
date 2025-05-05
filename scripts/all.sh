#!/bin/bash

TOML=${DIRECTORY}/fam.toml
CRATE_NAME=`${FAM_BASE}/scripts/crate_name.sh ${TOML}`

mkdir -p ${DIRECTORY}/target/objs
mkdir -p ${DIRECTORY}/target/out

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
	COMMAND="${RUSTC} ${RUSTEXTRA} --crate-name=${CRATE_NAME} --crate-type=lib -o ${DIRECTORY}/target/objs/lib${CRATE_NAME}.rlib ${DIRECTORY}/rust/lib.rs"
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
	COMMAND="${CC} -o ${DIRECTORY}/target/out/${CRATE_NAME} ${LINKEXTRA} ${DIRECTORY}/target/objs/*.o"
	echo ${COMMAND}
	${COMMAND} || exit 1;
fi
