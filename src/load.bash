#D# Load BSL libs.

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

[ "${BSL_INC_DEBUG:=0}" -lt 1 ] || echo "sources: ${BASH_SOURCE[*]}"

[ -v BSL_PATH ] || BSL_PATH="$(dirname "${BASH_SOURCE[0]}")"
source "${BSL_PATH}/bsl_logging.bash"
source "${BSL_PATH}/bsl_string.bash"
source "${BSL_PATH}/bsl_path.bash"
source "${BSL_PATH}/bsl_misc.bash"

##############################################
# end
##############################################
[ "${BSL_INC_DEBUG}" -lt 1 ] || echo "end: ${BASH_SOURCE[0]}"
