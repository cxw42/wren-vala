#!/bin/bash
# coverage.sh: generate code-coverage information.
# To see the compilation steps, run `V=1 ./coverage.sh`.
# Copyright (c) 2020--2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

set -x
set -eEuo pipefail

# Reconfigure if necessary so that coverage is enabled
if [[ ! -x ./config.status ]] || \
        ! ./config.status --config | grep -- '--enable-code-coverage'
then
    ./bootstrap
    touch `git ls-files '*.vala' '*.c' '*.h'`   # Force rebuilding
    ./configure --enable-code-coverage USER_VALAFLAGS='-g' CFLAGS='-g -O0' "$@"
fi

# Clean up from old runs
make -j4 remove-code-coverage-data

# Check it
make -j4 check-code-coverage
