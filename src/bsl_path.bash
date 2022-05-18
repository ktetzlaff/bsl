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

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
declare -f _bsl_init_lib >/dev/null || source "${BSL_PATH}/init.bash"
_bsl_init_lib || return 0

bsl_load_lib 'bsl_logging'

##############################################
# internal (_bsl_path) functions
##############################################

# editorconfig-checker-disable

# _bsl_path_usage ACTION
#
# Prints a usage/help message to stderr.
#
_bsl_path_usage() {
    local action="${1:-add}"

    if [ "${action}" = "ls" ]; then
        cat 1>&2 <<-'EOF'
Usage: bsl_path_ls [--varname VARNAME] [VARNAME]

List elements of value of VARNAME (default: PATH), each on a seperate line.
EOF
        return 0
    elif [ "${action}" = "clean" ]; then

        cat 1>&2 <<-'EOF'
Usage: bsl_path_clean [-v|--verbose] [-n|--dry-run]
       [--varname VARNAME] [VARNAME]
       [--printval]

Clean value of VARNAME (default: PATH).

  -h, --help              display this help and exit
  -v, --verbose           increase verbosity of (log) output
  -n, --dry-run           just print the result without changing VARNAMEs
                            value, format: ${VARNAME}=<value>
      --printval          same as --dry-run, but just print <value>
      --varname VARNAME   name of variable to operate on (default: PATH)
EOF
        return 0

    else

        cat 1>&2 <<-EOF
Usage: bsl_path_${action} [-v|--verbose] [-n|--dry-run]
EOF

    fi

    local -A short=(
        ['add']='Add ADDPATH elements to'
        ['remove']='Remove RMPATH elements from'
    )

    if [ "${action}" = "remove" ]; then
        cat 1>&2 <<-'EOF'
       [--varname VARNAME]
       [--path RMPATH]... [RMPATH]...
EOF
    elif [ "${action}" = "add" ]; then
        cat 1>&2 <<-'EOF'
       [-a|--append] [-p|--prepend] [-r|--replace]
       [--varname VARNAME]
       [--path ADDPATH]... [ADDPATH]...
EOF
    fi

    cat 1>&2 <<-EOF

${short["${action}"]} value of VARNAME (default: PATH).

  -h, --help              display this help and exit
  -v, --verbose           increase verbosity of (log) output
  -n, --dry-run           just print the result without changing VARNAMEs
                            value, format: \${VARNAME}=<value>
      --printval          same as --dry-run, but just print <value>
  -q, --quiet             minimize output, ignore (recoverable) errors
      --varname VARNAME   name of variable to operate on (default: PATH)
EOF

    if [ "${action}" = "remove" ]; then

        cat 1>&2 <<-'EOF'
      --path RMPATH       RMPATH element(s) to remove
EOF

    else

        cat 1>&2 <<-'EOF'
      --path ADDPATH      ADDPATH element(s) to add
  -a, --append            append ADDPATH element(s) (default)
  -p, --prepend           prepend ADDPATH element(s)
  -r, --replace           if ADDPATH element already exists, remove it first
      --after             alias for --append
  -b, --before            alias for --prepend
  -f, --force             alias for --replace
EOF
    fi
}

# editorconfig-checker-enable

# _bsl_path_argparse_invalid_opt OPT_NAME [PATHS_NAME]
#
# Used in _bsl_path_argparse to handle invalid options.
#
_bsl_path_argparse_invalid_opt() {
    local -n opt_ref="${1}"
    shift
    [ ! -v "opt_ref['quiet']" ] || return 0
    opt_ref=() # clear opt_ref

    if [ "${#}" -gt 1 ]; then
        paths_ref="${1}"
        shift
        paths_ref=() # clear paths_ref
    fi

    bsl_loge "invalid option: '${1}'"
    return 1
}

