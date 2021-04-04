# Makefile.am --- build and install Wren itself.
# This Makefile.am is part of wren-vala
# https://github.com/cxw42/wren-vala
# Copyright (c) 2021 Christopher White
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

EXTRA_DIST = .gitignore

include_HEADERS =
lib_LTLIBRARIES =

# === Headers ===========================================================

include_HEADERS += \
	wren-${APIVER}.h \
	wren-${APIVER}.hpp \
	$(EOL)

wren-${APIVER}.h: wren/src/include/wren.h
	cp "$<" "$@"

wren-${APIVER}.hpp: wren/src/include/wren.hpp
	cp "$<" "$@"

CLEANFILES = \
	wren-${APIVER}.h \
	wren-${APIVER}.hpp \
	$(EOL)

# === Libraries =========================================================
# Do include all the optional features.

lib_LTLIBRARIES += \
	libwren-@APIVER@.la \
	$(EOL)

libwren_@APIVER@_la_CFLAGS = \
	-I$(srcdir)/wren/src/vm -I$(srcdir)/wren/src/optional \
	-I$(srcdir)/wren/src/include \
	$(AM_CFLAGS) \
	$(EOL)

libwren_@APIVER@_la_SOURCES = \
	wren/src/include/wren.h \
	wren/src/include/wren.hpp \
	wren/src/vm/wren_common.h \
	wren/src/vm/wren_compiler.c \
	wren/src/vm/wren_compiler.h \
	wren/src/vm/wren_core.c \
	wren/src/vm/wren_core.h \
	wren/src/vm/wren_core.wren.inc \
	wren/src/vm/wren_debug.c \
	wren/src/vm/wren_debug.h \
	wren/src/vm/wren_math.h \
	wren/src/vm/wren_opcodes.h \
	wren/src/vm/wren_primitive.c \
	wren/src/vm/wren_primitive.h \
	wren/src/vm/wren_utils.c \
	wren/src/vm/wren_utils.h \
	wren/src/vm/wren_value.c \
	wren/src/vm/wren_value.h \
	wren/src/vm/wren_vm.c \
	wren/src/vm/wren_vm.h \
	wren/src/optional/wren_opt_meta.c \
	wren/src/optional/wren_opt_meta.h \
	wren/src/optional/wren_opt_meta.wren.inc \
	wren/src/optional/wren_opt_random.c \
	wren/src/optional/wren_opt_random.h \
	wren/src/optional/wren_opt_random.wren.inc \
	$(EOL)

# === Other Wren files ==================================================

EXTRA_DIST += \
	wren/AUTHORS \
	wren/CHANGELOG.md \
	wren/LICENSE \
	wren/README.md \
	$(EOL)
