# Makefile.am --- build and install Wren itself.
# This Makefile.am is part of wren-vala
# https://github.com/cxw42/wren-vala
# Copyright (c) 2021 Christopher White
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

EXTRA_DIST = .gitignore

noinst_LTLIBRARIES =

# === Libraries =========================================================
# Do include all the optional features.
# TODO make the optional features configure-time options

noinst_LTLIBRARIES += \
	libwren-@APIVER@.la \
	$(EOL)

libwren_@APIVER@_la_CFLAGS = \
	-I$(srcdir)/wren/src/vm -I$(srcdir)/wren/src/optional \
	-I$(srcdir)/wren/src/include \
	$(AM_CFLAGS) \
	$(EOL)

# Sources.  Note that we list both our local copies of the headers and the
# Wren headers (wren/src/include/*).  The local copies depend on the Wren
# headers above.  This way everything gets disted and depped.
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
	$(EOL)

# --- Meta and Random ---

EXTRA_libwren_@APIVER@_la_SOURCES = \
	wren/src/optional/wren_opt_meta.c \
	wren/src/optional/wren_opt_meta.h \
	wren/src/optional/wren_opt_meta.wren.inc \
	wren/src/optional/wren_opt_random.c \
	wren/src/optional/wren_opt_random.h \
	wren/src/optional/wren_opt_random.wren.inc \
	$(EOL)

if USE_WREN_META
libwren_@APIVER@_la_SOURCES += \
	wren/src/optional/wren_opt_meta.c \
	wren/src/optional/wren_opt_meta.h \
	wren/src/optional/wren_opt_meta.wren.inc \
	$(EOL)
else
libwren_@APIVER@_la_CFLAGS += -DWREN_OPT_META=0
endif

if USE_WREN_RANDOM
libwren_@APIVER@_la_SOURCES += \
	wren/src/optional/wren_opt_random.c \
	wren/src/optional/wren_opt_random.h \
	wren/src/optional/wren_opt_random.wren.inc \
	$(EOL)
else
libwren_@APIVER@_la_CFLAGS += -DWREN_OPT_RANDOM=0
endif

# === Other Wren files ==================================================

EXTRA_DIST += \
	wren/AUTHORS \
	wren/CHANGELOG.md \
	wren/LICENSE \
	wren/README.md \
	wren/src/optional/wren_opt_meta.wren \
	wren/src/optional/wren_opt_random.wren \
	$(EOL)
