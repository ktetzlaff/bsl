#!/usr/bin/env bats

#L#
# Copyright (C) 2022 ktetzlaff <bsl@tetzco.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#l#

# allow to find test_helper.bash
PATH="${BATS_TEST_DIRNAME:-.}:${PATH}"
source test_helper.bash

# SUT
unset _BSL_PATH
source bsl_path.bash

REFPATH="$(bslbats_prfdir usr/{bin,sbin} {bin,sbin})"
declare -r REFPATH

setup_file() {
    # create directories which can be used in bsl_path_add tests, use
    # ${BATS_FILE_TMPDIR} as base dir
    bslbats_mkfdir {bin,sbin} usr/{bin,sbin} bin{1,2,3}
}

setup() {
    # path variable which can be used in tests
    TESTPATH="${REFPATH}"
    export TESTPATH
}

teardown() {
    unset TESTPATH
}

teardown_file() {
    :
    # files/directories created in ${BATS_FILE_TMPDIR} are removed
    # automatically
}

##############################################################################
# _bsl_path_usage()
##############################################################################
@test "_bsl_path_usage" {
    run -0 --separate-stderr _bsl_path_usage
    assert_output ''
    # shellcheck disable=SC2154
    output="${stderr}"
    assert_output
    bslbats_logi "REFPATH='${REFPATH}'"
}

@test "_bsl_path_usage clean" {
    run -0 --separate-stderr _bsl_path_usage clean
    assert_output ''
    output="${stderr}"
    assert_output
}

@test "_bsl_path_usage ls" {
    run -0 --separate-stderr _bsl_path_usage ls
    assert_output ''
    output="${stderr}"
    assert_output
}

##############################################################################
# _bsl_path_argparse()
##############################################################################
@test "_bsl_path_argparse" {
    declare -A opt=(
        ['varname']='invalid'
    )
    declare -a paths=('test')
    run -0 _bsl_path_argparse
}

@test "_bsl_path_argparse remove with invalid arg" {
    declare -A opt=(
        ['varname']='invalid'
    )
    declare -a paths=('test')
    _bsl_path_argparse remove opt paths --prepend '/usr/local/bin' || status="${?}"
    assert [ "${status}" -eq 1 ]
    assert [ "${#paths[*]}" -eq 0 ]
    assert [ "${#opt[*]}" -eq 0 ]
}

@test "_bsl_path_argparse add with args" {
    declare -A opt=(
        ['varname']='invalid'
    )
    declare -a paths=('test')
    _bsl_path_argparse add opt paths -v -v \
        --varname TESTPATH --prepend --replace --printval \
        '/usr/bin' --path '/bin'
    status="${?}"
    if [ "${BSLBATS_DEBUG:-0}" -gt 0 ]; then
        bslbats_logi "status='${status}'"
        for i in "${!paths[@]}"; do
            bslbats_logi "[${i}]='${paths[${i}]}'"
        done
        for k in "${!opt[@]}"; do
            bslbats_logi "['${k}']='${opt[${k}]}'"
        done
    fi
    assert [ "${status}" -eq 0 ]
    assert [ "${#paths[*]}" -eq 2 ]
    assert [ "${paths[0]}" = '/usr/bin' ]
    assert [ "${paths[1]}" = '/bin' ]
    assert [ "${#opt[*]}" -eq 5 ]
    assert [ "${opt['verbose']}" -eq 2 ]
    assert [ "${opt['varname']}" = 'TESTPATH' ]
    assert [ "${opt['position']}" -eq 0 ]
    assert [ "${opt['replace']}" -eq 1 ]
    assert [ "${opt['printval']}" -eq 1 ]
}

