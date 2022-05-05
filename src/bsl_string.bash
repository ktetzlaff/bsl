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

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "${BSL_PATH}/bsl_logging.bash"

##############################################
# string functions
##############################################

_bsl_parse_args_sep() {
    # sets/modifies variables `sep` (str) and `args` (array[str])
    while [ $# -gt 0 ]; do
        case "${1}" in
            -s*)
                [[ "${#}" -gt 1 || "${#1}" -gt 2 ]] || {
                    bsl_loge "missing separator"
                    return 1
                }
                if [ "${#1}" -eq 2 ]; then
                    sep="${2}"
                    shift
                else
                    sep="${1:2}"
                fi
                ;;
            *)
                args+=("${1}")
                ;;
        esac
        shift
    done
}

# Examples:
#
#   bsl_rtrim "  hello  " # -> '  hello'
#   bsl_ltrim "  hello  " # -> 'hello  '
#   bsl_trim  "  hello  " # -> 'hello'
#
#   bsl_trim -s ':'  '::hello::' # -> 'hello'
#
bsl_rtrim() {
    local sep=' '
    local -a args
    _bsl_parse_args_sep "${@}"
    [ "${#args[*]}" -gt 0 ] || return 0

    saved=$(shopt -p extglob)
    shopt -s extglob
    args=("${args[@]%%+([${sep}])}")
    eval "${saved}"
    printf '%s' "${args[*]}"
}

bsl_ltrim() {
    local sep=' '
    local -a args
    _bsl_parse_args_sep "${@}"
    [ "${#args[*]}" -gt 0 ] || return 0

    saved=$(shopt -p extglob)
    shopt -s extglob
    args=("${args[@]##+([${sep}])}")
    eval "${saved}"
    printf '%s' "${args[*]}"
}

bsl_trim() {
    local sep=' '
    local -a args
    _bsl_parse_args_sep "${@}"
    [ "${#args[*]}" -gt 0 ] || return 0

    bsl_rtrim -s "${sep}" "$(bsl_ltrim -s "${sep}" "${args[@]}")"
}

# Example:
#
#   bsl_join a b c         # -> 'abc'
#   bsl_join -s: a b c     # -> 'a:b:c'
#   bsl_join -s', ' a b c  # -> 'a, b, c'
#
bsl_join() {
    local sep=''
    _bsl_parse_args_sep "${@}"
    [ "${#args[*]}" -gt 0 ] || return 0

    local result="${args[0]}"
    unset "args[0]"
    for e in "${args[@]}"; do
        result="${result}${sep}${e}"
    done
    printf '%s' "${result}"
}

# Example:
#
#   bsl_split -s ':' 'a:b:c' # -> 'a b c'
#
bsl_split() {
    local sep=' '
    local -a args
    _bsl_parse_args_sep "${@}"
    [ "${#args[*]}" -gt 0 ] || return 0

    saved=$(shopt -p extglob)
    shopt -s extglob
    args=("${args[@]//+([${sep}])/ }")
    eval "${saved}"
    printf '%s' "${args[*]}"
}

# Example:
#
#   bsl_reverse_lines < file
#
bsl_reverse_lines() {
    local in="${1:-/dev/stdin}"
    [ -e "${in}" ] || {
        bsl_loge "file not found: '${in}'"
        return 1
    }

    local output='' line
    while true; do
        [ ! -v line ] || printf -v output '%s\n%s' "${line}" "${output}"
        read -r line || break
    done <"${in}"
    printf '%s%s' "${line}" "${output}"
}
alias bsl_tac=bsl_reverse_lines

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
