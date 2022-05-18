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
bsl_load_lib 'bsl_misc' 1

setup() {
    :
}

##############################################################################
# bsl_stdin_to_log()
##############################################################################
@test "bsl_stdin_to_log" {
    skip
}

##############################################################################
# bsl_stdin_to_file()
##############################################################################
@test "bsl_stdin_to_file" {
    skip
}

##############################################################################
# bsl_has_cmd()
##############################################################################
@test "bsl_has_cmd" {
    skip
}

##############################################################################
# bsl_run_cmd()
##############################################################################
@test "bsl_run_cmd" {
    skip
}

##############################################################################
# bsl_run_cmd_logged()
##############################################################################
@test "bsl_run_cmd_logged" {
    skip
}

##############################################################################
# bsl_run_cmd_nostdout()
##############################################################################
@test "bsl_run_cmd_nostdout" {
    skip
}

##############################################################################
# bsl_run_cmd_nostderr()
##############################################################################
@test "bsl_run_cmd_nostderr" {
    skip
}

##############################################################################
# bsl_run_cmd_quiet()
##############################################################################
@test "bsl_run_cmd_quiet" {
    skip
}

##############################################################################
# bsl_with_shopt()
##############################################################################
@test "bsl_with_shopt" {
    skip
}

##############################################################################
# bsl_with_dir()
##############################################################################
@test "bsl_with_dir" {
    skip
}

##############################################################################
# bsl_create_backup_file()
##############################################################################
@test "bsl_create_backup_file" {
    skip
}

##############################################################################
# bsl_create_link()
##############################################################################
@test "bsl_create_link" {
    skip
}

##############################################################################
# bsl_update_file()
##############################################################################
@test "bsl_update_file" {
    skip
}

##############################################################################
# bsl_hostname()
##############################################################################
@test "bsl_hostname" {
    skip
}
