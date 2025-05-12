#!/bin/bash

parse_args() {
    CLEAN=0
    ALL=0
    COVERAGE=0
    TEST=0
    COMMAND_SET="0";
    DIRECTORY="`pwd`";
    VERBOSE=0;
    STATIC="";
    LINK_FLAGS="-nodefaultlibs -lc"

    CC=clang
    CCFLAGS="-O3 -flto"

    for arg in "$@"; do
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
            -d=*)
		DIRECTORY=${arg#*=};
            ;;
            --cc=*)
                CC=${arg#*=};
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
            --static)
	        STATIC="-static";
		LINK_FLAGS="";
            ;;
            *)
		echo "Unexpected param: $arg";
		usage
		exit 1;
            ;;
        esac
    done

    if [ "${COMMAND_SET}" = "0" ]; then
	    ALL=1
    fi

}

usage() {
	echo "Usage: fam [all | test | coverage | clean] <options>";
}
