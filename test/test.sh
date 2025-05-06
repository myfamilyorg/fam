#!/bin/bash

if [ "$NO_COLOR" = "" ]; then
   GREEN="\033[32m";
   CYAN="\033[36m";
   YELLOW="\033[33m";
   BRIGHT_RED="\033[91m";
   RESET="\033[0m";
   BLUE="\033[34m";
else
   GREEN="";
   CYAN="";
   YELLOW="";
   BRIGHT_RED="";
   RESET="";
   BLUE="";
fi

run_test() {
	local TARGET="$1"
	local EXPECTED="$2"

	fam clean -d=${TARGET}
	fam -d=${TARGET}
	./${TARGET}/target/out/${TARGET}
	RESULT=$?;
	if [ "${RESULT}" != "${EXPECTED}" ]; then
        	printf "${BRIGHT_RED}TEST FAILED:${RESET} '${TARGET}'. Expected: ${EXPECTED}. Found: ${RESULT}\n";
        	exit 1;
	fi
	fam clean -d=${TARGET}
}

run_test "crate1" 8
run_test "crate2" 10
run_test "crate3" 99
run_test "crate5" 51

printf "${GREEN}All tests succeeded!${RESET}\n";
