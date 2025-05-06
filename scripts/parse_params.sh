#!/bin/bash

# Main suboptions
ALL=0
TEST=0
COVERAGE=0
CLEAN=0
DIRECTORY="`pwd`"

export CC=clang
export RUSTC=rustc
COUNT=0;

for arg in "$@"; do
	case "$arg" in
		test)
			if [ ${COUNT} -ne 0 ]; then
				echo "Unexpected token: '$arg'";
				exit 1;
			fi
			TEST=1
		;;
		coverage)
			if [ ${COUNT} -ne 0 ]; then
				echo "Unexpected token: '$arg'";
                                exit 1;
                        fi      
			COVERAGE=1
                ;;
                clean)
                        if [ ${COUNT} -ne 0 ]; then
                                echo "Unexpected token: '$arg'";
                                exit 1;
                        fi
                        CLEAN=1
                ;;
		all)
                        if [ ${COUNT} -ne 0 ]; then
                                echo "Unexpected token: '$arg'";
                                exit 1;
                        fi
                        ALL=1
                ;;
		--cc=*)
			export CC=${arg#*=};
			if [ -z "${CC}" ]; then
                		echo "Error: --cc requires a non-empty value: --cc=cc" >&2
				exit 1;
			fi
		;;
		--cc)
			echo "Error: --cc requires a non-empty value: --cc=cc" >&2
			exit 1;
		;;
		--rustc=*)
			export RUSTC=${arg#*=};
			if [ -z "${RUSTC}" ]; then
				echo "Error: --rustc requires a non-empty value: --rustc=famc" >&2
				exit 1;
			fi
		;;
		--rustc)
			echo "Error: --rustc requires a non-empty value: --rustc=famc" >&2
			exit 1;
		;;
		-d=*)
			DIRECTORY=${arg#*=};
			if [ -z "${DIRECTORY}" ]; then
                                echo "Error: -d requires a non-empty value: -d=/path/to/project" >&2
                                exit 1;
                        fi
		;;
		-d)
			echo "Error: -d requires a non-empty value: -d=/path/to/project" >&2
                        exit 1;
		;;
		*)
			echo "ERROR: Unknown option: $arg" >&2
			exit 1;
		;;
	esac
	COUNT=$(expr $COUNT + 1)
done

if [ ! -e ${DIRECTORY}/fam.toml ]; then
        echo "Error: No fam.toml file in this directory.";
        exit 1;
fi

OS=$(uname -s)
if [ "$OS" = "Linux" ]; then
	LINK="-lm"
elif [ "$OS" = "Darwin" ]; then
	LINK=""
else
	echo "Only Linux and Macos are currrently supported."
	exit 1;
fi

if ${RUSTC} --version | grep -q "mrustc"; then
	EMIT_STR=""
	EXT_STR=""
	LIB_TYPE=lib
	LINKEXTRA="`${RUSTC} --output`/libcore.rlib.o"
else
	EMIT_STR="--emit=obj"
	EXT_STR=".o"
	LIB_TYPE=staticlib
	LINKEXTRA=""
fi

if [ ${CLEAN} -eq 0 ] && [ ${TEST} -eq 0 ] && [ ${COVERAGE} -eq 0 ]; then
	ALL=1
fi


