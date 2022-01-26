#D# Path (PATH, MANPATH, ...) manipulation functions.

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

[ ${_BSL_PATH:-0} -eq 1 ] && return || _BSL_PATH=1
[ ${BSL_INC_DEBUG:=0} -lt 1 ] || echo "sources: ${BASH_SOURCE[@]}"

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"

##############################################
# utility functions
##############################################

_bsl_path_usage() {
    1>&2 cat <<-EOF
Usage: ${FUNCNAME[-1]} [-v|--verbose] [-a|--after]
       [-p|--prepend] [-r|--replace]
       [--path NEWPATH] [--variable VARNAME] NEWPATH...
Modify PATH (or VARNAME).

  -a, --append            append NEWPATH element(s) at end of PATH [default]
  -p, --prepend           add NEWPATH element(s) at start of PATH
  -r, --replace           if a NEWPATH element already exists, remove it first
      --after             alias for --append
  -b, --before            alias for --prepend
  -f, --force             alias for --replace
      --path=NEWPATH      NEWPATH element(s) to add
      --variable=VARNAME  name of (path) variable to modify [default: PATH]
  -v, --verbose           increase verbosity of (log) output
  -h, --help              display this help and exit
EOF
}

#
# Parse arguments for bsl_path_* functions.
#
_bsl_path_argparse() {
    local -A opt
    local -a paths

    opt['_bsl_path_argparse']='1'
    opt['position']='-1'
    opt['replace']='0'
    opt['variable']='PATH'
    while [ -n "${1}" ]; do
        case "${1}" in
            -h|--help|-\?)
                _bsl_path_usage
                opt['_bsl_path_argparse_errno']=0
                ;;
            -v|--verbose)
                opt['verbose']='1'
                ;;
            -a|--append|--after)
                opt['position']='-1'
                ;;
            -p|--prepend|-b|--before)
                opt['position']='0'
                ;;
            -r|--replace|-f|--force)
                opt['replace']='1'
                ;;
            --path)
                shift
                paths+=("${1}")
                ;;
            --va*)
                shift
                opt['variable']="${1}"
                ;;
            -*)
                # unexpected option - print an error message to stderr and set
                # opt['_bsl_path_argparse_errno']=1 to indicate an error
                1>&2 echo "[ERR] unexpected option: '${1}'"
                unset opt
                opt['_bsl_path_argparse_errno']=1
                break
                ;;
            *)
                paths+=("${1}")
                ;;
        esac
        shift
    done

    if [ -n "${opt['_bsl_path_argparse_errno']}" ]; then
        echo "declare _bsl_path_argparse_errno=${opt['_bsl_path_argparse_errno']}"
        return ${opt['_bsl_path_argparse_errno']}
    fi

    local IFS=:
    opt['paths']="${paths[*]}"

    echo 'declare'
    for e in "${!opt[@]}"; do
        echo "${e}='${opt[${e}]}'"
    done
}

#
# Canonicalize path (${1}).
#
_bsl_path_canonicalize() {
    local p="${1}"
    # empty element is equivalent to CWD (weird, I know), remove it
    if [ -z "${p}" ]; then
        return
    fi

    # remove any relative paths
    if [ "${p:0:1}" != '/' ]; then
        return
    fi

    # normalize path and ensure we can access it
    p=$(cd "${p}" &>/dev/null && echo "${PWD}")
    # path doesn't exist or we can't access it
    if [ -z "${p}" ]; then
        return
    fi
    echo "${p}"
}

#
# Print path on multiple lines
#
bsl_path_ls() {
    local var="${1:-PATH}"
    if [ -n "${!var}" ]; then
        echo -e "${!var//:/\\n}"
    fi
}

#
# bsl_path_add <path> [direction] [varname]
#
# bsl_path_add takes a directory name, an optional direction name (defaults to
# "after" to append to list) and an optional variable name (defaults to PATH)
# and adds the directory name to data stored in variable.
#
# Example
#
# given: PATH='/bin:/sbin'
#
# bsl_path_add /usr/bin
# // PATH => '/bin:/sbin:/usr/bin'
# bsl_path_add /opt/local/bin before
# // PATH => '/opt/local/bin:/bin:/sbin:/usr/bin'
#
# The variable name should be passed by name.
# foo=''
# bsl_path_add /bin after foo
# // foo => '/bin'
#
# KTKT: It turns out that bsl_path_add is rather slow (~90ms on Intel E3-1575M in
# WSL)
#
bsl_path_add() {
    eval $(_bsl_path_argparse "${@}")
    if [ -v _bsl_path_argparse_errno ]; then
        return ${_bsl_path_argparse_errno}
    fi
    local path=$(bsl_path_print_add "$@") || return $?
    read -r "${variable?}" <<< "${path}"
}

