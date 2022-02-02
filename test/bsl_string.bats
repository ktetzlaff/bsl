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
unset _BSL_STRING
source bsl_string.bash

setup() {
    :
}

##############################################################################
# bsl_rtrim()/bsl_ltrim()/bsl_trim()
##############################################################################
@test "bsl_rtrim without -s" {
    run -0 -- bsl_rtrim "  hello  "
    assert_output '  hello'
}

@test "bsl_ltrim without -s" {
    run -0 -- bsl_ltrim "  hello  "
    assert_output 'hello  '
}


@test "bsl_trim without -s" {
    run -0 -- bsl_trim "  hello  "
    assert_output 'hello'
}

@test "bsl_rtrim with -s :" {
    run -0 -- bsl_rtrim -s : "::<hello>::"
    # >&3 echo "output='${output}'"
    assert_output '::<hello>'
}

@test "bsl_ltrim with -s :" {
    run -0 -- bsl_ltrim -s : "::<hello>::"
    # >&3 echo "output='${output}'"
    assert_output '<hello>::'
}

@test "bsl_trim with -s :" {
    run -0 -- bsl_trim -s : "::<hello>::"
    # >&3 echo "output='${output}'"
    assert_output '<hello>'
}

##############################################################################
# bsl_join()
##############################################################################
@test "bsl_join without parameter" {
    run -0 bsl_join
    assert_output ''
}

@test "bsl_join with single parameter" {
    run -0 bsl_join '  '
    assert_output ''
}

@test "bsl_join with single string" {
    run -0 bsl_join ' ' "hello world!"
    assert_output 'hello world!'
}

@test "bsl_join with two strings" {
    run -0 bsl_join ' ' "hello" "world!"
    assert_output 'hello world!'
}

@test "bsl_join with multiple strings" {
    run -0 bsl_join ' ' "dark" "side of" " the " "moon"
    assert_output 'dark side of  the  moon'
}

@test "bsl_join with multiple strings, sep=:" {
    run -0 bsl_join : "dark" "side of" " the " "moon"
    assert_output 'dark:side of: the :moon'
}

@test "bsl_join with empty seperator" {
    run -0 bsl_join '' "dark" "side of" " the " "moon"
    assert_output 'darkside of the moon'
}

##############################################################################
# split()
##############################################################################
@test "bsl_split without parameter" {
    run -0 bsl_split
    assert [ "${#lines[*]}" -eq 0 ]
}

@test "bsl_split with single parameter" {
    run -0 bsl_split '  '
    assert [ "${#lines[*]}" -eq 0 ]
}
