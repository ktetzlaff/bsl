# String manipulation functions.

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

[ "${_BSL_STRING:-0}" -eq 1 ] && return 0 || _BSL_STRING=1
[ "${BSL_INC_DEBUG:=0}" -lt 1 ] || echo "sources: ${BASH_SOURCE[*]}"

##############################################
# string functions
##############################################

# Examples:
#
#   bsl_rtrim "  hello  " # -> '  hello'
#   bsl_ltrim "  hello  " # -> 'hello  '
#   bsl_trim  "  hello  " # -> 'hello'
#
#   bsl_trim -s ':'  "::hello::" # -> "hello"
#
bsl_rtrim() {
    local sep=' '
    if [ "${1}" = "-s" ]; then shift; sep="${1}"; shift; fi
    saved=$(shopt -p extglob)
    shopt -s extglob
    # shellcheck disable=SC2295
    echo "${*%%*(${sep})}"
    eval "${saved}"
}

bsl_ltrim() {
    local sep=' '
    if [ "${1}" = "-s" ]; then shift; sep="${1}"; shift; fi
    saved=$(shopt -p extglob)
    shopt -s extglob
    # shellcheck disable=SC2295
    echo "${@##*(${sep})}"
    eval "${saved}"
}

bsl_trim() {
    local sep=' '
    if [ "${1}" = "-s" ]; then shift; sep="${1}"; shift; fi
    bsl_rtrim -s "${sep}" "$(bsl_ltrim -s "${sep}" "${@}")"
}

# Example:
#
#   bsl_join ':' a b c    # -> 'a:b:c'
#
bsl_join()  { local IFS="${1:-}"; shift; echo "${*}"; }

# Example:
#
#   bsl_split ':' 'a:b:c' # -> ' a b c' (yes, there is a leading ' ')
#
bsl_split() {
    local sep="${1}"
    shift
    echo "${1//*(${sep})/ }"
}

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
