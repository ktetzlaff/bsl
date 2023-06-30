#D# Functions to help with (re-)loading BSL libraries.

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

[ "${BSL_INIT_DEBUG:-0}" -eq 0 ] || {
    _bsl_init_print_sourced -v 2>/dev/null || echo "sources: ${BASH_SOURCE[*]}"
}

##############################################
# internal (_bsl_init_...) helper functions
##############################################

#D# Expand bundled option string into multiple separate options.
#
# Short program options are composed of a hyphen followed by a single letter (s.
# `argument syntax
# <https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html>`_).
# Multiple such options can be bundled into a single option string (e.g. `ls -l
# -a` can be replaced by `ls -la`). This function unbundles such option strings
# into separate options.
#
# .. note::
#
#    Options which take arguments are not supported by this function.
#
# Args:
#     arg (str): command line argument/option
#
# Returns:
#     exit status (int): ``0`` in case of success, any other value indicates an
#         error
#
#     stdout (str): expanded options
_bsl_init_unbundle_option() {
    local arg="${1}"
    local -a opts=()
    if [[ "${arg:0:1}" = '-' && "${#arg}" -gt 2 && "${arg:1:1}" != '-' ]]; then
        local i
        for ((i = $(("${#arg}" - 1)); i > 0; --i)); do
            opts=("-${arg:${i}:1}" "${opts[@]}")
        done
    else
        opts=("${arg}")
    fi
    printf -- '%s' "${opts[*]}"
}

#D# Parse bsl_load arguments.
#
# The parsing detects know options and translates them into corresponding
# entries in the associative array variable ``opts`` (using the long option name
# as the key; with ``-`` converted to ``_``).
#
# Known options:
#
# -v, --verbose: increase verboseness
# -r, --reload: reload library (or libraries)
# -n, --name-only:
#
# Additional non option arguments are stored under ``opt['libs']`` with
# individual entries separated by ``;``.
#
# Args:
#     *args: argument list
#
# Returns:
#     exit status (int): ``0`` in case of success, any other value indicates
#         an error
#
#     opt (outvar): associative array with the detected options
#
#     stdout: na
#
#     stderr: message detailing the error in case there is one
_bsl_init_parse_args() {
    # - expects associative array variable `opt` to be defined
    # - may set keys: libs (pathlist), reload (bool), name_only (bool)
    while [ "${#}" -gt 0 ]; do
        if [[ "${1:0:1}" = '-' && "${#1}" -gt 2 && "${1:1:1}" != '-' ]]; then
            local -a args
            IFS=' ' read -r -a args <<<"$(_bsl_init_unbundle_option "${1}")"
            shift
            _bsl_init_parse_args "${args[@]}" "${@}"
            return "${?}"
        fi
        case "${1}" in
            -v | --verbose)
                [[ ! -v opt['verbose'] ]] || ((++opt['verbose']))
                ;;
            -r | --reload)
                [[ ! -v opt['reload'] ]] || opt['reload']=1
                ;;
            -n | --name-only)
                [[ ! -v opt['name_only'] ]] || opt['name_only']=1
                ;;
            -*)
                local msg="unknown option: '${1}'"
                echo "[ERR] ${msg}" >&2
                opt['error']="${msg}"
                return 1
                ;;
            *)
                [[ ! -v opt['libs'] ]] || {
                    if [ -z "${opt['libs']}" ]; then
                        opt['libs']="${1}"
                    else
                        printf -v opt['libs'] \
                            -- "%s\0%s" "${opt['libs']}" "${1}"
                    fi
                }
                ;;
        esac
        shift
    done

    if [ "${BSL_LOGLEVEL:-2}" -gt 2 ]; then
        for k in "${!opt[@]}"; do
            printf -- "[DBG] %s='%s'\n" "${k}" "${opt[${k}]}" >&2
        done
    fi
}

