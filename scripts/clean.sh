#!/bin/sh

if [ -e ${DIRECTORY}/target ]; then
        COMMAND="rm -rf ${DIRECTORY}/target/*";
        ${COMMAND}
fi
