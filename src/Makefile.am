# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

EXTRA_DIST = .gitignore

pkgconfig_DATA =
lib_LTLIBRARIES =
dist_vapi_DATA =
include_HEADERS =

# === pkg-config ===

pkgconfig_DATA += \
	libwren-vala-@APIVER@.pc \
	$(EOL)

DISTCLEANFILES = $(pkgconfig_DATA)

# === Library ===

lib_LTLIBRARIES += libwren-vala.la

libwren_vala_la_SOURCES = \
	basics.vapi \
	marshal.vala \
	myconfig.vapi \
	trampoline.vala \
	vm.vala \
	wrennull.c \
	$(EOL)

libwren_vala_la_LIBADD = \
	$(top_builddir)/wren-pkg/libwren-@APIVER@.la \
	$(EOL)

libwren_vala_la_VALAFLAGS = \
	--library libwren-vala-@APIVER@.so -H libwren-vala-@APIVER@.h \
	--vapi libwren-vala.vapi \
	$(AM_VALAFLAGS) \
	$(EOL)

# === vapi and header ===

# Before installing libwren-vala-@APIVER@.vapi, tack basics.vapi onto the end
# of it.  The compiler only writes the declarations from vm.vala into the vapi
# file, but the client needs basics.vapi as well.
libwren-vala-@APIVER@.vapi: libwren-vala.vapi basics.vapi
	cat $^ > $@

dist_vapi_DATA += libwren-vala-@APIVER@.vapi
DISTCLEANFILES += libwren-vala-@APIVER@.vapi
include_HEADERS += libwren-vala-@APIVER@.h
