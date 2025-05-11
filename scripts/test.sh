#!/bin/sh

fam --test || exit 1;
${DIRECTORY}/target/lib/test || exit 1;
