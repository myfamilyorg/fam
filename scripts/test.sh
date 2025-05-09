#!/bin/bash

touch ${DIRECTORY}/rust/lib.rs
${FAM_BASE}/scripts/fam all --enable-tests || exit 1;
${DIRECTORY}/target/out/test
