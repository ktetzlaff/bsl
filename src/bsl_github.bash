# Github related functions

#L#
# Copyright (C) 2023 ktetzlaff <bsl@tetzco.de>
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
# github related functions
##############################################

#D# Retrieve github API releases JSON.
#
# Examples:
#
# #. Get JSON for latest release of got-gitea/gitea::
#
#   $ bsl_ghapi_releases 'go-gitea' 'gitea' 'latest'
#
# Args:
#     owner (str): Owner of the repository.
#     repo (str): Repository name.
#     tag (str): Release tag (default: 'latest').
#
# Returns:
#     exit status (int): ``0`` in case of success, any other value indicates an
#         error
#
#     stdout (str): Releases JSON.
bsl_ghapi_releases() {
    local owner="${1}"
    local repo="${2}"
    local tag="${3:-latest}"

    local url="https://api.github.com/repos/${owner}/${repo}/releases"
    if [ "${tag}" = "latest" ]; then
        url="${url}/${tag}"
    elif [ -n "${tag}" ]; then
        url="${url}/tags/${tag}"
    fi
    curl -qsL "${url}"
}

#D# Retrieve github API tag of latest release.
#
# Examples:
#
# #. Get JSON for latest release of got-gitea/gitea::
#
#   $ bsl_ghapi_releases_tag_latest 'go-gitea' 'gitea'
#   v1.18.5
#
# Args:
#     owner (str): Owner of the repository.
#     repo (str): Repository name.
#
# Returns:
#     exit status (int): ``0`` in case of success, any other value indicates an
#         error
#
#     stdout (str): Releases JSON.
bsl_ghapi_releases_tag_latest() {
    local owner="${1}"
    local repo="${2}"

    bsl_ghapi_releases "${owner}" "${repo}" 'latest' \
        | jq -r '.tag_name'
}

##############################################
_bsl_finalize_lib
##############################################
