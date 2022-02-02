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

[ "${_BSL_LOGGING:-0}" -eq 1 ] && return 0 || _BSL_LOGGING=1
[ "${BSL_INC_DEBUG:=0}" -lt 1 ] || echo "sources: ${BASH_SOURCE[*]}"

##############################################
# logging variables
##############################################

# Note: The seemingly redundant/unnecessary -g(lobal) option in the following
# declare statements is required by the (BATS) unit tests.

declare -ga BSLL_LEVEL2SNAME=(
    "ERR"
    "WRN"
    "INF"
    "DBG"
    "DB2"
)

declare -ga BSLL_LEVEL2LOGGER_PRIO=(
    "error"
    "warning"
    "info"
    "debug"
    "debug"
)

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

[ -v BSL_LOGLEVEL_DEFAULT ] || declare -gir BSL_LOGLEVEL_DEFAULT=2

declare -gi BSL_LOGLEVEL=${BSL_LOGLEVEL_DEFAULT}

declare -gi BSLL_USE_LOGGER=0
BSLL_LOGGER_FACILITY='user'

##############################################
# logging functions
##############################################
bsl_log() {
    local lvl="${1:?need a log level (0..4)}"
    local skip_prefix="${2:-}"
    local add_nl="${3:-1}"
    [ "${lvl}" -gt "${BSL_LOGLEVEL:-${BSL_LOGLEVEL_DEFAULT}}" ] && return 0
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

    [ "${BSLL_USE_LOGGER}" -eq 0 ] \
        || logger -p "${BSLL_LOGGER_FACILITY}.${BSLL_LEVEL2LOGGER_PRIO[${lvl}]}" "${msg}"

    return 0
}

bsl_loge()  { bsl_log 0 '' 1 "${*}"; }
bsl_logw()  { bsl_log 1 '' 1 "${*}"; }
bsl_logi()  { bsl_log 2 '' 1 "${*}"; }
bsl_logd()  { bsl_log 3 '' 1 "${*}"; }
bsl_logd2() { bsl_log 4 '' 1 "${*}"; }
bsl_die()   { bsl_loge "${*}"; return 1; }

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
