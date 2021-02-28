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
# It provides facilities to test Linux kernel in Xen/KVM contexts (in
# host and guest) and was polished to work with x86, x86_64, and ARM.
#
# It is licensed under a 2-clause BSD license. See the LICENSE file
# (reproduced above).
#
# ====================================================================


# ==================== Utility functions =============================

# constants
_SUCCESS=0
_FAILURE=1

declare -A program_package_mapping_ALinux
declare -A program_package_mapping_Debian

run_hook () {
    _hook=${1:-UNDEFINED}
    _TA_INC="bash-test-utils.hooks/$TESTUTIL_HOOKS/$_hook"
    if [ -e "$_TA_INC" ] ; then . $_TA_INC ; fi
}

# gets vendor "AMD" or "Intel" from /proc/cpuinfo
get_vendor () {
    vendor=$(echo $(grep vendor_id /proc/cpuinfo |head -1|cut -d: -f2|sed -e "s/Genuine\|Authentic//"))
    echo $vendor
}

# checks for vendor "Intel" in /proc/cpuinfo
vendor_intel () {
    grep -Eq 'vendor_id.*:.*Intel' /proc/cpuinfo
}

# checks for vendor "AMD" in /proc/cpuinfo
vendor_amd () {
    grep -Eq 'vendor_id.*:.*AMD' /proc/cpuinfo
}

