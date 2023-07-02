#D# Simple logging functions.

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

##############################################
# logging functions
##############################################

#D# initialize logging variables
bsl_logging_init() {

    # Note: The logging variables are now defined in this function so the
    # -g(lobal) option is needed to give them global scrope. However, even if
    # these variables were defined in the global scope the -g options were are
    # still required to allow the (BATS) unit tests to pass. Just keep this in
    # mind if the variable declarations are ever moved back to file scope.

    # map human readable, 3 character level string to numeric log level.
    declare -ga BSLL_LEVEL2SNAME=(
        "ERR"
        "WRN"
        "INF"
        "DBG"
        "DB2"
    )

    # map human readable, full length level string to numeric log level.
    declare -ga BSLL_LEVEL2NAME=(
        "ERROR"
        "WARNING"
        "INFO"
        "DEBUG"
        "DEBUG2"
    )

    # map `logger` (*syslog*) priority to numeric log level.
    declare -ga BSLL_LEVEL2LOGGER_PRIO=(
        "error"
        "warning"
        "info"
        "debug"
        "debug"
    )

    # map numeric log level to human readable name.
    # shellcheck disable=SC2034
    declare -gA BSLL_NAME2LEVEL=(
        ["ERR"]="0"
        ["WRN"]="1"
        ["INF"]="2"
        ["DBG"]="3"
        ["DB2"]="4"

        ["ERROR"]="0"
        ["WARNING"]="1"
        ["WARN"]="1"
        ["INFO"]="2"
        ["DEBUG"]="3"
        ["DEBUG2"]="4"

        ["error"]="0"
        ["warning"]="1"
        ["info"]="2"
        ["debug"]="3"
        ["debug2"]="4"
    )

    # default log level (int) to be used to initialize *BSL_LOGLEVEL*
    [ -v BSL_LOGLEVEL_DEFAULT ] || declare -gir BSL_LOGLEVEL_DEFAULT=2

    # log level (int) used by *BSL* logging functions (default= ``2``/``INFO`` )
    [ -v BSL_LOGLEVEL ] || declare -gi BSL_LOGLEVEL=${BSL_LOGLEVEL_DEFAULT}

    # flag (bool) which controls if log messages are sent to *syslog* via
    # ``logger`` cmd (default= ``0`` ).
    declare -gi BSLL_USE_LOGGER=0

    # facility used when logging via `logger` (default= ``user`` ).
    declare -g BSLL_LOGGER_FACILITY='user'
}

#D# Canonicalize log level to an integer value.
bsl_log_level_canonicalize() {
    local lvl="${1}"
    [[ "${lvl}" =~ ^[[:digit:]]+$ ]] || {
        lvl="${BSLL_NAME2LEVEL[${lvl^^}]}"
    }

    [ -n "${lvl}" ] || return 1
    printf '%d' "${lvl}"
}

#D# Set log level (or get current value).
bsl_log_level() {
    local verbose=0 lvl
    while [ ${#} -gt 0 ]; do
        case "${1}" in
            -v | -verbose)
                ((++verbose))
                ;;
            -l | --level)
                lvl=${2}
                shift
                ;;
            -i | --increment | ++)
                lvl="${lvl:-${BSL_LOGLEVEL}}"
                ((++lvl))
                ;;
            -d | --decrement | --)
                lvl="${lvl:-${BSL_LOGLEVEL}}"
                ((--lvl))
                ;;
            -*)
                # report unknown option?
                ;;
            *)
                lvl=${1}
                ;;
        esac
        shift
    done

    [ -n "${lvl}" ] || {
        if [ "${verbose}" -eq 0 ]; then
            printf '%d' "${BSL_LOGLEVEL}"
        else
            bsl_log "${BSL_LOGLEVEL}" 'INF' 1 \
                "log level: ${BSL_LOGLEVEL}" \
                "(${BSLL_LEVEL2NAME[${BSL_LOGLEVEL}]})"
        fi
        return 0
    }
    lvl="$(bsl_log_level_canonicalize "${lvl}" || echo -n "${lvl}")" || {
        bsl_die "invalid log level: '${lvl}'"
        return "${?}"
    }
    # return 0 if new is same as current  leg legel
    [ "${BSL_LOGLEVEL}" -ne "${lvl}" ] || {
        [ "${verbose}" -eq 0 ] || {
            bsl_log "${BSL_LOGLEVEL}" 'INF' 1 \
                "log level unchanged:" \
                "${BSL_LOGLEVEL} (${BSLL_LEVEL2NAME[${BSL_LOGLEVEL}]})"
        }
        return 0
    }
    # repor change in verbose mode
    [ "${verbose}" -eq 0 ] || {
        bsl_log "${BSL_LOGLEVEL}" 'INF' 1 \
            'log level:' \
            "${BSL_LOGLEVEL} (${BSLL_LEVEL2NAME[${BSL_LOGLEVEL}]})" \
            '->' \
            "${lvl} (${BSLL_LEVEL2NAME[${lvl}]})"
    }
    # update log level
    BSL_LOGLEVEL="${lvl}"
}

