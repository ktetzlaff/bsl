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

#################################################
# generate a help message from the default target
#################################################

help:
	@echo 'Targets:'
	@echo '- help:    prints this help message'
	@echo '- format:  show source formatting issues (using `shfmt`)'
	@echo '- test:    runs the (unit) tests'
	@echo '- lint:    run linters (running `github/super-linter` via docker)'
	@echo '- install: install src/*.bash to <PREFIX>/lib/bash/'
	@echo '      Example: PREFIX=$${HOME}/.local make install'

#################################################
# update GNU make built-in defaults
#################################################

# disable built-in rules, variables, ...
MAKEFLAGS += --no-builtin-rules --no-builtin-variables
SUFFIXES:
# warn in case of undefined variables
MAKEFLAGS += --warn-undefined-variables
# use bash as SHELL
SHELL := bash
# stop on errors, undefined variables and errors in pipes
.SHELLFLAGS := -eu -o pipefail -c
# use one shell invocation per recipe (instead of one per line)
.ONESHELL:

#################################################
# define helper vars
#################################################

# define the $(sp) macro which has the value ' '
ifndef blank
    blank := # editorconfig-checker-disable
endif
ifndef sp
    sp := $(blank) $(blank) # editorconfig-checker-disable
endif

#################################################
# variables used by our targets
#################################################

# define variable for the repository root
REPO_ROOT := $(subst $(sp),?,$(abspath .))

# variable used for install target
PREFIX ?= /usr/local
LIB_DIR := $(PREFIX)/lib/bash/bsl

# variables used for test targets
BSLBATS_BASE_DIR ?= $(REPO_ROOT)/.bats
export BSLBATS_BASE_DIR

BSLBATS_CORE_VER ?= v1.6.0-52-g5c964bb
BSLBATS_CORE_DIR ?= $(BSLBATS_BASE_DIR)/bats-core

BSLBATS_SUPPORT_VER ?= v0.3.0-11-g3c8fadc
BSLBATS_SUPPORT_DIR ?= $(BSLBATS_BASE_DIR)/bats-support

BSLBATS_ASSERT_VER ?= v2.0.0-58-g397c735
BSLBATS_ASSERT_DIR ?= $(BSLBATS_BASE_DIR)/bats-assert

BSLBATS_CORE_INSTALL ?= $(BSLBATS_CORE_DIR)/install.sh

BSLBATS_CORE_INSTALL ?= $(BSLBATS_CORE_DIR)/install.sh

BATS         := $(BSLBATS_BASE_DIR)/bin/bats
BATS_SUPPORT := $(BSLBATS_SUPPORT_DIR)/load.bash
BATS_ASSERT  := $(BSLBATS_ASSERT_DIR)/load.bash

BSLBATS_GITHUB := https://github.com/bats-core

# flags/options passed to the bats unit test tool
BATS_EXTRA_FLAGS ?=
BATS_FLAGS       := $(BATS_EXTRA_FLAGS)

#################################################
# define actual targets
#################################################

.PHONY: help format test lint install _bats_all

format:
	shfmt -d src test

BSLBATS_CORE_FILES :=\
    $(BSLBATS_CORE_INSTALL)\
    $(wildcard $(BSLBATS_CORE_DIR)/bin/*)\
    $(wildcard $(BSLBATS_CORE_DIR)/lib/bats-core/*)\
    $(wildcard $(BSLBATS_CORE_DIR)/libexec/bats-core/*)

$(subst $(sp),?,$(BSLBATS_CORE_INSTALL)):
	[ -d '$(@D)' ] || git clone '$(BSLBATS_GITHUB)/bats-core.git' '$(@D)'

$(subst $(REPO_ROOT),%,$(BATS)): $(subst $(REPO_ROOT),%,$(BSLBATS_CORE_FILES))
	'$(<)' '$(dir $(@D))'

$(subst $(REPO_ROOT),%,$(BATS_SUPPORT)):
	git clone '$(BSLBATS_GITHUB)/bats-support.git' '$(@D)'

$(subst $(REPO_ROOT),%,$(BATS_ASSERT)):
	git clone '$(BSLBATS_GITHUB)/bats-assert.git' '$(@D)'

_bats_core: $(subst $(sp),?,$(BATS) $(BSLBATS_CORE_INSTALL))
_bats_support: $(subst $(sp),?,$(BATS_SUPPORT))
_bats_assert: $(subst $(sp),?,$(BATS_ASSERT))

_bats_all: _bats_core _bats_support _bats_assert

define git_switch_branch
    BRANCH="$$(git -C '$(1)' branch --show-current)"; \
    [ "$${BRANCH}" = "$(2)" ] || { \
        echo "switching branch in '$$(basename $(1))': '$${BRANCH}'->'$(2)'"; \
        git -C '$(1)' fetch --all >/dev/null; \
        git -C '$(1)' switch -C '$(2)' '$(2)' || { \
            echo "[ERR] failed to switch branch, repo: '$(1)', branch: '$(2)'"; \
            return 1; \
        }; \
        [ -z '$(3)' ] || '$(BSLBATS_CORE_INSTALL)' '$(BSLBATS_BASE_DIR)'; \
    }
endef

define bslbats_switch_branches
    $(call git_switch_branch,$(BSLBATS_CORE_DIR),$(BSLBATS_CORE_VER),install)
    $(call git_switch_branch,$(BSLBATS_SUPPORT_DIR),$(BSLBATS_SUPPORT_VER),)
    $(call git_switch_branch,$(BSLBATS_ASSERT_DIR),$(BSLBATS_ASSERT_VER),)
endef

test: _bats_all
	@$(call bslbats_switch_branches)
	'$(BATS)' $(BATS_FLAGS) $(@)

test/%: _bats_all
	@$(call bslbats_switch_branches)
	'$(BATS)' $(BATS_FLAGS) '$(@)'

lint:
	docker run \
		-e RUN_LOCAL=true \
		-e VALIDATE_BASH_EXEC=false \
		-e FILTER_REGEX_EXCLUDE='.*/(test/.*\.bats|LICENSE)' \
		-v "$${PWD}:/tmp/lint" \
		github/super-linter

install:
	install -vpDt '$(LIB_DIR)' --mode=u=rwX,g=rX,o=rX '$(REPO_ROOT)/src/'*.bash
