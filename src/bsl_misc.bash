#D# Miscellaneous variables/functions.

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

[ "${_BSL_MISC:-0}" -eq 1 ] && return 0 || _BSL_MISC=1
[ "${BSL_INC_DEBUG:=0}" -lt 1 ] || echo "sources: ${BASH_SOURCE[*]}"

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "${BSL_PATH}/bsl_logging.bash"

##############################################
# variables
##############################################
if [ -e /dev/null ]; then
    DEVNULL='/dev/null'
else
    # windows :-(
    DEVNULL='nul'
fi

##############################################
# misc. functions
##############################################

bsl_stdin_to_log() {
    local log_fn="${1:-bsl_logi}"
    read -r -d '' lines || true
    "${log_fn}" "${lines}"
}

bsl_stdin_to_file() {
    local dst="${1:-}"
    local mode="${2:-append}"
    read -r -d '' lines || true

    if [[ -v _DRY_RUN || -z "${dst}" ]]; then
        exec {dst}>&1
    else
        if [ "${mode}" = "replace" ]; then
            exec {dst}>"${dst}"
        else
            exec {dst}>>"${dst}"
        fi
    fi
    echo -e "${lines}" >&"${dst}"
    exec {dst}>&-
}

bsl_has_cmd() {
    bsl_run_cmd_quiet type -p "${1}"
}

bsl_run_cmd() {
    if [ -v _DRY_RUN ]; then
        bsl_logi "${FUNCNAME[0]}, skip: '${*}'"
    else
        "${@}"
    fi
}

bsl_run_cmd_logged() {
    bsl_logd "${FUNCNAME[0]}, cmd: '${*}'"
    bsl_run_cmd "${@}"
}

bsl_run_cmd_nostdout() {
    "${@}" >"${DEVNULL}"
}

bsl_run_cmd_nostderr() {
    "${@}" 2>"${DEVNULL}"
}

bsl_run_cmd_quiet() {
    "${@}" &>"${DEVNULL}"
}

bsl_with_shopt() {
    IFS=' ,;:' read -ra opts <<<"${1}"
    shift

    local opts_saved=() o s
    for o in "${opts[@]}"; do
        s="$(shopt -p "${o}" 2>&- || shopt -op "${o}" 2>&-)"
        #echo "saved: '${s}'"
        opts_saved+=("${s}")
        shopt -qs "${o}" 2>&- || shopt -qo "${o}" 2>&-
    done
    "${@}"
    # local IFS='|'
    # echo -e "restore: '${opts_saved[@]}'"
    for o in "${opts_saved[@]}"; do
        eval "${o}"
    done
}

bsl_with_dir() {
    local dir="${1}"
    shift
    pushd "${dir}" &>"${DEVNULL}" || return "${?}"
    "${@}"
    popd &>"${DEVNULL}" || true
}

bsl_create_backup_file() {
    local src="${1}"
    local ext="${2:-.bckp}"

    local dst="${src}${ext}"
    local cmd=()
    bsl_logd "create backup: '${dst}'"
    bsl_run_cmd cp -a "${src}" "${dst}"
}

bsl_create_link() {
    bsl_logd "fn:${FUNCNAME[0]}: ${*}"

    local cmd=(
        'ln' '-s'
    )
    local backup=0
    local positional=()
    local src dst

    while [[ "${#}" -gt 0 ]]; do
        case "${1}" in
            --backup | -b)
                backup=1
                shift
                ;;
            *)
                positional+=("${1}")
                shift
                ;;
        esac
    done

    if [ "${#positional[@]}" -ne 2 ]; then
        bsl_loge "${FUNCNAME[0]}: requires 2 positional arguments, got ${#positional[*]}"
        return 1
    fi
    src="${positional[0]}"
    dst="${positional[1]}"
    # bsl_logd "src=${src}"
    # bsl_logd "dst=${dst}"

    if [ ! -e "${src}" ]; then
        bsl_loge "${FUNCNAME[0]}: src does not exist: '${src}'"
        return 2
    elif [ -L "${dst}" ]; then
        local lnk
        lnk="$(readlink "${dst}")"
        if [ "${src}" = "${lnk}" ]; then
            bsl_logi "link already exists: '${dst}' -> '${src}'"
            return 0
        elif [ ! -e "$(lnk)" ] && [ ! -L "$(lnk)" ]; then
            local backup="${dst}.qnap"
            bsl_logi "backup: '${dst}' -> '${backup}' ..."
            mv "${dst}" "${backup}"
        fi
    elif [ -e "${dst}" ]; then
        if diff -qr "${src}" "${dst}" >"${DEVNULL}"; then
            bsl_logi "no change needed: '${dst}'"
            return 0
        elif [ "${backup}" -eq 1 ]; then
            local backup="${dst}.qnap"
            bsl_logi "backup: '${dst}' -> '${backup}' ..."
            mv "${dst}" "${backup}"
        else
            bsl_loge "${FUNCNAME[0]}: dst already exists: '${dst}'"
            bsl_logd "src='${src}', dst='${dst}'"
            return 3
        fi
    fi

    bsl_logi "create link: '${dst}' -> '${src}' ..."
    "${cmd[@]}" "${src}" "${dst}"
    return 0
}

bsl_update_file() {
    bsl_logd "fn:${FUNCNAME[0]}: ${*}"
    local src="${1}"
    local dst="${2}"

    if ! diff -qr "${src}" "${dst}" >"${DEVNULL}"; then
        if [ -e "${dst}" ]; then
            local backup="${dst}.qnap"
            bsl_logi "backup: '${dst}' -> '${backup}' ..."
            mv "${dst}" "${backup}"
        fi
        bsl_logi "update ${dst} ..."
        cp "${src}" "${dst}"
    else
        bsl_logi "no update needed: '${dst}'"
    fi
    return 0
}

bsl_hostname() {
    { bsl_run_cmd_nostderr hostname || uname -n || echo "${HOSTNAME}"; } | cut -d. -f1
}

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
