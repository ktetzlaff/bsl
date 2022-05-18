#D# BSL version information

#D# BSL version number.
BSL_VERSION='0.0.5'

# -----END PYTHON----- - DO NOT MODIFY THIS LINE!

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
declare -f _bsl_init_lib >/dev/null || source "${BSL_PATH}/init.bash"
_bsl_init_lib || return 0

# Note: In addition to being sourced by bash, the beginning of this file up to
# the END PYTHON line above is imported as python module when building the BSL
# documentation. So make sure to use python compatible syntax (i.e. just define
# simple variables).

#D# Show BSL related information.
bsl_status() {
    while [ "${#*}" -gt 0 ]; do
        case "${1}" in
            -V | --version)
                echo "${BSL_VERSION}"
                return 0
                ;;
            *)
                : # no action required
                ;;
        esac
        shift
    done

    cat <<-EOF
BSL version: '${BSL_VERSION}'
Loaded from: '${BSL_PATH}'
EOF
}
alias bsl_info='bsl_status'
alias bsl_version='bsl_status --version'

##############################################
_bsl_finalize_lib
##############################################