# _bsl_path_argparse_handle_path ACTION PATHS_NAME PATH
#
# Handle PATH (ADDPATH/RMPATH) arguments in _bsl_path_argparse. Unpacks
# multiple elements (e.g. '/bin:/sbin' -> ['/bin', '/sbin']) and skips over
# invalid paths (s. bsl_path_canonicalize).
#
_bsl_path_argparse_handle_path() {
    local action="${1}"
    # shellcheck disable=SC2178
    local -n paths_ref="${2}"
    local ahp_unpacked
    IFS=: read -ra ahp_unpacked <<<"${3}"

    local p cp
    for p in "${ahp_unpacked[@]}"; do
        if [ "${action}" = 'remove' ]; then
            cp="${p}"
        else
            # adding paths which fail the checks in bsl_path_canonicalize
            # (e.g. non-existent directories) doesn't make sense (until
            # someone convinces me otherwise)
            cp="$(bsl_path_canonicalize "${p}")" || {
                [ "${DEBUG:-0}" -lt 1 ] \
                    || bsl_logw "${FUNCNAME[0]}: skip '${p}'"
                continue
            }
        fi
        paths_ref+=("${cp}")
    done
    return 0
}

# _bsl_path_argparse ACTION OPT_NAME [PATHS_NAME] [ARG]...
#
# Parse arguments for bsl_path_* functions.
#
# Args:
#
# - ACTION: Action to be performed, one of [ls, clean, add, remove].
# - OPT_NAME: Name of an associative array variable. Depending on ARGs,
#   _bsl_path_argparse will add the following keys: 'variable', 'position',
#   'replace'.
# - PATHS_NAME: Only for ACTION add/remove. Name of an array variable.
#   Depending on ARGs, _bsl_path_argparse will add path elements to
#   PATHS_NAME.
#
_bsl_path_argparse() {
    local action="${1}"
    shift

    local -a refs=()
    # shellcheck disable=SC2178
    local -n opt_ref="${1}"
    refs+=("${1}")
    shift
    # reset opt to (common) defaults
    opt_ref=(
        ['verbose']='0'
        ['varname']=''
    )

    if [[ "${action}" =~ add|remove ]]; then
        # shellcheck disable=SC2178
        local -n paths_ref="${1}"
        refs+=("${1}")
        shift
        # reset paths
        paths_ref=()

        if [ "${action}" = 'add' ]; then
            opt_ref['position']='-1'
            opt_ref['replace']='0'
        fi
    fi

    while [ -n "${1}" ]; do
        case "${1}" in
            -h | --help | -\?)
                _bsl_path_usage "${action}"
                opt_ref=(['help']=1)
                return 0
                ;;
            -v | --verbose)
                ((++opt_ref['verbose']))
                ;;
            -n | --dry*)
                opt_ref['dryrun']='1'
                ;;
            -q | --quiet)
                opt_ref['quiet']='1'
                ;;
            -a | --append | --after)
                [ -v "opt_ref['position']" ] \
                    || _bsl_path_argparse_invalid_opt "${refs[@]}" "${1}" \
                    || return "${?}"
                opt_ref['position']='-1'
                ;;
            -p | --prepend | -b | --before)
                [ -v "opt_ref['position']" ] \
                    || _bsl_path_argparse_invalid_opt "${refs[@]}" "${1}" \
                    || return "${?}"
                opt_ref['position']='0'
                ;;
            -r | --replace | -f | --force)
                [ -v "opt_ref['replace']" ] \
                    || _bsl_path_argparse_invalid_opt "${refs[@]}" "${1}" \
                    || return "${?}"
                opt_ref['replace']='1'
                ;;
            --printval*)
                opt_ref['printval']='1'
                ;;
            --path)
                [ -R paths_ref ] \
                    || _bsl_path_argparse_invalid_opt "${refs[@]}" "${1}" \
                    || return "${?}"
                shift
                _bsl_path_argparse_handle_path \
                    "${action}" "${refs[1]}" "${1}" || true
                ;;
            --var*)
                shift
                opt_ref['varname']="${1}"
                ;;
            -*)
                # unexpected option - print an error message to stderr return
                # 1 to indicate an error
                bsl_loge "unexpected option: '${1}'"
                opt_ref=()
                paths_ref=()
                return 2
                ;;
            *)
                if [ -R paths_ref ]; then
                    _bsl_path_argparse_handle_path \
                        "${action}" "${refs[1]}" "${1}" || true
                elif [ -z "${opt['varname']}" ]; then
                    opt['varname']="${1}"
                else
                    # editorconfig-checker-disable
                    bsl_loge "duplicate VARNAME - '${1}' would overwrite '${opt['varname']}'"
                    # editorconfig-checker-enable
                    opt_ref=()
                    paths_ref=()
                    return 3
                fi
                ;;
        esac
        shift
    done

    if [ -z "${opt['varname']}" ]; then
        opt['varname']='PATH'
    fi
}

