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

# avoid shellcheck warning: 'SC2154 stderr is referenced but not assigned.'
stderr=''

# SUT
unset _BSL_LOGGING
source bsl_logging.bash

setup() {
    BSL_LOGLEVEL="${BSL_LOGLEVEL_DEFAULT}"
}

##############################################################################
# bsl_loge()
##############################################################################
@test "check variable values" {
    assert_equal "${BSL_LOGLEVEL_DEFAULT}" 2
    assert_equal "${BSL_LOGLEVEL}" 2
    assert_equal "${BSLL_LEVEL2SNAME["${BSL_LOGLEVEL}"]}" INF
    assert_equal "${BSLL_NAME2LEVEL["INF"]}" 2
    assert_equal "${BSLL_NAME2LEVEL["INFO"]}" 2
    assert_equal "${BSLL_NAME2LEVEL["info"]}" 2
    assert_equal "${BSLL_LEVEL2LOGGER_PRIO["${BSL_LOGLEVEL}"]}" info
}

##############################################################################
# bsl_loge()
##############################################################################
@test "bsl_loge without args" {
    run -0 --keep-empty-lines --separate-stderr bsl_loge
    assert_output ''
    output="${stderr}"
    assert_output '[ERR]'
}

@test "bsl_loge with one arg" {
    run -0 --keep-empty-lines --separate-stderr bsl_loge "one arg"
    assert_output ''
    output="${stderr}"
    assert_output '[ERR] one arg'
}

@test "bsl_loge with multiple args" {
    run -0 --keep-empty-lines --separate-stderr bsl_loge "two" "args"
    assert_output ''
    output="${stderr}"
    assert_output '[ERR] two args'
}

##############################################################################
# bsl_logw()
##############################################################################
@test "bsl_logw without args" {
    run -0 --keep-empty-lines --separate-stderr bsl_logw
    assert_output ''
    output="${stderr}"
    assert_output '[WRN]'
}

@test "bsl_logw with one arg" {
    run -0 --keep-empty-lines --separate-stderr bsl_logw "one arg"
    assert_output ''
    output="${stderr}"
    assert_output '[WRN] one arg'
}

@test "bsl_logw with multiple args" {
    run -0 --keep-empty-lines --separate-stderr bsl_logw "two" "args"
    assert_output ''
    output="${stderr}"
    assert_output '[WRN] two args'
}

##############################################################################
# bsl_logi()
##############################################################################
@test "bsl_logi without args" {
    run -0 bsl_logi
    assert_output "[INF]"
}

@test "bsl_logi with one arg" {
    run -0 bsl_logi "one arg"
    assert_output '[INF] one arg'
}

@test "bsl_logi with multiple args" {
    run -0 bsl_logi "two" "args"
    assert_output '[INF] two args'
}

##############################################################################
# bsl_logd()
##############################################################################
@test "bsl_logd without args (BSL_LOGLEVEL unset)" {
    unset BSL_LOGLEVEL
    run -0 bsl_logd
    assert_output ''
}

@test "bsl_logd with one arg (BSL_LOGLEVEL unset)" {
    unset BSL_LOGLEVEL
    run -0 bsl_logd "one arg"
    assert_output ''
}

@test "bsl_logd with multiple args (BSL_LOGLEVEL unset)" {
    unset BSL_LOGLEVEL
    run -0 bsl_logd "two" "args"
    assert_output ''
}

@test "bsl_logd without args (BSL_LOGLEVEL=3)" {
    BSL_LOGLEVEL=3
    run -0 bsl_logd
    assert_output '[DBG]'
    unset BSL_LOGLEVEL
}

@test "bsl_logd with one arg (BSL_LOGLEVEL=3)" {
    BSL_LOGLEVEL=3
    run -0 bsl_logd "one arg"
    assert_output '[DBG] one arg'
    unset BSL_LOGLEVEL
}

@test "bsl_logd with multiple args (BSL_LOGLEVEL=4)" {
    BSL_LOGLEVEL=4
    run -0 bsl_logd "two" "args"
    assert_output '[DBG] two args'
    unset BSL_LOGLEVEL
}

@test "bsl_logd with multiple args (BSL_LOGLEVEL=)" {
    BSL_LOGLEVEL=
    run -0 bsl_logd "two" "args"
    assert_output ''
    unset BSL_LOGLEVEL
}

@test "bsl_logd with multiple args (BSL_LOGLEVEL='yes')" {
    # since BSL_LOGLEVEL has the integer attribute, the next line sets it to `0`
    BSL_LOGLEVEL='yes'
    assert_equal "${BSL_LOGLEVEL}" 0
    run -0 --separate-stderr bsl_logd "two" "args"
    assert_output ''
    output="${stderr}"
    assert_output ''
    unset BSL_LOGLEVEL
}

##############################################################################
# bsl_die()
##############################################################################
@test "bsl_die, single arg" {
    run -1 --separate-stderr bsl_die 'hello'
    assert_output ''
    output="${stderr}"
    assert_output '[ERR] hello'
}

@test "bsl_die, multiple args" {
    run -1 --separate-stderr bsl_die 'hello' 'world!'
    assert_output ''
    output="${stderr}"
    assert_output '[ERR] hello world!'
}
