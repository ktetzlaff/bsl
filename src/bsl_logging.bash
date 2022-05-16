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
# logging variables
##############################################

# Note: The seemingly redundant/unnecessary -g(lobal) option in the following
# declare statements is required by the (BATS) unit tests.

#D# Map human readable, 3 character level string to numeric log level.
declare -ga BSLL_LEVEL2SNAME=(
    "ERR"
    "WRN"
    "INF"
    "DBG"
    "DB2"
)

#D# Map `logger` (*syslog*) priority to numeric log level.
declare -ga BSLL_LEVEL2LOGGER_PRIO=(
    "error"
    "warning"
    "info"
    "debug"
    "debug"
)

#D# Map numeric log level to human readable name.
# shellcheck disable=SC2034
declare -gA BSLL_NAME2LEVEL=(
    ["ERR"]="0"
    ["WRN"]="1"
    ["INF"]="2"
    ["DBG"]="3"
    ["DB2"]="4"

    ["ERROR"]="0"
    ["WARNING"]="1"
    ["INFO"]="2"
    ["DEBUG"]="3"
    ["DEBUG2"]="4"

    ["error"]="0"
    ["warning"]="1"
    ["info"]="2"
    ["debug"]="3"
    ["debug2"]="4"
)

#D# Default log level (int) to be used to initialize *BSL_LOGLEVEL*.
[ -v BSL_LOGLEVEL_DEFAULT ] || declare -gir BSL_LOGLEVEL_DEFAULT=2

#D# Log level (int) used by *BSL* logging functions (default= ``2``/``INFO`` ).
declare -gi BSL_LOGLEVEL=${BSL_LOGLEVEL_DEFAULT}

#D# Flag (bool) which controls if log messages are sent to *syslog* via
# ``logger`` cmd (default= ``0`` ). #d#
declare -gi BSLL_USE_LOGGER=0
#D# Facility used when logging via `logger` (default= ``user`` ).
BSLL_LOGGER_FACILITY='user'

##############################################
# logging functions
##############################################

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
#     skip_prefix (bool): if non-empty, don't add level prefix to current
#                         message
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
    local skip_prefix="${2:-}"
    local add_nl="${3:-1}"
    [ "${lvl}" -gt "${BSL_LOGLEVEL:-${BSL_LOGLEVEL_DEFAULT}}" ] && return 0
    # shellcheck disable=SC2015
    [ "${#}" -ge 3 ] && shift 3 || shift "${#}"

    local prefix msg eol
    [ -n "${skip_prefix}" ] || prefix="[${BSLL_LEVEL2SNAME[${lvl}]}]"
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

bsl_loge() { bsl_log 0 '' 1 "${*}"; }
bsl_logw() { bsl_log 1 '' 1 "${*}"; }
bsl_logi() { bsl_log 2 '' 1 "${*}"; }
bsl_logd() { bsl_log 3 '' 1 "${*}"; }
bsl_logd2() { bsl_log 4 '' 1 "${*}"; }

bsl_die() {
    bsl_loge "${*}"
    return 1
}

##############################################
_bsl_finalize_lib
##############################################