##############################################
# public bsl_path functions
##############################################

# bsl_path_canonicalize PATH
#
# Print canonicalized PATH to stdout.
#
# The cleanup process allows to detect invalid paths (s. below), resolves '.',
# '..' and replaces multiple consecutive slashes with a single '/'.
#
# If an invalid (empty, relative, non-existent, non-accessible, ...) PATH is
# detected there is no output and the return value is one of:
#
# - 1: PATH is empty
# - 2: PATH does not start with '/' (e.g. relative path)
# - 3: PATH is not a directory (e.g. file, non-existent location, ...)
# - 4: PATH is not accessible
#
# Note: Contrary to `realpath`, bsl_path_canonicalize does not try to resolve
# symlinks.
#
# KTKT: add examples!
bsl_path_canonicalize() {
    local p="${1}"

    # invalid: empty path
    [ -n "${p}" ] || return 1
    # invalid: anything not starting with '/' (relative path, leading spaces,
    # ...)
    [ "${p:0:1}" = '/' ] || return 2
    # invalid: not a directory
    [ -d "${p}" ] || return 3
    # invalid: not accessible
    pushd "${p}" &>/dev/null || return 4

    # use ${PWD} to canonicalize path
    #
    # with special handling for leading '//' which may be present for
    # historical reasons, see
    # https://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap04.html:
    #
    #   ... A pathname that begins with two successive slashes may be
    #   interpreted in an implementation-defined manner, although more than
    #   two leading slashes shall be treated as a single slash. ...
    #
    # where the 'implementation-defined manner' for the '//' case is typically
    # treated identical to '/' (with the possible exception of msys/cygwin on
    # windows where '//' may still indicate a network path - ignored for now)
    p="${PWD/\/\//\/}"
    popd &>/dev/null || true

    echo "${p}"
}

# bsl_path_ls VARNAME
#
# Print each element of VARNAMEs value on separate line.
#
bsl_path_ls() {
    local -A opt=()
    _bsl_path_argparse ls opt "${@}" || return "${?}"
    [ ! -v "opt['help']" ] || return 0

    local varname="${opt['varname']}"
    [ -v "${varname}" ] || {
        bsl_loge "${FUNCNAME[0]}: '${varname}' not defined"
        bsl_log 0 1 1
        _bsl_path_usage add
        return 10
    }

    if [ -n "${!varname:-}" ]; then
        echo -e "${!varname//:/\\n}"
    fi
}

