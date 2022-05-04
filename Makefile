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

help:
	@echo "Commands/Targets:"
	@echo "- PREFIX=<PREFIX> make install: install src/*.bash to <PREFIX>/lib/bash/"
	@echo "- make test: runs the (unit) tests"
	@echo "- make help: prints this help message"

# define the $(sp) macro which has the value ' '
ifndef blank
  blank :=
endif
ifndef sp
  sp := $(blank) $(blank)
endif

REPO_ROOT := $(subst $(sp),?,$(abspath .))

# variable used for install target
PREFIX ?= /usr/local
LIB_DIR := $(PREFIX)/lib/bash/bsl

# variables used for test targets
BSLBATS_BASE_DIR    ?= $(REPO_ROOT)/.bats

BSLBATS_CORE_VER     ?= v1.5.0-83-ga2fe397
BSLBATS_CORE_DIR     ?= $(BSLBATS_BASE_DIR)/bats-core
BSLBATS_CORE_INSTALL ?= $(BSLBATS_CORE_DIR)/install.sh

BSLBATS_SUPPORT_VER ?= v0.3.0-7-g4761373
BSLBATS_SUPPORT_DIR ?= $(BSLBATS_BASE_DIR)/bats-support

BSLBATS_ASSERT_VER ?= v2.0.0-49-g4bdd58d
BSLBATS_ASSERT_DIR ?= $(BSLBATS_BASE_DIR)/bats-assert

BSLBATS_GITHUB := https://github.com/bats-core

BATS         := $(BSLBATS_BASE_DIR)/bin/bats
BATS_SUPPORT := $(BSLBATS_SUPPORT_DIR)/load.bash
BATS_ASSERT  := $(BSLBATS_ASSERT_DIR)/load.bash

export BSLBATS_BASE_DIR

.PHONY: install test help _bats_all

install:
	install -vpDt '$(LIB_DIR)' --mode=u=rwX,g=rX,o=rX '$(REPO_ROOT)/src/'*.bash

$(BSLBATS_CORE_INSTALL):
	git clone '$(BSLBATS_GITHUB)/bats-core.git' $(@D)
	git -C $(@D) switch -c '$(BSLBATS_CORE_VER)' '$(BSLBATS_CORE_VER)'

$(BATS): $(BSLBATS_CORE_INSTALL)
	$(<) $(dir $(@D))

$(BATS_SUPPORT):
	git clone '$(BSLBATS_GITHUB)/bats-support.git' $(@D)
	git -C $(@D) switch -c '$(BSLBATS_SUPPORT_VER)' '$(BSLBATS_SUPPORT_VER)'

$(BATS_ASSERT):
	git clone '$(BSLBATS_GITHUB)/bats-assert.git' $(@D)
	git -C $(@D) switch -c '$(BSLBATS_ASSERT_VER)' '$(BSLBATS_ASSERT_VER)'

_bats_assert: $(BATS_ASSERT)
_bats_support: $(BATS_SUPPORT)
_bats_core: $(BATS)

_bats_all: _bats_core _bats_support _bats_assert

test: _bats_all
	@$(BATS) $(@)

test/%: _bats_all
	@$(BATS) $(@)