@test "_bsl_path_argparse remove with args" {
    declare -A opt=(
        ['varname']='invalid'
    )
    declare -a paths=('test')
    _bsl_path_argparse remove opt paths --dry-run '/usr/local/bin' || status="${?}"
    if [ "${BSL_BATS_DEBUG:-0}" -gt 0 ]; then
        bslbats_logi "status='${status}'"
        for i in "${!paths[@]}"; do
            bslbats_logi "[${i}]='${paths[${p}]}'"
        done
        for k in "${!opt[@]}"; do
            bslbats_logi "['${k}']='${opt[${k}]}'"
        done
    fi
    assert [ "${status:-0}" -eq 0 ]
    assert [ "${#paths[*]}" -eq 1 ]
    assert [ "${paths[0]}" = '/usr/local/bin' ]
    assert [ "${#opt[*]}" -eq 3 ]
    assert [ "${opt['verbose']}" -eq 0 ]
    assert [ "${opt['varname']}" = 'PATH' ]
    assert [ "${opt['dryrun']}" -eq 1 ]
}

##############################################################################
# bsl_path_canonicalize()
##############################################################################
@test "bsl_path_canonicalize fail/1 (without args)" {
    run -1 bsl_path_canonicalize
    assert_output ''
}

@test "bsl_path_canonicalize fail/1 ('')" {
    run -1 bsl_path_canonicalize ''
    assert_output ''
}

@test "bsl_path_canonicalize fail/2 (' ')" {
    run -2 bsl_path_canonicalize ' '
    assert_output ''
}

@test "bsl_path_canonicalize fail/2 (' /bin')" {
    run -2 bsl_path_canonicalize ' /bin'
    assert_output ''
}

@test "bsl_path_canonicalize fail/3 ('/etc/passwd')" {
    run -3 bsl_path_canonicalize '/etc/passwd'
    assert_output ''
}

@test "bsl_path_canonicalize fail/3 ('/bin/unlikely to exist')" {
    run -3 bsl_path_canonicalize '/bin/unlikely to exist'
    assert_output ''
}

@test "bsl_path_canonicalize fail/4 ('/etc/ssl/private')" {
    [[ -d '/etc/ssl/private' || -r '/etc/ssl/private' ]] || skip
    run -4 bsl_path_canonicalize '/etc/ssl/private'
    assert_output ''
}

@test "bsl_path_canonicalize ok ('/bin')" {
    run -0 bsl_path_canonicalize '/bin'
    assert_output '/bin'
}

@test "bsl_path_canonicalize ok (special case: leaading '//')" {
    run -0 bsl_path_canonicalize '//bin'
    assert_output '/bin'
}

@test "bsl_path_canonicalize ok ('///bin')" {
    run -0 bsl_path_canonicalize '///bin'
    assert_output '/bin'
}

@test "bsl_path_canonicalize ok ('/.//usr///bin//')" {
    run -0 bsl_path_canonicalize '/.//usr///bin//'
    assert_output '/usr/bin'
}

@test "bsl_path_canonicalize ok ('/bin//./')" {
    run -0 bsl_path_canonicalize '/bin//./'
    assert_output '/bin'
}

##############################################################################
# bsl_path_ls()
##############################################################################
@test "bsl_path_ls, local PATH" {
    PATH='/usr/bin:/usr/sbin' run -0 bsl_path_ls
    assert [ "${#lines[*]}" -eq 2 ]
    assert_line -n 0 '/usr/bin'
    assert_line -n 1 '/usr/sbin'
}

@test "bsl_path_ls, TESTPATH" {
    run -0 bsl_path_ls TESTPATH
    assert [ "${#lines[*]}" -eq 4 ]
    assert_line -n 0 "$(bslbats_prfdir usr/bin)"
    assert_line -n 3 "$(bslbats_prfdir sbin)"
}


@test "bsl_path_ls, --varname TESTPATH" {
    run -0 bsl_path_ls --varname TESTPATH
    assert [ "${#lines[*]}" -eq 4 ]
    assert_line -n 0 "$(bslbats_prfdir usr/bin)"
    assert_line -n 3 "$(bslbats_prfdir sbin)"
}

##############################################################################
# bsl_path_clean()
##############################################################################
@test "bsl_path_clean '/bin:/bin'" {
    unset status
    TESTPATH='/bin:/bin'
    bsl_path_clean --varname TESTPATH || status="${?}"
    assert [ -z "${status:-}" ]
    assert [ "${TESTPATH}" = '/bin' ]
}

