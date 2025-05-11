#!/bin/bash

parse_args() {
    CLEAN=0
    ALL=0
    COVERAGE=0
    TEST=0
    COMMAND_SET="0";
    DIRECTORY="`pwd`";
    VERBOSE=0;
    RUSTC=rustc;
    LINK_LIB=staticlib;
    export CC=clang
    CCFLAGS="-O3 -flto"
    COMPILE_TESTS=0

    dir_set=0;
    exp_dir=0;
    for arg in "$@"; do
	if [ ${exp_dir} -eq 1 ]; then
		DIRECTORY=$arg
		dir_set=1;
		exp_dir=0;
		continue;
	fi
        case "$arg" in
            test)
                TEST=1
		if [ "${COMMAND_SET}" = "1" ]; then
			echo "Error: more than one main command set"
                        usage
                        exit 1;
                fi
		COMMAND_SET="1";
            ;;
            coverage)
		COVERAGE=1
		if [ "${COMMAND_SET}" = "1" ]; then
			echo "Error: more than one main command set"
                        usage
                        exit 1;
                fi
		COMMAND_SET=1;
	    ;;
	    all)
		ALL=1
		if [ "${COMMAND_SET}" = "1" ]; then
			echo "Error: more than one main command set"
                        usage
                        exit 1;
                fi
		COMMAND_SET=1;
	    ;;
            clean)
		CLEAN=1
		if [ "${COMMAND_SET}" = "1" ]; then
			echo "Error: more than one main command set"
			usage
			exit 1;
		fi
		COMMAND_SET=1;
            ;;
            -d)
                if [ ${dir_set} -eq 1 ]; then
			echo "Error: -d option specified twice"
			usage
			exit 1;
		fi
                exp_dir=1;
            ;;
            --cc=*)
                export CC=${arg#*=};
            ;;
            --rustc=*)
                RUSTC=${arg#*=};
            ;;
            --ccflags=*)
                CCFLAGS=${arg#*=};
            ;;
            --rustflags=*)
		RUSTFLAGSSET=1
                RUSTFLAGS=${arg#*=};
            ;;
            --verbose)
                VERBOSE=1;
            ;;
            --test)
                COMPILE_TESTS=1;
            ;;
            *)
		echo "Unexpected param: $arg";
		usage
		exit 1;
            ;;
        esac
    done

    if ${RUSTC} --version | grep -q "mrustc"; then
        if [ "$RUSTFLAGSSET" = "" ]; then
            RUSTFLAGS="-O"
	fi
        LINK_LIB=lib
	OBJ_EXT=""
    else
	if [ "$RUSTFLAGSSET" = "" ]; then
            RUSTFLAGS="-C opt-level=3"
        fi  
        LINK_LIB=staticlib;
	OBJ_EXT=".o"
    fi
    if [ "${COMMAND_SET}" = "0" ]; then
	    ALL=1
    fi

}

usage() {
	echo "Usage: fam [all | test | coverage | clean] <options>";
}
