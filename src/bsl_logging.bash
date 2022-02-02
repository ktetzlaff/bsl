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
# logging functions
##############################################
bsl_log() {
    local lvl="${1}"
    shift
    local msg="[${lvl}]"
    if [ -n "${*}" ]; then
        msg="${msg} ${*}"
    fi
    echo "${msg}"
    logger "${msg}"
}

bsl_loge() { >&2 bsl_log "ERR" "${*}"; }
bsl_logw() { >&2 bsl_log "WRN" "${*}"; }
bsl_logi() {     bsl_log "INF" "${*}"; }
bsl_logd() { if [ "${BSL_DEBUG:-0}" -gt 0 ]; then bsl_log "DBG" "${*}"; fi; }
bsl_die()  { bsl_loge "${*}"; return 1; }

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
