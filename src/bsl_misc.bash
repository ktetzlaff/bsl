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

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
declare -f _bsl_init_lib >/dev/null || source "${BSL_PATH}/init.bash"
_bsl_init_lib || return 0

bsl_load_lib 'bsl_logging'

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

    local lines
    read -r -d '' lines || true
    "${log_fn}" "${lines}"
}

bsl_stdin_to_file() {
    local dst="${1:-}" mode="${2:-append}"

    local lines
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

bsl_run_cmd() {
    if [ -v _DRY_RUN ]; then
        bsl_logfi "skip: '${*}'"
    else
        "${@}"
    fi
}

bsl_run_cmd_logged() {
    bsl_logfd "cmd: '${*}'"
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

#D# Run command while catching stdtout and stderr into (nameref) variables.
#
# Args:
#     stdout (str, nameref): variable name for stdout
#
#     stderr (str, nameref): variable name for stderr
#
#     cmd (str): command to be run
#
#     &args (str): args for `command`
#
# Returns:
#     exit status: ```` in case of success, any other value indicates an error
#     stdout: na
#d#
bsl_run_cmd_catch_stdouterr() {
    local -n __stdout__="${1}" __stderr__="${2}"
    {
        IFS=$'\n' read -r -d '' __stdout__;
        IFS=$'\n' read -r -d '' __stderr__;
        (IFS=$'\n' read -r -d '' __exit__; return "${__exit__}");
    } < <((printf '\0%s\0%d\0' "$(((({ shift 2; "${@}"; echo "${?}" 1>&3-; } | tr -d '\0' 1>&4-) 4>&2- 2>&1- | tr -d '\0' 1>&4-) 3>&1- | exit "$(cat)") 4>&1-)" "${?}" 1>&2) 2>&1)
}

bsl_has_cmd() {
    bsl_run_cmd_quiet command -v "${1}"
}

bsl_with_shopt() {
    local -a opts
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
    bsl_logfd "${*}"

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
        # editorconfig-checker-disable
        bsl_logfe "requires 2 positional arguments, got ${#positional[*]}"
        # editorconfig-checker-enable
        return 1
    fi
    src="${positional[0]}"
    dst="${positional[1]}"
    # bsl_logd "src=${src}"
    # bsl_logd "dst=${dst}"

    if [ ! -e "${src}" ]; then
        bsl_logfe "src does not exist: '${src}'"
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
            bsl_logfe "dst already exists: '${dst}'"
            bsl_logd "src='${src}', dst='${dst}'"
            return 3
        fi
    fi

    bsl_logi "create link: '${dst}' -> '${src}' ..."
    "${cmd[@]}" "${src}" "${dst}"
    return 0
}

bsl_update_file() {
    bsl_logfd "${*}"
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
    {
        bsl_run_cmd_nostderr hostname uname -n echo "${HOSTNAME}"
    } | cut -d. -f1
}

#D#
# Output current or user defined ISO8691 timestamp to stdout.
#
# The resolution is seconds.
#
# Args:
#     unix_time (float): unix time (default: now)
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: ISO8601 formatted timestamp with second resolution
#
# Examples:
#   #. Current timestamp::
#
#        $ bsl_timestamp
#        20220804T180821
#
#   #. User defined timestamp (unix time/epoch)::
#
#        $ bsl_timestamp 123.456
#        20220804T180914
#
#      Note that any decimal places get ignored.
#d#
bsl_timestamp() {
    # use default -1 (= now)
    printf '%(%Y%m%dT%H%M%S)T' "${1:--1}"
}

#D#
# Output microsecond ISO8601 timestamp to stdout.
#
# If a user defined timestamp is used, the decimal places must be provided using
# full 6 digits (corresponding to the number of microseconds). The
# implementation could avoid that by using the external date executable.
# However, that would result in a considerable decrease in performance.
#
# Args:
#     unix_time (float): unix time with microsecond resolution (default: now)
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: ISO8601 formatted timestamp with microsecond resolution
#
# Examples:
#   #. Current timestamp::
#
#        $ bsl_timestamp_us
#        20220805T150602.498229
#
#   #. User defined timestamp (unix time/epoch)::
#
#        $ bsl_timestamp_us 123.456000
#        20220804T180914.456000
#
#      Note that decimal places for microseconds resolution must be provided
#      with full 6 digits.
#d#
bsl_timestamp_us() {
    local unix_time="${1:-${EPOCHREALTIME}}"
    # shellcheck disable=SC2086
    printf '%(%Y%m%dT%H%M%S)T.%06.0f' ${unix_time/./ }
}

##############################################
_bsl_finalize_lib
##############################################
