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

# (re-)load SUT
bsl_load_lib 'bsl_file' 1

setup() {
    :
}

##############################################################################
# bsl_dirname()
##############################################################################
@test "bsl_dirname: /foo/bar" {
    run -0 bsl_dirname /foo/bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '/foo'
}

@test "bsl_dirname: foo/bar" {
    run -0 bsl_dirname foo/bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'foo'
}

@test "bsl_dirname: foo/" {
    run -0 bsl_dirname foo/
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'foo'
}

@test "bsl_dirname: foo" {
    run -0 bsl_dirname foo
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.'
}

@test "bsl_dirname: <empty>" {
    run -0 bsl_dirname
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.'
}

##############################################################################
# bsl_basename()
##############################################################################
@test "bsl_basename: /foo/bar.baz" {
    run -0 bsl_basename /foo/bar.baz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.baz'
}

@test "bsl_basename: /foo/bar.baz/" {
    run -0 bsl_basename /foo/bar.baz/
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.baz'
}

@test "bsl_basename: /foo/bar.baz .baz" {
    run -0 bsl_basename /foo/bar.baz .baz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar'
}

@test "bsl_basename: /foo/bar.baz baz" {
    run -0 bsl_basename /foo/bar.baz baz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.'
}

@test "bsl_basename: /foo/bar.baz buz" {
    run -0 bsl_basename /foo/bar.baz buz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.baz'
}

@test "bsl_basename: /foo/bar.baz bar" {
    run -0 bsl_basename /foo/bar.baz bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.baz'
}

@test "bsl_basename: /foo/bar.baz ''" {
    run -0 bsl_basename /foo/bar.baz ''
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar.baz'
}

@test "bsl_basename: foo/bar" {
    run -0 bsl_basename foo/bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar'
}

@test "bsl_basename: bar" {
    run -0 bsl_basename bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar'
}

@test "bsl_basename: <empty>" {
    run -0 bsl_basename
    assert [ "${#lines[*]}" -eq 0 ]
    refute_output
}

##############################################################################
# bsl_getext()
##############################################################################

@test "bsl_getext: /foo/bar.baz" {
    run -0 bsl_getext /foo/bar.baz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.baz'
}

@test "bsl_getext: /foo/bar.baz/" {
    run -0 bsl_getext /foo/bar.baz/
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.baz'
}

@test "bsl_getext: /foo/bar." {
    run -0 bsl_getext /foo/bar.
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.'
}

@test "bsl_getext: ." {
    run -0 bsl_getext .
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '.'
}

@test "bsl_getext: /foo/bar" {
    run -0 --keep-empty-lines bsl_getext /foo/bar
    assert [ "${#lines[*]}" -eq 0 ]
    refute_output
}

@test "bsl_getext: bar" {
    run -0 --keep-empty-lines bsl_getext bar
    assert [ "${#lines[*]}" -eq 0 ]
    refute_output
}

@test "bsl_getext: <empty>" {
    run -0 --keep-empty-lines bsl_getext
    assert [ "${#lines[*]}" -eq 0 ]
    refute_output
}

##############################################################################
# bsl_stripext()
##############################################################################

@test "bsl_stripext: /foo/bar.baz" {
    run -0 bsl_stripext /foo/bar.baz
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '/foo/bar'
}

@test "bsl_stripext: /foo/bar." {
    run -0 bsl_stripext /foo/bar.
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '/foo/bar'
}

@test "bsl_stripext: /foo/bar" {
    run -0 bsl_stripext /foo/bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output '/foo/bar'
}

@test "bsl_stripext: bar" {
    run -0 bsl_stripext bar
    assert [ "${#lines[*]}" -eq 1 ]
    assert_output 'bar'
}

@test "bsl_stripext: <empty>" {
    run -0 bsl_stripext
    assert [ "${#lines[*]}" -eq 0 ]
    refute_output
}