# bsl_path_clean [VARNAME]
#
# bsl_path_clean takes an optional VARNAME (default: PATH) and returns
# (prints) a cleaned up version of the value of VARNAME. The cleaning
# process will:
#
# 1. canonicalize paths containing '.' and duplicate '/' ('/usr//share/../bin'
#    => '/usr/bin')
# 2. remove empty elements (':/bin::' => '/bin')
# 3. remove relative elements ('/bin:./sbin:.local/bin' => '/bin')
# 4. remove directories that don't exist or can't be accessed
# 5. remove duplicates (first element stays, subsequent elements are tossed).
#
# Examples:
#
#   - with foo='/bin:/bin'
#     $ bsl_path_clean --varname foo # => foo='/bin'
#
#   - with PATH='/bin:/bin//:////bin//////:/usr/bin/does not exist/..::'
#     $ bsl_path_clean # => PATH='/bin'
#
#   - with PATH='::/bin:/sbin:::./:../some-rel-path::/does not exist'
#     $ bsl_path_clean # => PATH='/bin:/sbin'
#
bsl_path_clean() {
    local -A opt=()
    _bsl_path_argparse clean opt "${@}" || return "${?}"
    [ ! -v "opt['help']" ] || return 0

    local varname="${opt['varname']}"

    local curpaths
    IFS=: read -ra curpaths <<<"${!varname}"

    local -a results
    local -A seen
    local cp
    for cp in "${curpaths[@]}"; do
        cp="$(bsl_path_canonicalize "${cp}")" || continue

        # filter out duplicates
        [[ ! -v "seen[${cp}]" ]] || continue

        # mark as seen
        seen["${cp}"]='1'

        # store the new path
        results+=("${cp}")
    done

    local IFS=:
    local result="${results[*]}"
    unset IFS

    # 'publish' result depending on user options
    if [ -v "opt['printval']" ]; then
        echo "${result}"
    elif [ -v "opt['dryrun']" ]; then
        echo "${varname}=${result}"
    else
        # shellcheck disable=SC2229
        read -r "${varname}" <<<"${result}"
    fi
}

