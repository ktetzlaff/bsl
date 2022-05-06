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
	@echo 'Targets:'
	@echo '- help:    prints this help message'
	@echo '- format:  show source formatting issues (using `shfmt`)'
	@echo '- test:    runs the (unit) tests'
	@echo '- lint:    run linters (running `github/super-linter` via docker)'
	@echo '- install: install src/*.bash to <PREFIX>/lib/bash/'
	@echo '      Example: PREFIX=$${HOME}/.local make install'

# define the $(sp) macro which has the value ' '
ifndef blank
    blank := # editorconfig-checker-disable
endif
ifndef sp
    sp := $(blank) $(blank) # editorconfig-checker-disable
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

.PHONY: help format test lint install _bats_all

format:
	shfmt -d src test

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

lint:
	docker run \
	    -e RUN_LOCAL=true \
	    -e VALIDATE_BASH_EXEC=false \
	    -e FILTER_REGEX_EXCLUDE='.*/(test/.*\.bats|LICENSE)' \
	    -v "$${PWD}:/tmp/lint" \
	    github/super-linter

install:
	install -vpDt '$(LIB_DIR)' --mode=u=rwX,g=rX,o=rX '$(REPO_ROOT)/src/'*.bash
