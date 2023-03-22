#Dd Utility variables/functions for BSL BATS tests.

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

: # keep following shellcheck directive from having file-wide scope
# shellcheck disable=SC2154
[ -v REPO_ROOT ] || REPO_ROOT="$(realpath "${BATS_TEST_DIRNAME}/..")"
[ -v BSLBATS_BASE_DIR ] || BSLBATS_BASE_DIR="${REPO_ROOT}/.bats"
[ -v _SUPPORT_DIR ] || _SUPPORT_DIR="${BSLBATS_BASE_DIR}/bats-support"
[ -v _ASSERT_DIR ] || _ASSERT_DIR="${BSLBATS_BASE_DIR}/bats-assert"

# shellcheck source=../src/init.bash
source "${REPO_ROOT}/src/init.bash"

# shellcheck source=../.bats/bats-support/load.bash
source "${_SUPPORT_DIR}/load.bash"
# shellcheck source=../.bats/bats-assert/load.bash
source "${_ASSERT_DIR}/load.bash"

bats_require_minimum_version 1.9.0

bslbats_logi() {
    msg="${*:+ ${*}}"
    printf >&3 -- '# [INF]%s\n' "${msg}"
}

bslbats_logd() {
    if [ "${BSLBATS_DEBUG:-0}" -gt 0 ]; then
        msg="${*:+ ${*}}"
        printf >&3 -- '# [DBG]%s\n' "${msg}"
    fi
}

bslbats_mkfdir() {
    local d
    for d in "${@}"; do
        # shellcheck disable=SC2154
        mkdir -p "${BATS_FILE_TMPDIR}/${d}"
    done
}

bslbats_prfdir() {
    local d result
    for d in "${@}"; do
        if [ "${d:0:1}" = '/' ]; then
            result="${result}:${d}"
        else
            result="${result}:${BATS_FILE_TMPDIR:-/tmp}/${d}"
        fi
    done
    echo "${result:1}"
}
