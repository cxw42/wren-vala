#!/bin/bash

. common.sh

grep -q "Num does not implement 'noSuchMethod'" <(./160-error-s noSuchMethod 2>&1)
ok $? "runtime error"

grep -q "Expected expression" <(./160-error-s compiletime 2>&1)
ok $? "compile-time error"

done_testing