#D# Generate name of guard variable for given library name (or path).
#
# Writes the name of the guard variable to stdout if the guard is defined (or if
# the ``-n``/``--name-only`` option is used).
#
# Examples:
#
# #. Simple name::
#
#   $ _bsl_init_guard -vn foo
#   _BSL_FOO
#
# #. A leading ``bsl_`` and trailing ``.bash`` in ``name`` are ignored::
#
#   $ _bsl_init_guard -vn bsl_foo.bash
#   _BSL_FOO
#
# Args:
#     name (str): name of the library
#
# Returns:
#     exit status (int): ``0`` in case of the guard is defined (or
#         ``-n``/``--name-only`` option is used), ``1`` if the guard is
#         not defined
#
#     stdout (str): guard variable for ``name`` if it is defined (or
#         if ``-n``/``--name-only`` option is used)
_bsl_init_guard() {
    local -A opt=(
        ['name_only']=0
        ['verbose']=0
        ['libs']=''
    )
    _bsl_init_parse_args "$@"

    local name_or_path="${opt['libs']^^}"
    [ "${name_or_path:0:4}" = "BSL_" ] || name_or_path="BSL_${name_or_path}"

    local guard
    guard="__$(basename "${name_or_path}" .BASH)_LOADED__"
    # if the guard is not defined, unset guard variable
    if [[ ! -v "${guard}" && "${opt['name_only']}" -eq 0 ]]; then
        unset guard
    fi
    [ -n "${guard}" ] || return 1

    if [ "${opt['verbose']}" -eq 1 ]; then
        if [ "${opt['name_only']}" -eq 1 ]; then
            printf -- "%s\n" "${guard}"
        else
            printf -- "%s='%s'\n" "${guard}" "${!guard:-}"
        fi
    else
        printf -- '%s' "${guard}"
    fi
}

#D# Print sourced files to stdout.
#
# In case of nested source statements, the order of sourced files is latest
# first.
_bsl_init_print_sourced() {
    local -i verbose="${1:-0}"
    local prfx=''

    [ "${verbose}" -eq 0 ] || printf -- 'sources: '
    local -i end="${#FUNCNAME[*]}"
    for ((i = 1; i < "${end}"; ++i)); do
        [ "${FUNCNAME[${i}]}" != "source" ] || {
            printf -- "%s" "${prfx}${BASH_SOURCE[${i}]}"
            prfx=' '
        }
    done
    [ "${verbose}" -eq 0 ] || printf -- '\n'
}

#D# Initialize BSL library.
#
# The following lines shall added to the beginning of every BSL library::
#
#   [ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
#   declare -f _bsl_init_lib >/dev/null || source "${BSL_PATH}/init.bash"
#   _bsl_init_lib || return 0
_bsl_init_lib() {
    local lib guard
    lib="$(basename "${BASH_SOURCE[1]}")"
    guard="$(_bsl_init_guard -n "${lib}")"

    [ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"

    [ "${!guard:-0}" -eq 1 ] && return 1 || printf -v "${guard}" -- '%d' 1
    [ "${BSL_INIT_DEBUG:-0}" -lt 1 ] || {
        local -i end="${#FUNCNAME[*]}"
        _bsl_init_print_sourced -v
    }
}

#D# Finalize BSL lib loading.
#
# The following lines shall added to the end of every BSL library::
#
#   ##############################################
#   _bsl_finalize_lib
#   ##############################################
_bsl_finalize_lib() {
    [ "${BSL_INIT_DEBUG:-0}" -lt 1 ] || echo "end:     ${BASH_SOURCE[1]}"
}

##############################################
# public functions
##############################################

# Load a BSL library
#
# Args:
#     lib (str): library to load (full path, relative path or name)
bsl_load_lib() {
    local lib="${1}" reload="${2:-0}" verbose="${3:-0}"
    [ -n "${lib}" ] || {
        echo "usage: bsl_load_lib <lib>"
        return 1
    }

    [ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"

    lib="$(basename "${lib}" .bash).bash"
    [ -f "${lib}" ] || lib="${BSL_PATH}/${lib}"

    [ "${reload}" -eq 0 ] || unset "$(_bsl_init_guard -n "${lib}")"
    [ "${verbose}" -eq 0 ] || local BSL_INIT_DEBUG=1

    # shellcheck disable=SC1090
    source "${lib}"
}

#D# Load all BSL libraries.
bsl_load() {
    local -A opt=(
        ['reload']=0
        ['verbose']=0
    )
    _bsl_init_parse_args "$@" || return "${?}"

    bsl_load_lib 'init' "${opt['reload']}" "${opt['verbose']}"
    for lib in "${BSL_PATH}/bsl_"*.bash; do
        bsl_load_lib "${lib}" "${opt['reload']}" "${opt['verbose']}"
    done
}

#D# Reload all BSL libraries.
bsl_reload() {
    bsl_load --reload "${@}"
}

##############################################
_bsl_finalize_lib
##############################################
