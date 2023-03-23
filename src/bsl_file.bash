#D# File related funtions.

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

#D#
# Minimal dirname in pure bash.
#
# Output NAME with its last non-slash component and trailing slashes removed; if
# NAME contains no /'s, output '.' (meaning the current directory).
#
# Args:
#     name (str): file/directory name
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: directory name
#
# Examples:
#
#     $ bsl_dirname /foo/bar
#     /foo
#
#     $ bsl_dirname foo/bar
#     foo
#
#     $ bsl_dirname foo/
#     foo
#
#     $ bsl_dirname foo
#     .
#
#     $ bsl_dirname
#     .
#d#
bsl_dirname() {
    local name="${1:-}"
    if [[ "${name}" =~ / ]]; then
        echo "${name%/*}"
    else
        echo .
    fi
}

#D#
# Minimal basename in pure bash.
#
# Print NAME with any leading directory components removed. If specified, also
# remove a trailing SUFFIX.
#
# Args:
#     name (str): file/directory name
#     suffix (str): extension to remove
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: file name without directory compoents (and, if provided, without
#         SUFFIX).
#
# Examples:
#
#     $ bsl_basename /foo/bar.baz
#     bar.baz
#
#     $ bsl_basename /foo/bar.baz/
#     bar.baz
#
#     $ bsl_basename /foo/bar.baz .baz
#     bar
#
#     $ bsl_basename /foo/bar.baz baz
#     bar.
#
#     $ bsl_basename foo/bar
#     bar
#
#     $ bsl_basename bar
#     bar
#
#     $ bsl_basename
#     # empty line
bsl_basename() {
    local name="${1:-}"
    local ext="${2:-}"

    [ "${name: -1:1}" != "/" ] || name="${name::-1}"
    [ -z "${ext}" ] || name="${name%"${ext}"}"
    echo "${name##*/}"
}

#D#
# Print extension of NAME.
#
# Print last dot (``.``) and following characters.
#
# Args:
#     name (str): file/directory name
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: extension of NAME
#
# Examples:
#
#     $ bsl_getext /foo/bar.baz
#     .baz
#
#     $ bsl_getext /foo/bar.baz/
#     .baz
#
#     $ bsl_getext /foo/bar.
#     .
#
#     $ bsl_getext .
#     .
#
#     $ bsl_getext /foo/bar
#     # empty string
#
#     $ bsl_getext bar
#     # empty string
#
#     $ bsl_getext
#     # empty string
bsl_getext() {
    local name="${1:-}"

    if [ -n "${name}" ]; then
        name="$(bsl_basename "${name}")"
        if [ "${name}" != "${name/./}" ]; then
            printf '%s' ".${name##*.}"
        fi
    fi
}

#D#
# Print NAME with last extension removed.
#
# Remove extension from NAME by stripping last dot (``.``) followed by anything.
#
# Args:
#     name (str): file/directory name
#
# Returns:
#     exit status: ``0`` in case of success, any other value indicates an error
#     stdout: file/directory name without (last) extension
#
# Examples:
#
#     $ bsl_stripext /foo/bar.baz
#     /foo/bar
#
#     $ bsl_stripext /foo/bar.
#     /foo/bar
#
#     $ bsl_stripext /foo/bar
#     /foo/bar
#
#     $ bsl_stripext bar
#     bar
#
#     $ bsl_stripext
#     # empty string
bsl_stripext() {
    local name="${1:-}"
    printf '%s' "${name%.*}"
}

##############################################
_bsl_finalize_lib
##############################################