# bsl_path_add ...
#
# Add directories to the value of VARNAME (default: PATH) and print the
# result.
#
# Examples:
#
#   given: PATH='/bin:/sbin', foo='/usr/bin'
#
#   - append '/usr/bin' to value of `PATH`:
#     $ bsl_path_add /usr/bin           # => PATH='/bin:/sbin:/usr/bin'
#
#   - prepend '/opt/local/bin' to value of `PATH`:
#     $ bsl_path_add -p /opt/local/bin  # => PATH='/opt/local/bin:/bin:/sbin'
#
#   - append '/bin' to value of `foo`:
#     $ bsl_path_add --varname foo /bin # => PATH='/usr/bin:/bin'
#
#   - move '/sbin' to the beginning of `PATH`:
#     $ bsl_path_add --replace -p /sbin # => PATH='/sbin:/bin'
#
# KTKT: It turns out that bsl_path_add (measured via: time bsl_path_add -n
# '/etc') on WSL2 is rather slow at ~120ms (on Intel E3-1575M 3GHz, WSL2
# v0.51.2.0), kernel 5.10.81.1-microsoft-standard-WSL). On the same machine
# with native linux (debian bookworm, kernel 5.15.0-3-amd64 #1 SMP Debian
# 5.15.15-2 (2022-01-30)) it takes ~33ms whereas on a (on paper) much slower
# machine (QTS 4.3.6.1907 build 20220103. i7-3770T 2.5GHz, kernel 4.2.8) it
# just takes ~13ms.
#
bsl_path_add() {
    local -A opt=()
    local -a addpaths=()
    _bsl_path_argparse add opt addpaths "${@}" || return "${?}"
    [ ! -v "opt['help']" ] || return 0

    [[ "${#addpaths[*]}" -gt 0 || -v "opt['quiet']" ]] || {
        bsl_loge "${FUNCNAME[0]}: missing ADDPATH"
        bsl_log 0 1 1
        _bsl_path_usage add
        return 10
    }

    local i
    # if prepending, reverse addpaths
    if [ "${opt['position']}" -eq 0 ]; then
        local -a _tmp
        for ((i = ${#addpaths[@]}; i--; )); do
            _tmp+=("${addpaths[${i}]}")
        done
        addpaths=("${_tmp[@]}")
        unset _tmp
    fi
    local varname="${opt['varname']}" replace="${opt['replace']}"

    # build associative array of current path (cpath) to allow duplicate
    # detection
    local curpaths
    IFS=: read -ra curpaths <<<"$(bsl_path_clean --printval "${varname}")"
    local -A cur
    for i in "${!curpaths[@]}"; do
        cur["${curpaths[${i}]}"]="${i}"
    done

    # mark duplicates by changing curpaths/addpaths elements to the empty string
    #echo "addpaths: '(${addpaths[*]})'"
    local ap
    for i in "${!addpaths[@]}"; do
        ap="${addpaths[${i}]}"
        #echo "process: '${ap}'"
        ap="$(bsl_path_canonicalize "${ap}")" || continue
        #echo "canonicalized: '${ap}'"
        if [[ -v cur["${ap}"] ]]; then
            if [ "${replace}" -eq 1 ]; then
                curpaths["${cur[${ap}]}"]=''
            else
                #echo "already present: '${ap}'"
                addpaths["${i}"]=''
            fi
        fi
    done

    # start building result by joining curpaths using ':' as seperator ...
    local IFS=:
    local result="${curpaths[*]}"
    unset IFS

    # remove artifacts of duplicate marking ...
    if [ "${replace}" -eq 1 ]; then
        while [ "${result}" != "${result//::/:}" ]; do
            result="${result//::/:}"
        done
    fi

    # add new elements ...
    local position="${opt['position']}"
    for ap in "${addpaths[@]}"; do
        [ -n "${ap}" ] || continue
        #echo "add: '${ap}'"

        if [ "${position}" -eq 0 ]; then
            result="${ap}:${result}"
        else
            result="${result}:${ap}"
        fi
    done

    # and finally, 'publish' result depending on user options
    if [ -v "opt['printval']" ]; then
        echo "${result}"
    elif [ -v "opt['dryrun']" ]; then
        echo "${varname}=${result}"
    else
        # shellcheck disable=SC2229
        read -r "${varname}" <<<"${result}"
    fi
}

# bsl_path_remove DIR [VARNAME]
#
# Removes every instance of DIR from the value of VARNAME (default: PATH).
#
# Examples:
#
#   given: PATH='/bin:/sbin:/usr/bin:/usr/sbin'
#
#   $ bsl_path_remove /notfound # => PATH='/bin:/sbin:/usr/bin:/usr/sbin'
#   $ bsl_path_remove /usr/bin  # => PATH='/bin:/sbin:/usr/sbin'
#
#   The variable to be modified can be passed by name:
#
#   $ foo='/bin:/sbin'
#   $ bsl_path_remove /bin foo # => foo='/sbin'
#
bsl_path_remove() {
    local -A opt=()
    local -a rmpaths=()
    _bsl_path_argparse remove opt rmpaths "${@}" || return "${?}"
    [ ! -v "opt['help']" ] || return 0

    local varname="${opt['varname']}" result
    if [ "${#rmpaths[*]}" -eq 0 ]; then
        [ -v "opt['quiet']" ] || {
            bsl_loge "${FUNCNAME[0]}: missing RMPATHs"
            bsl_log 0 1 1
            _bsl_path_usage remove
            return 10
        }
        result="${!varname}"
    else
        local curpaths
        IFS=: read -ra curpaths <<<"${!varname}:"
        local -a results
        local rmp cp
        for rmp in "${rmpaths[@]}"; do
            for cp in "${curpaths[@]}"; do
                if [ "${rmp}" = "${cp}" ]; then
                    continue
                fi
                results+=("${cp}")
            done
        done

        local IFS=:
        result="${results[*]}"
        unset IFS
    fi

    # 'publish' result depending on user options
    if [ -v "opt['printval']" ]; then
        echo "${result}"
    elif [ -v "opt['dryrun']" ]; then
        echo "${varname}=${result}"
    else
        # shellcheck disable=SC2229
        read -r "${varname}" <<<"${result}"
    fi
}

##############################################
_bsl_finalize_lib
##############################################
