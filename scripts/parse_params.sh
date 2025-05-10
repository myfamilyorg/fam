#!/bin/bash

parse_args() {
    CLEAN=0
    ALL=0
    COVERAGE=0
    TEST=0
    COMMAND_SET="0";
    DIRECTORY="`pwd`";

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
	echo "usage: fam [all | test | coverage | clean] <options>";
}
