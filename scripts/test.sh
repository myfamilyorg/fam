#!/bin/sh

if [ -d "${DIRECTORY}/c" ]; then
    if ls ${DIRECTORY}/c/* >/dev/null 2>&1; then
        touch ${DIRECTORY}/c/*
    fi
fi
fam --test || exit 1;
${DIRECTORY}/target/lib/test || exit 1;
