#!/bin/sh

touch ${DIRECTORY}/src/lib.rs
fam --test --rustflags="-C debuginfo=2" --ccflags="-g" || exit 1;
${DIRECTORY}/target/lib/test || exit 1;