#D#
# Generic logging function.
#
# Log message to console and, when :py:data:`BSLL_USE_LOGGER` is set to ``1``,
# also to *syslog*.
#
# Message is skipped if **lvl** > :py:data:`BSL_LOGLEVEL`.
#
# Args:
#     lvl (int): log level for current message
#     prefix (str): empty: get prefix from LVL, ``-``: don't add a prefix,
#          ``:f``: append ``/<funcname>`` to LVL prefix, other: use as prefix
#     add_nl (bool): if non-empty, add newline to current message
#     *args (str): All further arguments are joined to form the current
#          message (using ' ' as separator)
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: na
#
# Examples:
#   #. Log error with multiple message arguments::
#
#        $ bsl_log 0 '' 1 consecutive spaces will be replaced by single space
#        [ERR] consecutive spaces will be replaced by single space
#
#   #. Log warning with single, preformatted message argument::
#
#        $ bsl_log 1 '' 1 'spaces will   be preserved   !'
#        [WRN] spaces will   be preserved   !
#
#   #. Log first info with without newline, log 2nd info without prefix::
#
#        $ {
#        >     bsl_log 2 '' '' unfinished message ...
#        >     sleep 2 # or do something else ...
#        >     bsl_log 2 1 1 ' DONE'
#        > }
#        [INF] unfinished message ... DONE
#d#
# some more comments
bsl_log() {
    local lvl="${1:?need a log level (0..4)}"
    local prefix="${2:-}"
    local add_nl="${3:-1}"
    [ "${lvl}" -gt "${BSL_LOGLEVEL:-${BSL_LOGLEVEL_DEFAULT}}" ] && return 0
    # shellcheck disable=SC2015
    [ "${#}" -ge 3 ] && shift 3 || shift "${#}"

    local msg eol
    if [ -z "${prefix}" ]; then
        prefix="[${BSLL_LEVEL2SNAME[${lvl}]}]"
    elif [ "${prefix}" = '-' ]; then
        prefix=''
    elif [ "${prefix}" = ':f' ]; then
        prefix="[${BSLL_LEVEL2SNAME[${lvl}]}/${FUNCNAME[2]:-}]"
    else
        prefix="[${prefix}]"
    fi
    [ -z "${*}" ] || msg=" ${*}"
    [ -z "${add_nl}" ] || eol='\n'

    if [ "${lvl}" -lt 2 ]; then
        printf >&2 "${prefix}%b${eol}" "${msg}"
    else
        printf "${prefix}%b${eol}" "${msg}"
    fi

    # editorconfig-checker-disable
    [ "${BSLL_USE_LOGGER}" -eq 0 ] \
        || logger -p "${BSLL_LOGGER_FACILITY}.${BSLL_LEVEL2LOGGER_PRIO[${lvl}]}" "${msg}"
    # editorconfig-checker-enable

    return 0
}

# logging functions

bsl_loge() { bsl_log 0 '' 1 "${*}"; }
bsl_logw() { bsl_log 1 '' 1 "${*}"; }
bsl_logi() { bsl_log 2 '' 1 "${*}"; }
bsl_logd() { bsl_log 3 '' 1 "${*}"; }
bsl_logd2() { bsl_log 4 '' 1 "${*}"; }

# logging functions for use inside functions (with function name added to
# prefix)

bsl_logfe() { bsl_log 0 ':f' 1 "${*}"; }
bsl_logfw() { bsl_log 1 ':f' 1 "${*}"; }
bsl_logfi() { bsl_log 2 ':f' 1 "${*}"; }
bsl_logfd() { bsl_log 3 ':f' 1 "${*}"; }
bsl_logfd2() { bsl_log 4 ':f' 1 "${*}"; }

# log and return false (``1`` or user defined).

bsl_die() {
    local -i ret='1'
    [[ "${1}" != '-r' && ! "${1}" =~ ^--ret(urn)?$ ]] || {
        # use printf '%d' to make sure that ${2} is a valid integer, otherwise
        # reset to initial value of 1
        printf -v ret '%d' "${2}" 2>/dev/null || ret='1'
        shift 2
    }
    bsl_loge "${*}"
    return "${ret}"
}

# initialize logging
bsl_logging_init

##############################################
_bsl_finalize_lib
##############################################