# stops testscript if not matching required cpu vendor
require_vendor_intel () {
    if vendor_intel
    then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok 0 "require_vendor_intel" ; fi
        return $_SUCCESS
    else
        explanation="${1:-vendor does not match Intel}"
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if not matching required cpu vendor
require_vendor_amd () {
    if vendor_amd
    then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok 0 "require_vendor_amd" ; fi
        return $_SUCCESS
    else
        explanation="${1:-vendor does not match AMD}"
        autoreport_skip_all "$explanation"
    fi
}

# Checks for ARM cpu
arm_cpu () {
    grep -Eqi 'Processor.*:.*ARM' /proc/cpuinfo
}

# outputs cpu stepping from /proc/cpuinfo
get_cpu_stepping () {
    echo $(echo $(grep "^stepping" /proc/cpuinfo |head -1|cut -d: -f2))
}

# outputs cpu model from /proc/cpuinfo
get_cpu_model () {
    echo $(echo $(grep "^model[^ ]" /proc/cpuinfo |head -1|cut -d: -f2))
}

# outputs cpu model from /proc/cpuinfo
get_cpu_model_hex () {
    echo "0x"$(get_hex_from_int $(get_cpu_model))
}

# checks cpu model from /proc/cpuinfo against a minimum model
cpu_model_min () {
    min=${1:-0}
    mod=$(get_cpu_model)
    [ $(($mod)) -ge $(($min)) ]
}

# checks cpu model from /proc/cpuinfo against a maximum model
cpu_model_max () {
    max=${1:-0x999}
    mod=$(get_cpu_model)
    [ $(($mod)) -le $(($max)) ]
}

# outputs cpu family from /proc/cpuinfo
# since all testsuites using hex values, return value in hex format
get_cpu_family () {
    echo $(echo $(grep "^cpu family" /proc/cpuinfo |head -1|cut -d: -f2))
}

get_cpu_family_hex () {
    echo "0x"$(get_hex_from_int $(get_cpu_family))
}

# checks cpu family from /proc/cpuinfo against a minimum family
cpu_family_min () {
    min=${1:-0}
    fam=$(get_cpu_family)
    [ $(($fam)) -ge $(($min)) ]
}

# checks cpu family from /proc/cpuinfo against a maximum family
cpu_family_max () {
    max=${1:-0x999}
    fam=$(get_cpu_family)
    [ $(($fam)) -le $(($max)) ]
}

is_amd_family_range () {
    min="${1:-0}"
    max="${2:-$min}"
    if vendor_amd && cpu_family_min "$min" && cpu_family_max "$max" ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if not matching required cpu family from
# /proc/cpuinfo of a minimum/maximum range
require_amd_family_range () {
    min="${1:-0}"
    max="${2:-$min}"
    if is_amd_family_range "$min" "$max" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok 0 "require_amd_family_range $min $max" ; fi
        return $_SUCCESS
    else
        vendor=$(get_vendor);
        fam=$(printf "0x%x" $(get_cpu_family));
        explanation="${3:-Family $vendor/$fam does not match AMD/$min..$max}"
        autoreport_skip_all "$explanation"
    fi
}

# Checks all nodes for NB devices with one of the supplied PCI device ids
# Note: Call it separately for different PCI device functions
has_amd_nb_function_id () {
    devids=${@:-"0xffffffff"}

    for devid in $devids; do
        devid=$(printf '0x%x' $devid)
        nbdevs="/sys/bus/pci/devices/0000:00:1[89abcdef].*"

        [ $(ls $nbdevs 2>/dev/null | wc -l) -gt 0 ] || continue

        f0devs="/sys/bus/pci/devices/0000:00:1[89abcdef].0/vendor"
        northbridges=$(ls $f0devs 2>/dev/null | wc -l)

        devices=0
        for nbdev in $nbdevs; do
            vendor=$(cat $nbdev/vendor 2>/dev/null)
            if [ "$vendor" != "0x1022" ]; then
                return $_FAILURE
            fi

            device=$(cat $nbdev/device 2>/dev/null)
            if [ "$device" = "$devid" ]; then
                let devices++
            fi
        done

        if [ $devices -gt 0 -a $devices -eq $northbridges ]; then
            return $_SUCCESS
        fi
    done

    return $_FAILURE
}

# Stops if no NB devices with one of supplied PCI device ids exist on all nodes
# Note: Call it separately for different PCI device functions
require_amd_nb_function_id () {
    devids=${@:-"0xffffffff"}
    if has_amd_nb_function_id "$devids"; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_amd_nb_function_id" ; fi
    else
        autoreport_skip_all "No supported AMD northbridge function devices"
    fi
}

get_number_cpus () {
    (getconf _NPROCESSORS_ONLN || grep -ci "^bogomips" /proc/cpuinfo || echo -1) 2>/dev/null
}

# check sysfs whether cpu has L3 cache
has_l3cache () {
    if [ -d /sys/devices/system/cpu/cpu0/cache/index3 ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if cpu does not have L3 cache
require_l3cache () {
    explanation="${1:-No L3 cache}"
    if has_l3cache ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_l3cache" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# check x86_64
is_x86_64 () {
    if uname -m | grep -q x86_64 ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if is not x86_64
require_x86_64 () {
    explanation="${1:-No x86_64}"
    if is_x86_64 ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_x86_64" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# scan all PCI devices for one with XenSource's PCI-ID
has_xen_pci_device () {
    # try lspci (not in PATH if not root)
    _ta_xen_LSPCI=$(which lspci 2> /dev/null) || _ta_xen_LSPCI=/sbin/lspci
    if [ -x "$_ta_xen_LSPCI" ]
    then
        $_ta_xen_LSPCI -n | grep -q " 5853:"
        return $?
    else
        # directly query sysfs and check for XenSource's PCI-ID
        if [ -r /sys/bus/pci/devices/0000:00:00.0/vendor ] ; then
            cat /sys/bus/pci/devices/*/vendor | grep -q 0x5853
            return $?
        else
            return $_FAILURE
        fi
    fi
}

# checks the PCI hostbridge's vendor and optionally device ID
# usage: check_hostbridge 0x1022 (for checking for AMD northbridge)
#        check_hostbridge 0x8086 0x1237 (for QEMU host bridge)
check_hostbridge() (
    LSPCI=$(which lspci 2> /dev/null) || LSPCI=/sbin/lspci
    if [ -x "$LSPCI" ]
    then
        lspciout=$($LSPCI -s 0:0.0 -n | cut -d: -f3- | tr -d \ )
        vendor="0x$(echo $lspciout | cut -d: -f1)"
        device="0x$(echo $lspciout | cut -d: -f2)"
    else
        vendor=$(cat /sys/bus/pci/devices/0000:00:00.0/vendor)
        device=$(cat /sys/bus/pci/devices/0000:00:00.0/device)
    fi
    [ "$vendor" = "$1" ] || return $_FAILURE
    [ -z "$2" ] && return $_SUCCESS
    [ "$device" = "$2" ]
    return $?
)

# checks whether the Xen hypervisor is running
# this returns 0 if we are a Dom0 or PV DomU or HVM DomU
is_running_under_xen_hv () {
    if [ -r /sys/hypervisor/type ] ; then
        [ $(cat /sys/hypervisor/type) = "xen" ]
        return $?
    fi

    [ -r /proc/xen/capabilities ] && return $_SUCCESS

    # Linux denies registering XenFS if not running under Xen
    if has_kernel_config CONFIG_XENFS ; then
        grep -q xenfs /proc/filesystems
        return $?
    fi

    # TODO: do older kernels support this? At least RHEL5 does
    has_cpufeature hypervisor || return $_FAILURE

    _ta_e820prov=$(dmesg | sed -e 's/^\[.*\] *//' | grep -A1 "^BIOS-provided physical RAM map:" | tail -1 | cut -d: -f1)
    [ -n "$_ta_820prov" ] && [ "$_ta_e820prov" = "Xen" ] && return $_SUCCESS

    dmesg | grep -q "Booting paravirtualized kernel on Xen" && return $_SUCCESS

    return $_FAILURE
}

# check if we are in a Xen host
# it is a bit tricky to differentiate Dom0 and (PV-)DomU
is_running_in_xen_dom0 () {

    # this is a definite way to check for Dom0, but not always available, since
    # XENFS could not be mounted
    if [ -r /proc/xen/capabilities ] ; then
        grep -q control_d /proc/xen/capabilities
        return $?
    fi

    # this should sort out most of the other possibilities
    is_running_under_xen_hv || return $_FAILURE

    # we need to sort out only Dom0 vs. DomU from now on

    # an ATI or AMD northbridge means Dom0
    if check_hostbridge 0x1002 || check_hostbridge 0x1022 ; then
        return $_SUCCESS
    fi

    # a QEMU northbridge cannot be Dom0
    check_hostbridge 0x8086 0x1237 && return $_FAILURE

    # out of clues, but we are probably not Dom0 at this point anymore
    return $_FAILURE
}

# check if we are in a KVM host
is_running_in_kvm_host () {
    [ -e /dev/kvm ]
}

# check if we have KVM guests running
has_kvm_guests () {
    counter=$(lsmod |grep '^kvm_'|awk '{print $3}')
    if [ $counter -gt 0 ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

get_xen_tool () {
    which xl 2> /dev/null || which xm 2> /dev/null
}

get_number_xen_guests () {
    XL=$(get_xen_tool) || return $_FAILURE
    res=$($XL list | wc -l)
    if [ -n "$res" -a "$res" -ge 2 ] ; then
        echo "$((res-2))"
        return $_SUCCESS
    else
        echo "0"
        return $_FAILURE
    fi
}

# check if we are in a Xen guest
# Note:
#   In Xen the dom0 reports the same 'hypervisor' flag and CPUID entry
#   as in domU therefore the CPUID check is not enough, but dmidecode
#   and lspci show different devices inside a domU.
is_running_in_xen_guest () {

    is_running_under_xen_hv || return $_FAILURE

    has_xen_pci_device && return $_SUCCESS

    check_hostbridge 0x8086 0x1237 && return $_SUCCESS

    # try dmidecode
    if dmidecode > /dev/null 2>&1 ; then
        _dmi_chassis=$(dmidecode -s chassis-manufacturer)
        # dmidecode does not output anything in PV Xen
        if [ -n "$_dmi_chassis" ] ; then
            echo "$_dmi_chassis" | grep -q Xen
            return $?
        fi
    fi

    # last resort: check for Xen Dom0
    is_running_in_xen_dom0 && return $_FAILURE

    # there are no PCI device by default in PV guests
    _nr_pci_devices=$(ls /sys/bus/pci/devices | wc -l)
    [ "$_nr_pci_devices" -eq 0 ] && return $_SUCCESS

    # no more clues at this point, assume we are some kind of DomU
    return $_SUCCESS
}

# check if we are in a KVM guest
# Note:
#   In KVM the hypervisor CPUID check is relieable and we can first
#   narrow it against being not a Xen guest. After that the devices
#   are less significant in KVM so here we then check for the CPUID.
is_running_in_kvm_guest () {

    is_running_in_xen_guest && return $_FAILURE
    has_cpufeature hypervisor || return $_FAILURE

    # try to load the cpuid module if not already done
    [ -c /dev/cpu/0/cpuid ] || modprobe cpuid > /dev/null 2>&1

    if [ -c /dev/cpu/0/cpuid ] ; then
        virtvendor=$(dd if=/dev/cpu/0/cpuid bs=16 skip=67108864 count=1 2> /dev/null)
        [ "$virtvendor" = "KVMKVMKVM" ]
        return $?
    fi
    return 1
}

# check if we are in a virtualized guest (Xen or KVM)
is_running_in_virtualized_guest () {
    is_running_in_xen_guest || is_running_in_kvm_guest
    return $?
}

# stops testscript if we aren't a Xen guest
require_running_in_xen_guest () {
    explanation="${1:-Needs to run in Xen guest}"
    if is_running_in_xen_guest ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_running_in_xen_guest" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if we aren't a Xen dom0
require_running_in_xen_dom0 () {
    explanation="${1:-Needs to run in Xen dom0}"
    if is_running_in_xen_dom0 ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_running_in_xen_dom0" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if we aren't a KVM guest
require_running_in_kvm_guest () {
    explanation="${1:-Needs to run in KVM guest}"
    if is_running_in_kvm_guest ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_running_in_kvm_guest" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if we aren't a KVM host
require_running_in_kvm_host () {
    explanation="${1:-Needs to run in KVM host}"
    if is_running_in_kvm_host ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_running_in_kvm_host" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# stops testscript if we aren't a virtualized guest
require_running_in_virtualized_guest () {
    explanation="${1:-Needs to run in virtualized guest}"
    if is_running_in_virtualized_guest ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_running_in_virtualized_guest" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# checks for a feature flag in /proc/cpuinfo
has_cpufeature () {
    _ta_feature="${1:-UNKNOWNFEATURE}"
    if cat /proc/cpuinfo | grep -E '^flags\W*:' | head -1 | sed -e 's/^flags\W*://' | grep -q "\<${_ta_feature}\>" 2>&1 ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if a feature flag is not found in /proc/cpuinfo
require_cpufeature () {
    _ta2_feature="${1:-UNKNOWNFEATURE}"
    explanation="${2:-Missing cpufeature $_ta2_feature}"
    if has_cpufeature "$_ta2_feature" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_cpufeature $_ta2_feature" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# checks for a config in /proc/config.gz or /boot/config/$(uname -r)
has_kernel_config () {
    _ta3_feature="${1:-UNKNOWNFEATURE}"
    CONFIG=$(get_first_file "/proc/config.gz" "/boot/config-$(uname -r)")
    if [ -z "$CONFIG" ] ; then
        return $_FAILURE
    fi
    if echo $CONFIG | grep -q '\.gz' ; then
        gzip -cd "$CONFIG" | grep -q "^${_ta3_feature}=."
    else
        grep -q "^${_ta3_feature}=." "$CONFIG"
    fi
}

# stops testscript if a feature flag is not found in /proc/cpuinfo
require_kernel_config () {
    _ta4_feature="${1:-UNKNOWNFEATURE}"
    explanation="${2:-Missing kernel config $_ta4_feature}"
    if has_kernel_config "$_ta4_feature" ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_kernel_config $_ta4_feature" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

# Enable CPU frequency scaling and set sane defaults
# - Makes sure the appropriate cpufreq driver is loaded
# - Enables ondemand governor on all cores
# - Sets the boost state, on=1 (default), off=0
enable_cpufreq () {
    booststate="$1"
    [ "$booststate" != "0" ] && booststate=1

    # Load cpufreq driver module
    for module in acpi-cpufreq powernow-k8; do
        [ -d /sys/devices/system/cpu/cpu0/cpufreq ] && break
        modprobe $module 2>/dev/null
    done
    if [ ! -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        echo "failed to load cpufreq driver"
        return $_FAILURE
    fi

    # Load ondemand governor module and set ondemand governor
    if ! grep -q ondemand /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors; then
        modprobe cpufreq-ondemand 2>/dev/null
    fi
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo ondemand > $cpu 2>/dev/null
        if [ "$(cat $cpu)" != "ondemand" ]; then
            echo "failed to set ondemand governor"
            return $_FAILURE
        fi
    done

    # Set requested boost state
    if ! has_cpufeature cpb; then
        return $_SUCCESS
    elif [ -f /sys/devices/system/cpu/cpufreq/boost ]; then
        interfaces="/sys/devices/system/cpu/cpufreq/boost"
    elif [ $(ls /sys/devices/system/cpu/cpu*/cpufreq/cpb 2>/dev/null | wc -l) -gt 0 ]; then
        interfaces="/sys/devices/system/cpu/cpu*/cpufreq/cpb"
    elif grep -q " show_cpb\| show_global_boost" /proc/kallsyms; then
        echo "failed to find sysfs boost state interface"
        return $_FAILURE
    elif [ $booststate -eq 0 ]; then
        echo "cpufreq driver doesn't provide sysfs boost state interface"
        return $_FAILURE
    else
        return $_SUCCESS
    fi
    for interface in $interfaces; do
       echo $booststate > $interface 2>/dev/null
       if [ "$(cat $interface)" != "$booststate" ]; then
            echo "failed to set requested boost state"
            return $_FAILURE
       fi
    done

    return $_SUCCESS
}

require_cpufreq_enabled () {
    explanation="${1:-CPUFreq not available}"
    reason=$(enable_cpufreq 1)
    if [ $? -eq $_SUCCESS ] ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_cpufreq_enabled" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation ($reason)"
    fi
}

require_cpb_disabled () {
    explanation="${1:-Failed to disable Core Boosting}"
    reason=$(enable_cpufreq 0)
    if [ $? -eq $_SUCCESS ] ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_cpufreq_enabled" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation ($reason)"
    fi
}

request_cpufreq_enabled () {
    todo="# TODO $(enable_cpufreq 1)" && todo=""
    ok $? "request_cpufreq_enabled $todo"
    [ -n "$todo" ] && return $_FAILURE
    return $_SUCCESS
}

request_cpb_disabled () {
    todo="# TODO $(enable_cpufreq 0)" && todo=""
    ok $? "request_cpb_disabled $todo"
    [ -n "$todo" ] && return $_FAILURE
    return $_SUCCESS
}

# disables core performance boosting for reproducable and well scaling
# benchmarks. Tries hard to learn the actual state and to really disable
# it. Diagnostic messages will be print to stdout, the return value
# describes the success: 0=CPB is disabled, 1=CPB is (probably) still enabled.
# possible usage (failed disabling is non-fatal, but report it):
#   todostem="# TODO "
#   expl=$(disable_cpb) && todostem=""
#   ok $? "disable CPB $todostem$expl"
# or a fatal version ending the script:
#   expl=$(disable_cpb)
#   require_ok $? "disable CPB"
# or: just try to disable it, but don't care if we fail
#   disable_cpb > /dev/null
disable_cpb () {
    # check whether the CPB sysfs knob is there
    if [ ! -r /sys/devices/system/cpu/cpu0/cpufreq/cpb ] ; then
        is_running_in_virtualized_guest && _cpbhint=" (running virtualized)"
        # if the CPU does not support boosting, we dont care
        if ! has_cpufeature cpb ; then
            echo "# CPU has no CPB support$_cpbhint"
            return 0
        fi
        # is the powernow_k8 driver loaded?
        if ! grep -q " powernowk8_init" /proc/kallsyms; then
            # if not, try to load it
            if ! _modprobe_res=$(modprobe powernow_k8 2>&1) ; then
                echo "# modprobe powernow_k8: $_modprobe_res"
                return 1
            fi
        fi
        # does this version of powernow_k8 support CPB?
        if ! grep -q " show_cpb" /proc/kallsyms ; then
            echo "# powernow_k8 loaded, but no CPB support"
            return 1
        fi
    fi
    # now check for the sysfs knob again (we may have loaded the driver)
    if [ ! -r /sys/devices/system/cpu/cpu0/cpufreq/cpb ] ; then
        echo "# no sysfs knob for disabling CPB, probably still active"
        return 1
    fi

    # if the knob is there and it reads 0, everything is fine
    if [ $(cat /sys/devices/system/cpu/cpu0/cpufreq/cpb) = "0" ] ; then
        echo "# CPB already disabled"
        return 0
    fi
    # try to disable CPB on all cores and count the number of failures
    failures=0
    for cpb in /sys/devices/system/cpu/cpu*/cpufreq/cpb; do
        echo 0 2> /dev/null > $cpb || let failures++
    done
    # no failures means everything is fine
    if [ "$failures" = 0 ] ; then
        echo "# CPB successfully disabled"
        return 0
    fi
    # don't give up so quickly, try to explore dmesg for the right message
    if $(dmesg | grep -q "Core Boosting .*abled") ; then
        # there was at least one messages, check the last one
        if dmesg | grep -q "Core Boosting .*abled" | tail -1 | grep -q "Core Boosting disabled" ; then
            # the last message says its disabled, believe this
            echo "# CPB disabling failed, but probably disabled before"
            return 0
        else
            # the last message says its enabled, we failed eventually
            echo "# CPB disabling failed (no permissions), CPB active"
            return 1
        fi
    fi
    # we have no real clue at this point, but assume the worst
    echo "# CPB disabling failed, probably still active"
    return 1
}

# checks whether the cpbdisable file exists in sysfs
has_cpbdisable () {
    # This file's existence is not the best check.
    # It also exists on non-cpb systems.
    if [ -e /sys/devices/system/cpu/cpu0/cpufreq/cpb ] ; then
        return $_SUCCESS
    else
        return $_FAILURE
    fi
}

# stops testscript if the cpbdisable file does not exist in sysfs
require_cpbdisable () {
    explanation="${1:-No CPB disable}"
    if has_cpbdisable ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_cpbdisable" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

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

get_distro () {
    if grep -q "Amazon Linux" /etc/issue ; then
        echo ALinux
    elif grep -q "Ubuntu" /etc/issue ; then
        echo Ubuntu
    elif grep -q "Debian" /etc/issue ; then
        echo Debian
    fi
}

get_pkg_for_program () {
    _BTU_program="$1"
    _BTU_distro=$(get_distro)

    # Mapping of programs to RPM/DEB packages if pkg differs from program name
    declare -A default_program_package_mapping_ALinux
    declare -A default_program_package_mapping_Debian
    default_program_package_mapping_ALinux=( ["g++"]="gcc-c++" )
    default_program_package_mapping_Debian=( ["g++"]="g++" )

    _BTU_pkg=""
    if [ "xDebian" == "x$_BTU_distro" -o "xUbuntu" == "x$_BTU_distro"  ] ; then
        _BTU_pkg="${program_package_mapping_Debian[$_BTU_program]:-${default_program_package_mapping_Debian[$_BTU_program]}}"

    elif [ "xALinux" == "x$_BTU_distro" ] ; then
        _BTU_pkg="${program_package_mapping_ALinux[$_BTU_program]:-${default_program_package_mapping_ALinux[$_BTU_program]}}"

    fi

    if [ -z "$_BTU_pkg" ] ; then
        _BTU_pkg="$_BTU_program"
    fi

    echo "$_BTU_pkg"
}

# installs program (assume deb/rpm packagename == program name)
install_program () {
    _install_program_program="$1"
    if [ -z "$_install_program_program" ] ; then
        diag "install_program: no program name provided"
        return
    fi

    if ! has_program "$program" ; then
        _install_program_pkg=$(get_pkg_for_program $_install_program_program)
        print_and_diag "INSTALLING program: $_install_program_program (package '$_install_program_pkg') ..."

        if has_program "aptitude" ; then
            sudo aptitude update
            sudo aptitude -y install "$_install_program_pkg"
        elif has_program "yum" ; then
            sudo yum -y update
            sudo yum -y install "$_install_program_pkg"
        else
            print_and_diag "Neither 'aptitude' nor 'yum' available."
        fi
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

# get environment variable
get_env () {
    _ltu_get_env_name="${1:-}"
    explanation="${2:-No environment variable $_ltu_get_env_name}"

    echo "${!_ltu_get_env_name}"
    return
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

# checks whether the script's criticality is in allowed range
has_crit_level () {
    _ta_crit_level="${1:-5}"
    _ta_crit_level_allowed="${CRITICALITY:-0}"
    if [ $_ta_crit_level -le $_ta_crit_level_allowed ] ; then
        return $_SUCCESS;
    else
        return $_FAILURE
    fi
}

# stops testscript if script's criticality is not in allowed range
require_crit_level () {
    _ta_crit_level="${1:-5}"
    _ta_crit_level_allowed="${CRITICALITY:-0}"
    explanation="${2:-Too high criticality level: $_ta_crit_level (CRITICALITY=$_ta_crit_level_allowed)}"

    if has_crit_level $_ta_crit_level ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "criticality level $_ta_crit_level (CRITICALITY=$_ta_crit_level_allowed)" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

require_root () {
    explanation="${1:-Need to run as root}"
    ID=$(id|cut -d" " -f1|cut -d= -f2|cut -d\( -f1)
    if [ "x$ID" == "x0" ] ; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_root" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
}

get_largest_partition () {
    echo $(df |grep -v -i available | awk '{print $4, $1, $6}'| sort -t" " -k 1 -n|tail -1|cut -d" " -f3)
}

get_largest_user_tempdir () {
    _BTU_LARGESTPARTITION=$(get_largest_partition)
    _BTU_TEMP=${_BTU_LARGESTPARTITION:-${TEMP:-/tmp}}
    _BTU_LARGETEMP=$(mktemp -q -d --tmpdir=$_BTU_TEMP)
    if [ ! -w "$_BTU_LARGETEMP" ] ; then
        _BTU_LARGETEMP=$(sudo mktemp -q -d --tmpdir=$_BTU_TEMP)
        sudo chown $USER "$_BTU_LARGETEMP"
    fi
    echo "$_BTU_LARGETEMP"
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

# checks whether MSRs could be read from userspace
# will try to load the appropriate kernel module if not already done
# will return an error if the file is not readable (not root)
has_msr_access() (
    cpu=${1:-0}
    if [ ! -e /dev/cpu/$cpu/msr ] ; then
        has_program modprobe || return 1
        modprobe msr || return 1
    fi
    [ -r /dev/cpu/$cpu/msr ]
)

# reads a MSR via the /dev/cpu/<n>/msr device
# expects the MSR number (in hex) as the first parameter and optionally the
# CPU number from which to read as the second argument (defaults to 0)
# outputs a 16 char hex value (lower case letters) to stdout
# returns 0 on success, 1 for an invalid MSR and 2 for permission issues
read_msr() (
    cpu=${2:-0}
    if has_program rdmsr ; then
        rdmsr -x -0 -p $cpu "$1" 2> /dev/null
        return $?
    fi
    [ -r /dev/cpu/$cpu/msr ] || return 2

    perl -e 'my $msr;sysseek(STDIN,hex($ARGV[0]),0);sysread(STDIN,$msr,8) or exit(1);my @words=unpack("LL",$msr);printf("%08x%08x\n",$words[1],$words[0]);' $1 < /dev/cpu/$cpu/msr
)

# writes a MSR via the /dev/cpu/<n>/msr device
# expects the MSR number (in hex) as the first parameter, the value (in hex)
# is the second one. Optionally the CPU number to use for the write can be
# given as the third argument (defaults to 0)
# returns 0 on success, 1 for an invalid MSR and 2 for permission issues
write_msr() (
    [ $# -lt 2 ] && return 3
    cpu=${3:-0}
    if has_program wrmsr ; then
        wrmsr -p $cpu "$1" "$2" 2> /dev/null
        return $?
    fi
    [ -w /dev/cpu/$cpu/msr ] || return 2
    low=$(printf "0x%x" $(($2 & (2**32 - 1))))
    high=$(printf "0x%x" $((($2 >> 32) & (2**32 - 1))))
    perl -e 'my $value=pack("LL",hex($ARGV[1]),hex($ARGV[2]));sysseek(STDOUT,hex($ARGV[0]),0);syswrite(STDOUT,$value,8) or exit(1);' $1 $low $high > /dev/cpu/$cpu/msr
)

# Reads an entire cpuid register
# Usage: get_cpuid_register <leafnr_in_hex> e[abcd]x
# Example: get_cpuid_register 0x80000001 ecx
# Outputs the decimal register value to stdout
# Returns 0 for success, 1 for invalid cpuid leaf, 2 for permission
get_cpuid_register () {
    [ $# -lt 2 ] && return 3
    cpu=${3:-0}

    # try to load the cpuid module if not already done
    [ -c /dev/cpu/$cpu/cpuid ] || modprobe cpuid > /dev/null 2>&1
    [ -r /dev/cpu/$cpu/cpuid ] || return 2

    perl -e 'my $leaf;sysseek(STDIN, hex($ARGV[0]),0);sysread(STDIN,$leaf,16) or exit(1);my @regs=unpack("LLLL",$leaf);printf("%u\n",$regs[ord(substr($ARGV[1],1,1))-ord("a")]);' $1 $2 < /dev/cpu/$cpu/cpuid
}

# Reads a cpuid register and filters a certain bit
# Usage: get_cpuid_bit <leafnr_in_hex> e[abcd]x <bitnr>
# Example: get_cpuid_bit 0x80000001 ecx 2
# Outputs either 0 or 1 to stdout
# Returns 0 for success, 1 for invalid cpuid leaf, 2 for permission
get_cpuid_bit () {
    [ $# -lt 3 ] && return 3
    cpu=${4:-0}
    reg=$(get_cpuid_register $1 $2 $4) || return $?

    echo $(($reg >> $3 & 1))
}

# Get a space separated list of CPUs from a sysfs cpumap file
# Example:
#   get_cpus_from_cpumap /sys/devices/system/node/node0/cpumap
#   0 1 2 3
# Notes:
#   Result may be an empty string
#   Result may be -1 in case of parsing errors
get_cpus_from_cpumap () {
    cpumap="${1}"
    cpus=""
    wordcnt=$(cat $cpumap | sed -e 's/,/ /g' | wc -w)

    if [ $wordcnt -eq 0 ]; then
        echo -1
        return
    fi

    for i in $(seq $wordcnt -1 1); do
        offset=$(($wordcnt - $i))
        word=$((0x$(cat $cpumap | cut -d , -f $i)))
        if [ $? -ne 0 ]; then cpus=-1; break; fi
        for j in $(seq 0 31); do
            if [ $(($word >> $j & 1 )) -eq 1 ]; then
                cpus="$cpus $((32 * $offset + $j))"
            fi
        done
    done

    echo $cpus
}

# Get a space separated list of CPUs from a sysfs cpulist file
# Example:
#   get_cpus_from_cpulist /sys/devices/system/cpu/online
#   0 1 2 3
# Notes:
#   Result may be an empty string
#   Result may be -1 in case of parsing errors
get_cpus_from_cpulist () {
    cpulist="${1}"
    cpus=""
    ranges=$(cat $cpulist | sed -e 's/,/ /g')

    if [ -z "$ranges" ]; then
        echo -1
        return
    fi

    for range in $ranges; do
        if echo $range | grep -q '^[0-9]\+-[0-9]\+$'; then
            min=$(echo $range | sed 's/-[0-9]\+$//')
            max=$(echo $range | sed 's/^[0-9]\+-//')
            if [ $min -ge $max ]; then cpus=-1; break; fi
            for cpu in $(seq $min $max); do cpus="$cpus $cpu"; done
        elif echo $range | grep -q '^[0-9]\+$'; then
            cpus="$cpus $range"
        else
            cpus=-1; break
        fi
    done

    echo $cpus
}

autoreport_skip_all () {
    explanation="${1:-'no explanation'}"
    SKIPALL="1..0 # skip $explanation"
    NOUPLOAD=1
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

get_benchmarkdata_counter () {
     echo ${#BENCHMARKDATA[@]}
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

append_benchmarkdata () {
    [ -z "$1" ] && return $_FAILURE
    have_NAME=0
    have_VALUE=0
    have_undef_key=0
    have_undef_value=0
    for kv in "$@" ; do
        k=$(cut -d: -f1  <<<$kv)
        v=$(cut -d: -f2- <<<$kv)
        if [ "$k" == "NAME"  ] ; then have_NAME=1  ; fi
        if [ "$k" == "VALUE" ] ; then have_VALUE=1 ; fi
        if [ -z "$k" ] ; then have_undef_key=1   ; fi
        if [ -z "$v" ] ; then have_undef_value=1 ; fi
    done

    if [ "x$have_NAME" == "x0" -o "x$have_VALUE" == "x0" -o "x$have_undef_key" == "x1" -o "x$have_undef_value" == "x1" ] ; then
        diag "Error in benchmarkdata:" $(for kv in "$@" ; do echo "'$kv'" ; done)
        if [ "x$have_NAME"        == "x0" ] ; then diag ".  missing key 'NAME'" ; fi
        if [ "x$have_VALUE"       == "x0" ] ; then diag ".  missing key 'VALUE'" ; fi
        if [ "x$have_undef_key"   == "x1" ] ; then diag ".  contains undefined keys" ; fi
        if [ "x$have_undef_value" == "x1" ] ; then diag ".  contains undefined values" ; fi
        return $_FAILURE
    fi

    BENCHMARKDATA=( "${BENCHMARKDATA[@]}" "-" )
    for kv in "$@" ; do
        k=$(cut -d: -f1  <<<$kv)
        v=$(cut -d: -f2- <<<$kv)
        BENCHMARKDATA=( "${BENCHMARKDATA[@]}" "  $k: '$v'" )
    done
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
    done < "$0"
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

has_kernel_release_min () {
    _ta_autoreport_v="${1:-0}"
    version_number_compare $(get_kernel_release) -gt $_ta_autoreport_v
}

require_kernel_release_min () {
    release_req="${1:-}"
    explanation="${2:-Linux Kernel must be newer than ${release_req}}"
    if has_kernel_release_min "$release_req"; then
        if [ "x1" = "x$REQUIRES_GENERATE_TAP" ] ; then ok $_SUCCESS "require_kernel_release_min $release_req" ; fi
        return $_SUCCESS
    else
        autoreport_skip_all "$explanation"
    fi
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
    cpuinfo=$(
        if arm_cpu
        then
            cpu=$(grep 'Processor' < /proc/cpuinfo | cut -d: -f2- |head -1 | cut -d" " -f2);
        else
            cpu=$(grep 'model name' < /proc/cpuinfo | cut -d: -f2- | head -1 | sed -e "s/^ *//");
        fi
        echo "$(get_number_cpus) cores [$cpu]";
    )
    # TODO: bogomips from /proc/cpuinfo

    if [ -e "/boot/config-$kernelrelease" ]
    then
    BOOTCONFIG="/boot/config-$kernelrelease"
    else
    BOOTCONFIG=
    fi
    PROCCONFIG="/proc/config.gz"

    ticketurl=${TICKETURL:-""}
    wikiurl=${WIKIURL:-""}
    planningid=${PLANNINGID:-""}
    moreinfourl=${MOREINFOURL:-""}

    run_hook "prepare_information"
} # prepare_information()

suite_meta () {
    if [[ -n $VERBOSE ]]; then
        echo "# Test-section: $suite_name";
        echo "# Test-suite-version: $suite_version";
    fi
    echo "# Test-suite-name: $suite_name";
    echo "# Test-machine-name: $hostname";

    if [ -n "$ticketurl" ] ; then
        echo "# Test-ticket-url:               $ticketurl";
    fi
    if [ -n "$wikiurl" ] ; then
        echo "# Test-wiki-url:                 $wikiurl";
    fi
    if [ -n "$planningid" ] ; then
        echo "# Test-planning-id:              $planningid";
    fi
    if [ -n "$moreinfourl" ] ; then
        echo "# Test-moreinfo-url:             $moreinfourl";
    fi

    run_hook "suite_meta"
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

# we could as well use uname -r here, but lets explicitly ask Xen
# first what it thinks the Dom0 kernel version is
ltu_xen_dom0_kernel () {
    XL=$(get_xen_tool)
    if [ "$?" -eq 0 ] ; then
        $XL info 2> /dev/null | grep '^release.*:' | cut -d: -f2 || uname -r
    else
        uname -r
    fi
}

ltu_xen_changeset () {
    if [ -r /sys/hypervisor/properties/changeset ] ; then
        cat /sys/hypervisor/properties/changeset | sed -e 's/^.* \([^ ]*\)/\1/'
    else
        XL=$(get_xen_tool) || return $_FAILURE
        echo $($XL info|grep '^xen_changeset.*:'|sed -e 's/^.* \([^ ]*\)/\1/')
    fi
}

ltu_xen_version () {
    if [ -r /sys/hypervisor/version/major ] ; then
        _VPATH="/sys/hypervisor/version"
        echo "$(cat $_VPATH/major).$(cat $_VPATH/minor)$(cat $_VPATH/extra)"
    else
        XL=$(get_xen_tool) || return $_FAILURE
        XEN_VERSION_MAJOR=$(echo $($XL info|grep '^xen_major.*:'|cut -d: -f2))
        XEN_VERSION_MINOR=$(echo $($XL info|grep '^xen_minor.*:'|cut -d: -f2))
        XEN_VERSION_EXTRA=$(echo $($XL info|grep '^xen_extra.*:'|cut -d: -f2))
        XEN_VERSION=""
        if [ -n "$XEN_VERSION_MAJOR" ] ; then
            XEN_VERSION="$XEN_VERSION_MAJOR.$XEN_VERSION_MINOR$XEN_VERSION_EXTRA"
        fi
        echo $XEN_VERSION
    fi
}

ltu_xen_meta () {
    echo "# Test-xen-dom0-kernel: $(ltu_xen_dom0_kernel)"
    echo "# Test-xen-version: $(ltu_xen_version)"
    echo "# Test-xen-changeset: $(ltu_xen_changeset)"
    echo "# Test-xen-base-os-description: $(ltu_base_os_description)"
}

ltu_kvm_meta () {
    echo "# Test-kvm-version: $(uname -r)"
    echo "# Test-kvm-base-os-description: $(ltu_base_os_description)"
}

ltu_section_meta () {
    if [ ! "x1" = "x$DONTREPEATMETA" ] ; then
        echo "# Test-uname: $uname"
        echo "# Test-osname: $osname"
        echo "# Test-kernel: $kernelrelease"
        echo "# Test-changeset: $changeset"
        echo "# Test-flags: $kernelflags"
        echo "# Test-cpuinfo: $cpuinfo"
        echo "# Test-ram: $ram"
        echo "# Test-starttime-test-program: $starttime_test_program"
        echo "# Test-endtime-test-program: $endtime_test_program"
        if is_running_in_xen_dom0 ; then
            ltu_xen_meta
        fi
        if is_running_in_kvm_host ; then
            ltu_kvm_meta
        fi
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
    MYPLAN=3   # initialize with count of default entries
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

    # ==================== additional benchmark data ====================
    echo "ok - benchmarkdata"
    BENCHMARKDATACOUNT=${#BENCHMARKDATA[@]}
    if [ "$BENCHMARKDATACOUNT" -gt 0 ] ; then
        echo "  ---"
        echo "  BenchmarkAnythingData:"
        if [ "$BENCHMARKDATACOUNT" -gt 0 ] ; then
            for l in $(seq 0 $(($BENCHMARKDATACOUNT - 1))) ; do
                echo "    ${BENCHMARKDATA[l]}"
            done
        fi
        echo "  ..."
    fi

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

done_testing_to_file () {
    prepare_start "${@}"

    _LTU_MYTMP=$(mktemp -d)
    _LTU_COPY_TMP=$(mktemp -d --tmpdir "SPECIALFILES.XXX")

    MYTAPFILE="$_LTU_MYTMP/$_TAPFILE"
    MYUPLOADSFILE="$_LTU_MYTMP/$_UPLOADSFILE"

    autoreport_main > $MYTAPFILE

    # ==================== files ====================
    # paranoid whitespace-aware tar
    if [ $_LTU_FILECOUNT -gt 0 ] ; then
        eval tar -P -czf "'$MYUPLOADSFILE'" $(
            for f in $(seq 0 $(($_LTU_FILECOUNT - 1))) ; do
                _LTU_FILE="${_LTU_FILES[f]}"
                if [ -e "$_LTU_FILE" ] ; then
                    # handle /proc and /sys files by reading their content into intermediate file
                    if echo $_LTU_FILE | grep -qE '^\/(proc|sys)\/' > /dev/null 2>&1 ; then
                        _LTU_FILE_COPY="$_LTU_COPY_TMP/$(echo $_LTU_FILE | sed -e 's/\W/_/g')"
                        cat $_LTU_FILE > "$_LTU_FILE_COPY" 2>&1
                        _LTU_FILE="$_LTU_FILE_COPY"
                    fi
                    echo "# Upload file: '$_LTU_FILE'" >> $MYTAPFILE
                    echo "'$_LTU_FILE'"
                else
                    echo "# Ignore file: '$_LTU_FILE' (not existing)" >> $MYTAPFILE
                fi
            done
        )
    fi

    _MAYBE_UPLOADSFILE="$_UPLOADSFILE"
    if [ ! -e $MYUPLOADSFILE ] ; then
        _MAYBE_UPLOADSFILE=""
    fi
    tar -C $_LTU_MYTMP -czf "$TESTRESULTSFILE" "$_TAPFILE" $_MAYBE_UPLOADSFILE

    rm -fr "$_LTU_MYTMP"
    rm -fr "$_LTU_COPY_TMP"
}

done_testing () {
    cd $_LTU_ORIGINAL_STARTDIR

    if [ "x$CREATE_RESULTS_FILE" = "x1" ] ; then
        done_testing_to_file "${@}"
    else
        done_testing_to_stdout "${@}"
    fi

    if [ "x$PROVIDE_EXITCODE" = "x1" ] ; then
        return $_LTU_EXITCODE
    fi
}

run_hook "functions"

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
