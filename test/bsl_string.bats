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

# shellcheck disable=SC2016,SC2119

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
@test "bsl_rtrim: default sep, '  hello  '" {
    run -0 --keep-empty-lines -- bsl_rtrim '  hello  '
    assert_equal "${#lines[*]}" 1
    assert_output '  hello'
}

@test "bsl_ltrim: default sep, '  hello  '" {
    run -0 --keep-empty-lines -- bsl_ltrim '  hello  '
    assert_equal "${#lines[*]}" 1
    assert_output 'hello  '
}

@test "bsl_trim: default sep, '  hello  '" {
    run -0 --keep-empty-lines -- bsl_trim '  hello  '
    assert_equal "${#lines[*]}" 1
    assert_output 'hello'
}

@test "bsl_rtrim: sep=:, '::<hello>::'" {
    run -0 --keep-empty-lines -- bsl_rtrim -s : '::<hello>::'
    bslbats_logd "output='${output}'"
    assert_equal "${#lines[*]}" 1
    assert_output '::<hello>'
}

@test "bsl_ltrim: sep=:, '::<hello>::'" {
    run -0 --keep-empty-lines -- bsl_ltrim -s : '::<hello>::'
    bslbats_logd "output='${output}'"
    assert_equal "${#lines[*]}" 1
    assert_output '<hello>::'
}

@test "bsl_trim: sep=:, '::<hello>::'" {
    run -0 --keep-empty-lines -- bsl_trim -s : '::<hello>::'
    bslbats_logd "output='${output}'"
    assert_equal "${#lines[*]}" 1
    assert_output '<hello>'
}

##############################################################################
# bsl_join()
##############################################################################
@test "bsl_join: no args" {
    run -0 --keep-empty-lines bsl_join
    assert_equal "${#lines[*]}" 1
    assert_output ''
}

@test "bsl_join: sep='', no *args" {
    run -0 --keep-empty-lines bsl_join -s ''
    assert_equal "${#lines[*]}" 1
    assert_output ''
}

@test "bsl_join: default sep, 'a'" {
    run -0 --keep-empty-lines bsl_join 'a'
    assert_equal "${#lines[*]}" 1
    assert_output 'a'
}

@test "bsl_join: default sep, 'a' 'b'" {
    run -0 --keep-empty-lines bsl_join 'a' 'b'
    assert_equal "${#lines[*]}" 1
    assert_output 'ab'
}
@test "bsl_join: sep=' ', 'hello world!'" {
    run -0 --keep-empty-lines bsl_join -s' ' 'hello world!'
    assert_output 'hello world!'
}

@test "bsl_join: sep=' ', 'hello' 'world!'" {
    run -0 --keep-empty-lines bsl_join -s ' ' 'hello' 'world!'
    assert_output 'hello world!'
}

@test "bsl_join: sep=' ', multiple *args" {
    run -0 --keep-empty-lines bsl_join -s ' ' 'dark' 'side of' ' the ' 'moon'
    assert_output 'dark side of  the  moon'
}

@test "bsl_join: sep=:, multiple *args" {
    run -0 --keep-empty-lines bsl_join -s: 'dark' 'side of' ' the ' 'moon'
    assert_output 'dark:side of: the :moon'
}

@test "bsl_join: empty sep, multiple *args" {
    run -0 --keep-empty-lines bsl_join -s '' 'dark' 'side of' ' the ' 'moon'
    assert_output 'darkside of the moon'
}

@test "bsl_join: sep=', ', multiple *args" {
    run -0 --keep-empty-lines bsl_join -s ', ' 'dark' 'side of' ' the ' 'moon'
    assert_output 'dark, side of,  the , moon'
}

@test "bsl_join: sep='  ', no *args" {
    run -0 --keep-empty-lines bsl_join -s '  '
    assert_equal "${#lines[*]}" 1
    assert_output ''
}

@test "bsl_join: sep='  ', 'a' 'b'" {
    run -0 --keep-empty-lines bsl_join -s'  ' 'a' 'b'
    assert_output 'a  b'
}

##############################################################################
# split()
##############################################################################
@test "bsl_split: no args" {
    run --keep-empty-lines true
    bslbats_logd "output:'${output}'"
    bslbats_logd "lines[${#lines[*]}]:'${lines[*]}'"
    [ "${#lines[*]}" -eq 1 ]
    assert_output ''
}

@test "bsl_split: sep='  ', no *args" {
    run -0 --keep-empty-lines bsl_split -s'  '
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output ''
}

@test "bsl_split: default sep, 'hello world!'" {
    run -0 --keep-empty-lines bsl_split 'hello world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello world!'
}

@test "bsl_split: default sep, 'hello:world!'" {
    run -0 --keep-empty-lines bsl_split 'hello:world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello:world!'
}

@test "bsl_split: sep=:, 'hello:world!'" {
    run -0 --keep-empty-lines bsl_split -s: 'hello:world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello world!'
}

@test "bsl_split: sep=:, 'hello::world!'" {
    run -0 --keep-empty-lines bsl_split -s: 'hello::world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello world!'
}

@test "bsl_split: sep='::', 'hello::world!'" {
    run -0 --keep-empty-lines bsl_split -s '::' 'hello::world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello world!'
}

@test "bsl_split: sep=': ', 'hello::world!'" {
    run -0 --keep-empty-lines bsl_split -s ': ' 'hello::world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'hello world!'
}

@test "bsl_split: sep=': ', ':hello::world!'" {
    run -0 --keep-empty-lines bsl_split -s ': ' ':hello::world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output ' hello world!'
}

@test "bsl_split: sep=': ', ':hello:.:world!'" {
    run -0 --keep-empty-lines bsl_split -s ': ' ':hello:.:world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output ' hello . world!'
}

@test "bsl_split: sep=': ', ':hello: . :world!'" {
    run -0 --keep-empty-lines bsl_split -s ': ' ':hello: . :world!'
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output ' hello . world!'
}

##############################################################################
# bsl_reverse_lines()
##############################################################################
@test "bsl_reverse_lines: stdin, ''" {
    ec=0
    output="$(printf '' | bsl_reverse_lines)" || ec="${?}"
    assert_equal "${ec}" 0
    assert_equal "${output}" ''
    printf -v nl '\n'
    assert_equal "${nl}" $'\n'
    run -0 --keep-empty-lines
}

@test "bsl_reverse_lines: stdin, 'a'" {
    ec=0
    output="$(printf 'a' | bsl_reverse_lines)" || ec="${?}"
    assert_equal "${ec}" 0
    assert_output 'a'
}

@test "bsl_reverse_lines: stdin, 'Hello\nworld!'" {
    ec=0
    output="$(printf 'Hello\nworld!' | bsl_reverse_lines)" || ec="${?}"
    assert_equal "${ec}" 0
    printf 'world!Hello\n' | assert_output -
}

@test "bsl_reverse_lines: stdin, 'Hello\nworld!\n'" {
    ec=0
    output="$(printf 'Hello\nworld!\n' | bsl_reverse_lines)" || ec="${?}"
    assert_equal "${ec}" 0
    printf 'world!\nHello\n' | assert_output -
}
