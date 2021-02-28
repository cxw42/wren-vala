#!/bin/bash

. bash-test-utils.sh
ok $_SUCCESS "sanity"

diff <(./110-hello-world-s) <(printf "Hello, world!\n") &> /dev/null
ok $? "110-hello-world-s output from script"

done_testing