#
# bsl_path_remove <path> [varname]
#
# bsl_path_remove takes a directory name and an optional variable name
# (defaults to PATH) and removes every instance of the directory name from the
# data stored in the variable.
#
# Example
#
# given: PATH='/bin:/sbin:/usr/bin:/usr/sbin'
#
# bsl_path_remove /usr/bin
# // PATH => '/bin:/sbin:/usr/sbin'
# bsl_path_remove /not-found
# // PATH => '/bin:/sbin:/usr/sbin'
#
# The variable name should be passed by name.
# foo='/bin:/sbin'
# bsl_path_remove /bin foo
# // foo => '/sbin'
#
bsl_path_remove() {
    local var="${2:-PATH}"
    local path=
    path=$(bsl_path_print_remove "$@") || return 1
    read -r "${var?}" <<< "${path}"
}

#
# bsl_path_clean [varname]
#
# bsl_path_clean takes an optional variable name (defaults to PATH) and "cleans"
# it, this process will:
#
# 1. Remove empty elements (which are treated like CWD/'.').
# 2. Remove relative directories.
# 3. Remove directories that don't exist/can't be accessed (checked with
#    `cd`).
# 4. Remove duplicates (first element stays, subsequent elements are tossed).
#
# Example
#
# PATH='::/bin:/sbin:::./:../../some-path::/doesnt-exist'
# bsl_path_clean
# // PATH => '/bin:/sbin'

# PATH='/bin:/bin//:////bin//////:/bin/dir/..::'
# bsl_path_clean
# // PATH => '/bin'
#
# The variable name should be passed by name.
# foo='/bin:/bin'
# bsl_path_clean /bin foo
# // foo => '/bin'
#
bsl_path_clean() {
    local var="${1:-PATH}"
    local path=$(bsl_path_print_clean "$@") || return 1
    read -r "${var?}" <<< "${path}"
}

#
# Prints a string which can be used to update the given path variable by
# `eval`ing it.
#
# eval bsl_path_print_add '/opt/local/bin'
#
# See `bsl_path_add` for more details.
#
bsl_path_print_add() {
    if [ ! -v _bsl_path_argparse ]; then
        eval $(_bsl_path_argparse "${@}")
    fi
    if [ -v _bsl_path_argparse_errno ]; then
        return ${_bsl_path_argparse_errno}
    fi

    local -a arr
    IFS=: read -ra cpaths <<< $(bsl_path_print_clean "${variable}")
    local -A cur
    for i in "${!cpaths[@]}"; do
        cur["${cpaths[${i}]}"]="${i}"
    done

    local taccat=$(if [ ${position} -eq 0 ]; then echo tac; else echo cat; fi)
    IFS=: read -ra npaths <<< "${paths}"
    while read -r new; do
        new=$(_bsl_path_canonicalize "${new}")
        if [ -v cur["${new}"] ]; then
            if [ "${replace:-0}" -eq 1 ]; then
                unset cpaths["${cur[${new}]}"]
            else
                unset new
            fi
        fi

        if [ -v new ]; then
            case "${position}" in
                -1) cpaths=("${cpaths[@]}" "${new}");;
                *) cpaths=("${new}" "${cpaths[@]}");;
            esac
        fi
    done <<< "$((for e in "${npaths[@]}"; do echo "${e}"; done) | ${taccat})"

    local IFS=:
    local new="${cpaths[*]}"
    [ "${new:0:1}" = ':' ] && new="${new:1}"
    [ "${new: -1}" = ':' ] && new="${new:0:-1}"
    echo "${new}"
}

#
# Exact same usage as bsl_path_remove but prints the new PATH only and doesn't
# modify anything in place.
#
bsl_path_print_remove() {
    local p="${1}"
    local var="${2:-PATH}"

    local -a arr newarr
    if [[ -z $p || $p == *:* ]]; then
        echo "bsl_path_print_remove: invalid argument: '$p'" >&2
        return 1
    fi

    IFS=: read -ra arr <<< "${!var}:"

    local _p
    for _p in "${arr[@]}"; do
        if [[ $p == "$_p" ]]; then
            continue
        fi
        newarr+=("$_p")
    done

    local IFS=:
    echo "${newarr[*]}"
}

#
# Exact same usage as bsl_path_clean but prints the new PATH only and doesn't
# modify anything in place.
#
bsl_path_print_clean() {
    local var="${1:-PATH}"

    # read PATH into an array, trailing ":" is due to:
    # http://mywiki.wooledge.org/BashPitfalls#pf47
    IFS=: read -ra arr <<< "${!var}:"

    local p
    local -a newarr
    local -A seen
    for p in "${arr[@]}"; do
        p="$(_bsl_path_canonicalize "${p}")"
        [ -z "${p}" ] && continue

        # filter out dups while we are here
        [ -v seen[${p}] ] && continue
        seen[${p}]=true

        # store the new path
        newarr+=("${p}")
    done

    local IFS=:
    echo "${newarr[*]}"
}

##############################################
# end
##############################################
[ ${BSL_INC_DEBUG} -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