@test "bsl_path_clean '/bin:/bin//:////bin//////:/usr/bin/does not exist/..::'" {
    unset status
    TESTPATH='/bin:/bin//:////bin//////:/usr/bin/does not exist/..::'
    bsl_path_clean --varname TESTPATH || status="${?}"
    assert [ -z "${status:-}" ]
    assert [ "${TESTPATH}" = '/bin' ]
}

@test "bsl_path_clean '::/bin:/sbin:::./:../some-rel-path::/does not exist'" {
    unset status
    # shellcheck disable=SC2030
    TESTPATH='::/bin:/sbin:::./:../some-rel-path::/does not exist'
    bsl_path_clean --varname TESTPATH || status="${?}"
    assert [ -z "${status:-}" ]
    assert [ "${TESTPATH}" = '/bin:/sbin' ]
}

##############################################################################
# bsl_path_add()
##############################################################################
@test "bsl_path_add without ADDPATH" {
    run -10 --separate-stderr bsl_path_add --varname TESTPATH
    assert_output ''
    output="${stderr}"
    assert_output --partial "missing ADDPATH"
}

@test "bsl_path_add '$(bslbats_prfdir bin1)'" {
    unset status
    bsl_path_add --varname TESTPATH "$(bslbats_prfdir bin1)" || status="${?}"
    assert [ -z "${status:-}" ]
    # shellcheck disable=SC2031
    assert [ "${TESTPATH}" = "${REFPATH}:$(bslbats_prfdir bin1)" ]
}

@test "bsl_path_add --printval '/bin1'" {
    run -0 bsl_path_add --printval --varname TESTPATH "$(bslbats_prfdir bin1)"
    assert_output "${REFPATH}:$(bslbats_prfdir bin1)"
}

@test "bsl_path_add '/bin1' '/bin2'" {
    run -0 bsl_path_add --printval --varname TESTPATH \
        "$(bslbats_prfdir bin1)" "$(bslbats_prfdir bin2)"
    assert_output "${REFPATH}:$(bslbats_prfdir bin{1,2})"
}

@test "bsl_path_add -p '/bin1' 'bin2'" {
    run -0 bsl_path_add --printval -p --varname TESTPATH \
        "$(bslbats_prfdir bin1)" "$(bslbats_prfdir bin2)"
    assert_output "$(bslbats_prfdir bin{1,2}):${REFPATH}"
}

@test "bsl_path_add -p '/bin1:/bin2'" {
    run -0 bsl_path_add --printval -p --varname TESTPATH \
        "$(bslbats_prfdir bin{1,2})"
    assert_output "$(bslbats_prfdir bin{1,2}):${REFPATH}"
}

@test "bsl_path_add -p '/bin1:/bin3:/bin2:/bin4', bin4 invalid" {
    run -0 bsl_path_add --printval -p --varname TESTPATH \
        "$(bslbats_prfdir bin{1,3,2,4})"
    assert_output "$(bslbats_prfdir bin{1,3,2}):${REFPATH}"
}

##############################################################################
# bsl_path_remove()
##############################################################################
@test "bsl_path_remove -p '/usr/bin'" {
    TESTPATH="$(bslbats_prfdir /usr/{bin,sbin} /{bin,sbin})"
    run -0 bsl_path_remove --printval --varname TESTPATH '/usr/bin'
    assert_output '/usr/sbin:/bin:/sbin'
}

@test "bsl_path_remove (single '/usr/bin')" {
    unset status
    TESTPATH="$(bslbats_prfdir /usr/{bin,sbin} /{bin,sbin})"
    bsl_path_remove --varname TESTPATH '/usr/bin' || status="${?}"
    assert [ -z "${status:-}" ]
    assert [ "${TESTPATH}" = '/usr/sbin:/bin:/sbin' ]
}

@test "bsl_path_remove, duplicate '/usr/bin', trailing ':'" {
    unset status
    TESTPATH="$(bslbats_prfdir /usr/{bin,sbin} /sbin /usr/{bin,local/sbin,bin}):"
    bsl_path_remove --varname TESTPATH '/usr/bin' || status="${?}"
    assert [ -z "${status:-}" ]
    assert [ "${TESTPATH}" = '/usr/sbin:/sbin:/usr/local/sbin:' ]
}
