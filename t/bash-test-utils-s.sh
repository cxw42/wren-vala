#! /bin/bash

# From https://github.com/tapper/Tapper-autoreport/blob/018eb58f5cde79ef0c8aed0dae1a78a7d67daed1/bash-test-utils

# Copyright (c) 2008-2012, Advanced Micro Devices, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ====================================================================
#
# bash-test-utils
# ----------------
#
# This is the "bash-test-utils" bash utility -- a bash include file
# to turn your bash script into a test suite.
#
# It also allows your bash script to be used with the "prove" command,
# a tool to run test scripts that produce TAP output (Test Anything
# Protocol).
#
# It was derived from "Tapper-autoreport" by simply dropping all
# Tapper specific features like: file upload, Tapper testrun context
# detection, and special parameter handling.
#
# It is licensed under a 2-clause BSD license. See the LICENSE file
# (reproduced above).
#
# ====================================================================


# ==================== Utility functions =============================

# constants
_SUCCESS=0
_FAILURE=1

# checks whether the module is ther
has_module () {
    module="${1:-UNKNOWNMODULE}"
    if lsmod | grep -q "^$module\b" ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if the cpbdisable file does not exist in sysfs
require_module () {
    module="${1:-UNKNOWNMODULE}"
    explanation="${2:-No module $module disable}"
    if has_module "$module"; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_module" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# checks whether the program is available
has_program () {
    _has_program_program="${1:-UNKNOWNPROGRAM}"
    if which "$_has_program_program" > /dev/null 2>&1 ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if program not available
require_program () {
    program="${1:-UNKNOWNPROGRAM}"
    explanation="${2:-Missing program $program}"
    if has_program "$program" ; then
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# checks whether the file is available
has_file () {
    file="${1:-UNKNOWNFILE}"
    explanation="${2:-Missing file $file}"
    if [ -e "$file" ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if file not available
require_file () {
    file="${1:-UNKNOWNFILE}"
    explanation="${2:-Missing file $file}"
    if has_file "$file" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_file $file" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# return whether environment variable is set to expected value
has_env () {
    _ltu_require_env_name="${1:-}"
    _ltu_require_env_expected_value="${2:-}"
    _ltu_require_env_actual_value="${!_ltu_require_env_name}"
    if [ "x$_ltu_require_env_actual_value" = "x$_ltu_require_env_expected_value" ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if environment variable does not equal a particular value
require_env_eq () {
    _ltu_require_env_name="${1:-}"
    _ltu_require_env_expected_value="${2:-}"
    _ltu_require_env_actual_value="${!_ltu_require_env_name}"
    explanation="require environment variable $_ltu_require_env_name = '$_ltu_require_env_expected_value' (actual value: '$_ltu_require_env_actual_value')"

    if has_env "$_ltu_require_env_name" "$_ltu_require_env_expected_value" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then
            ok $_SUCCESS "$explanation"
        fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if environment variable equals a particular value
require_env_not_eq () {
    _ltu_require_env_name="${1:-}"
    _ltu_require_env_expected_value="${2:-}"
    _ltu_require_env_actual_value="${!_ltu_require_env_name}"
    explanation="require environment variable $_ltu_require_env_name != '$_ltu_require_env_expected_value' (actual value: '$_ltu_require_env_actual_value')"

    if ! has_env "$_ltu_require_env_name" "$_ltu_require_env_expected_value" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then
            ok $_SUCCESS "$explanation"
        fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

get_first_file () {
    for i in $(seq 1 $#) ; do
        file=${!i}
        if [ -r "$file" ] ; then
            echo "$file"
            return
        fi
    done
}

autoreport_skip_all () {
    explanation="${1:-'no explanation'}"
    SKIPALL="1..0 # skip $explanation"
    if [[ -n $EXIT_ON_SKIPALL ]]; then
        exit 254
    else
        done_testing
        exit 0
    fi
}

# ==================== TAP utils ====================

get_tap_counter () {
     echo ${#TAP[@]}
}

get_tapdata_counter () {
     echo ${#TAPDATA[@]}
}

append_timestamp () {
    append_comment "Test-Timestamp: $(date '+%s')"
}

append_tap () {
    tapline="${1:-'not ok - unknown TAP line in utility function append_tap'}"
    TAP=( "${TAP[@]}" "$tapline" )
    if [ "x1" = "x$GENERATE_TIMESTAMPS" ] ; then
        append_timestamp
    fi
}

append_tapdata () {
    tapline="${1:-'not ok - unknown TAP line in utility function append_tapdata'}"
    TAPDATA=( "${TAPDATA[@]}" "$tapline" )
}

append_comment () {
    tapline="# ${@:-''}"
    TAP=( "${TAP[@]}" "$tapline" )
    COMMENTCOUNTER=$((COMMENTCOUNTER + 1))
}

diag () {
    while read line
    do
        append_comment "$line"
    done <<< "${@}"
}

diag_file () {
    while read line
    do
        append_comment "$line"
    done < "$1"
}

print_and_diag () {
    while read line
    do
        echo "# $line"
        append_comment "$line"
    done <<< "${@}"
}

print_and_diag_file () {
    while read line
    do
        echo "# $line"
        append_comment "$line"
    done < "$1"
}

is () {
    A="${1:-}"
    B="${2:-}"
    msg="${3:-unknown}"

    if [ "x$A" != "x$B" ] ; then
        append_tap "not ok - $msg"
        append_comment "Failed test '$msg'"
        append_comment "got: '$A'"
        append_comment "expected: '$B'"
    else
        append_tap "ok - $msg"
    fi
}

isnt () {
    A="${1:-}"
    B="${2:-}"
    msg="${3:-unknown}"

    if [ "x$A" = "x$B" ] ; then
        append_tap "not ok - $msg"
        append_comment "Failed test '$msg'"
        append_comment "got: '$A'"
        append_comment "expected: anything else"
    else
        append_tap "ok - $msg"
    fi
}

# checks for success, usually the last command's error code
has_success () {
    success="${1:-0}"
    if [ "$success" = "0" ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if no successful errorcode
require_success () {
    success="${1:-0}"
    explanation="${2:-successful error code required ($success)}"
    if has_success "$success" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_success $success" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

require_ok () {
    success="${1:-0}"
    msg="${2:-unknown}"
    if [ "$success" != "0" ] ; then
        NOT="not "
    else
        NOT=""
    fi
    append_tap "${NOT}ok - $msg"

    if [ "$success" = "0" ] ; then
        return
    fi

    # similar to SKIPALL but report what we have so far
    if [[ -n $EXIT_ON_SKIPALL ]]; then
        exit 254
    else
        done_testing
        exit 0
    fi
}

ok () {
    success="${1:-0}"
    msg="${2:-unknown}"
    if [ "$success" != "0" ] ; then
        NOT="not "
    else
        NOT=""
    fi
    append_tap "${NOT}ok - $msg"
    return $success
}

negate_ok () {
    success="${1:-0}"
    msg="${2:-unknown}"
    if [ "$success" == "0" ] ; then
        NOT="not "
    else
        NOT=""
    fi
    append_tap "${NOT}ok - $msg"
    return $success
}

get_hex_from_int () { # returns lower case
    printf "%x\n" "$1"
}

lower_case () {
    string="${1:-}"
    echo $(echo "$string" | tr '[A-Z]' '[a-z]')
}

get_random_number () {
    range_max="${1:-32768}"
    number=$RANDOM
    let "number %= $range_max"
    echo "$number"
}

get_kernel_release_1 () {
    uname -r | cut -d. -f1
}

get_kernel_release_2 () {
    uname -r | cut -d. -f2
}

get_kernel_release_3 () {
    uname -r | cut -d. -f3 | sed -s 's/^\([0-9]*\).*$/\1/'
}

get_kernel_release () {
    echo $(uname -r | cut -d. -f1-2).$(get_kernel_release_3)
}

normalize_version_number () {
    A="${1:-0}"
    # triplets x.y.z are converted to x + y/thousands + z/millions
    # easier, but requires awk:
    # awk -F. '{printf ("%d.%03d%03d\n",$1,$2,$3);}'
    # we have to do a trick do avoid octal interpretation due to leading
    # zeros, we use $((10#<number>)), which overrides with a base of 10
    if echo $A | grep -q '\.' ; then
        printf "%d.%03d%03d\n" $((10#$(echo "$A" | cut -d. -f1))) $((10#$(echo "$A" | cut -d. -f2))) $((10#$(echo "$A" | cut -d. -f3)))
    else
        echo "$A.000000"
    fi
}

version_number_compare () {
    A="${1:-0}"
    COMPARATOR="${2:-'-eq'}"
    B="${3:-0}"

    An=$(normalize_version_number $A | tr -d .)
    Bn=$(normalize_version_number $B | tr -d .)

    test "$An" $COMPARATOR "$Bn"
}

version_number_gt () {
    A="${1:-0}"
    B="${2:-0}"
    return $(version_number_compare "$A" -gt "$B")
}

version_number_ge () {
    A="${1:-0}"
    B="${2:-0}"
    return $(version_number_compare "$A" -ge "$B")
}

version_number_lt () {
    A="${1:-0}"
    B="${2:-0}"
    return $(version_number_compare "$A" -lt "$B")
}

version_number_le () {
    A="${1:-0}"
    B="${2:-0}"
    return $(version_number_compare "$A" -le "$B")
}

# This function is guaranteed (by contract) to be called ONLY during include
initialize_variables_once () {
    _LTU_EXITCODE=0
    _LTU_FILECOUNT=0
    _LTU_ORIGINAL_STARTDIR=$(pwd)
}

prepare_information () {

    # ===== control variables defaults ==================

    # by default require_* functions generate TAP ok lines
    REQUIRES_GENERATE_TAP=${REQUIRES_GENERATE_TAP:-1}

    # ===== kernel details ==================

    kernelrelease=$(uname -r)

    # ===== suite name ==================

    myname=$(echo $(basename -- $0 | sed -e 's/\.\w*$//i'))

    SUITE=${myname:-bash-test-utils}
    VERSION=2.000

    # ===== other meta info ==================

    suite_name=${SUITENAME:-$(echo $SUITE)}
    suite_version=${SUITEVERSION:-$VERSION}
    hostname=${HOSTNAME:-$(hostname)}
    hostname=$(echo $hostname | cut -d. -f1)

    if [ -e /etc/issue.net ]
    then
        osname=${OSNAME:-$(cat /etc/issue.net | head -1)}
    else
        osname=${OSNAME:-$(uname -o)}
    fi

    changeset=${CHANGESET:-$(cat /proc/version | head -1)}
    kernelflags=$(cat /proc/cmdline)
    uname=$(uname -a)
    ram=$(free -m | grep -i mem: | awk '{print $2}'MB)
    starttime_test_program=${starttime_test_program:-$(date --rfc-2822)} # first occurrence
    starttime_test_program_epoch=${starttime_test_program_epoch:-$(date +"%s")}
    endtime_test_program=$(date --rfc-2822) # last occurrence
    endtime_test_program_epoch=$(date +"%s")
    bogomips=$(echo $(cat /proc/cpuinfo | grep -i bogomips | head -1 | cut -d: -f2))

    #run_hook "prepare_information"
} # prepare_information()

suite_meta () {
    if [[ -n $VERBOSE ]]; then
        echo "# Test-section: $suite_name";
        echo "# Test-suite-version: $suite_version";
    fi
    echo "# Test-suite-name: $suite_name";
    echo "# Test-machine-name: $hostname";

    #run_hook "suite_meta"
}

ltu_base_os_description () {
    if [ -r /etc/lsb-release ] ; then
        . /etc/lsb-release
        BASE_OS_DESCRIPTION="$DISTRIB_DESCRIPTION"
    else
        RELEASE_FILES="/etc/slackware-version /etc/gentoo-release /etc/SuSE-release /etc/issue /etc/issue.net /etc/motd"
        for i in $RELEASE_FILES ; do if [ -r $i ] ; then RELEASE_FILE=$i ; break ; fi; done
        BASE_OS_DESCRIPTION=$(cat $RELEASE_FILE | perl -ne 'print if /\w/' | head -1)
    fi
    echo $BASE_OS_DESCRIPTION
}

ltu_section_meta () {
    if [ ! "x1" = "x$DONTREPEATMETA" ] ; then
        echo "# Test-uname: $uname"
        echo "# Test-osname: $osname"
        echo "# Test-kernel: $kernelrelease"
        echo "# Test-changeset: $changeset"
        echo "# Test-flags: $kernelflags"
        echo "# Test-ram: $ram"
        echo "# Test-starttime-test-program: $starttime_test_program"
        echo "# Test-endtime-test-program: $endtime_test_program"
    fi

    if [ -n "$SECTION" ] ; then
        echo "# Test-section:              $SECTION"
    fi
}

ltu_help () {
    echo "bash-test-utils"
    echo ""
    echo "This is the 'bash-test-utils' bash utility -- a bash include file"
    echo "to turn your bash script into a test suite that can optionally be"
    echo "used with the 'prove' command, a standard tool to run test scripts."
    echo ""
    echo "Use in your script:"
    echo "  . ./bash-test-utils"
    echo "  # ... your testing here, eg.:"
    echo "  grep -q foobar /proc/cpuinfo"
    echo '  ok $? "found foobar in cpuinfo"'
    echo "  done_testing"
    echo ""
    echo "Run:"
    echo "  prove    ./examples/utils-example-01.t"
    echo "  prove -v ./examples/utils-example-01.t  # verbose"
    echo "  prove    ./examples/                    # whole subdir"
    echo ""
}

ltu_version () {
    echo "$VERSION"
}

# ===== param evaluation ==============================

prepare_start () {

    prepare_information
    # other context sensitive initialization (eg. default, destructive, ...)

    # public
    TESTRESULTSFILE=${TESTRESULTSFILE:-testresults.tgz}

    # private
    _TAPFILE=${_TAPFILE:-tests.tap}
    _UPLOADSFILE=${_UPLOADSFILE:-files.tgz}
}

prepare_plan () {
    # count of our own tests
    COUNT=${#TAP[@]}
    PLAN=$(($MYPLAN + $COUNT - $COMMENTCOUNTER))
}

# ===== main =========================================

autoreport_main () {

    COMMENTCOUNTER=${COMMENTCOUNTER:-0}

    if [ -n "$SKIPALL" ] ; then
        echo "$SKIPALL"
        suite_meta
        if [[ -n $VERBOSE ]]; then
            ltu_section_meta
        fi
        return
    fi

    # ==================== prepare plan

    # count of tests until "END of own tests"
    MYPLAN=2   # initialize with count of default entries
    prepare_plan
    echo "TAP Version 13"
    echo "1..$PLAN"

    # ==================== meta info ====================
    suite_meta
    if [[ -n $VERBOSE ]]; then
        ltu_section_meta
    fi

    # =============== own headers (later entries win) ===============
    HEADERSCOUNT=${#HEADERS[@]}
    for l in $(seq 0 $(($HEADERSCOUNT - 1))) ; do
        echo ${HEADERS[l]}
    done

    # ,==================== BEGIN of own tests ====================
    # |
    #
    echo "ok - survived"
    #
    # |
    # `==================== END of own tests ====================

    # ==================== remaining TAP ====================
    for l in $(seq 0 $(($COUNT - 1))) ; do
        echo "${TAP[l]}"
        if echo "${TAP[l]}" | grep -q '^not ok ' ; then
            if [ "$_LTU_EXITCODE" -lt 253 ] ; then # avoid overflow; and 254 means SKIPALL
                let _LTU_EXITCODE++
            fi
        fi
    done

    # ==================== additional TAP/YAML data ====================
    echo "ok - tapdata"
    echo "  ---"
    echo "  tapdata: 1"
    if [ -n "$starttime_test_program_epoch" ] && [ -n "$endtime_test_program_epoch" ] ; then
        echo "  starttime: $starttime_test_program_epoch"
        echo "  endtime: $endtime_test_program_epoch"
        echo "  runtime: $((endtime_test_program_epoch-starttime_test_program_epoch))"
    fi
    TAPDATACOUNT=${#TAPDATA[@]}
    if [ "$TAPDATACOUNT" -gt 0 ] ; then
        for l in $(seq 0 $(($TAPDATACOUNT - 1))) ; do
            echo "  ${TAPDATA[l]}"
        done
    fi
    echo "  ..."

    # ==================== remaining output ====================
    OUTPUTCOUNT=${#OUTPUT[@]}
    for l in $(seq 0 $(($OUTPUTCOUNT - 1))) ; do
        echo ${OUTPUT[l]}
    done

    if set | grep -q '^main_end_hook \(\)' ; then
        main_end_hook
    fi
}

upload_file () {
    _ta_upload_file="${1:-0}"
    _LTU_FILES[$_LTU_FILECOUNT]="$_ta_upload_file"
    let _LTU_FILECOUNT=_LTU_FILECOUNT+1
}

# ===== main =========================================

done_testing_to_stdout () {
    prepare_start "${@}"
    autoreport_main
}

done_testing () {
    cd $_LTU_ORIGINAL_STARTDIR

    done_testing_to_stdout "${@}"

    if [ "x$PROVIDE_EXITCODE" = "x1" ] ; then
        return $_LTU_EXITCODE
    fi
}

#run_hook "functions"

# =====================================================

function recover_kill {
    ok 1 'GOT KILLED EXTERNALLY'
    done_testing
    if [ "x$PROVIDE_EXITCODE" = "x1" ] ; then
        exit $_LTU_EXITCODE
    fi
    exit
}

trap "recover_kill" SIGTERM SIGHUP SIGINT SIGKILL

# =====================================================

[ "$1" == "--help" ]         && ltu_help    && exit $_SUCCESS
[ "$1" == "--version" ]      && ltu_version && exit $_SUCCESS

# =====================================================

initialize_variables_once
prepare_information
