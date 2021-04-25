# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

EXTRA_DIST = .gitignore

pkgconfig_DATA =
lib_LTLIBRARIES =
noinst_LTLIBRARIES =
dist_vapi_DATA =
dist_include_HEADERS =
dist_noinst_HEADERS =
BUILT_SOURCES =

DISTCLEANFILES =
MAINTAINERCLEANFILES =

# === pkg-config ===

pkgconfig_DATA += \
	libwren-vala-@APIVER@.pc \
	$(EOL)

DISTCLEANFILES += $(pkgconfig_DATA)

# === Library, pass 1 ===
# The Vala files, as a convenience library.  This is to get the ordering
# right with respect to shim.c.

noinst_LTLIBRARIES += libinternal.la

wren_header = $(top_srcdir)/wren-pkg/wren/src/include/wren.h

libinternal_la_SOURCES = \
	$(vala_all_sources) \
	wren-vala-merged.h \
	$(wren_header) \
	$(EOL)

# XXX not robust against Automake changes
libinternal_stamp = $(srcdir)/libinternal_la_vala.stamp

# Make libinternal get built first.  That way $(generated_header) will exist
# when it's time to build shim.c.
BUILT_SOURCES += $(libinternal_stamp)

generated_header = $(srcdir)/wren-vala-generated.h
MAINTAINERCLEANFILES += $(generated_header)
dist_noinst_HEADERS += $(generated_header)

# valac makes wren-vala-generated.h.  At compile time,
# hand-made wren-vala-merged.h will pull in wren-vala-generated.h and wren.h.
libinternal_la_VALAFLAGS = \
	--library libinternal.so -H $(generated_header) \
	--vapi libwren-vala.vapi \
	$(AM_VALAFLAGS) \
	$(EOL)

libinternal_la_CFLAGS = \
	-I$(top_srcdir)/wren-pkg/wren/src/include \
	$(AM_CFLAGS) \
	$(EOL)

# === Library, pass 2 ===
# This is everything except the Vala files

lib_LTLIBRARIES += libwren-vala-@APIVER@.la

libwren_vala_@APIVER@_la_SOURCES = \
	$(c_all_sources) \
	$(EOL)

libwren_vala_@APIVER@_la_CFLAGS = \
	-I$(top_srcdir)/wren-pkg/wren/src/include \
	$(AM_CFLAGS) \
	$(EOL)

libwren_vala_@APIVER@_la_LIBADD = \
	libinternal.la \
	$(top_builddir)/wren-pkg/libwren-@APIVER@.la \
	$(EOL)

# === Installed header ===
# The client of this library uses a single header with everything in one.
# I make it by hand this way since I was having trouble getting Automake
# to cooperate.

header_for_installation = wren-vala-@APIVER@.h
DISTCLEANFILES += $(header_for_installation)

$(header_for_installation): $(generated_header) $(wren_header) Makefile.am
	$(AM_V_GEN)
	$(AM_V_at)echo "/* $@ generated at `date` */" > $@
	$(AM_V_at)perl -ne '$$shouldprint = 1../#include.+\bwren.*\.h/; print if $$shouldprint && $$shouldprint !~ /E0/' $(generated_header) >> $@
	$(AM_V_at)echo "/* inlining $(wren_header) */" >> $@
	$(AM_V_at)cat $(wren_header) >> $@
	$(AM_V_at)echo "/* end of inlined $(wren_header) */" >> $@
	$(AM_V_at)perl -ne 'print if $$shouldprint; $$shouldprint ||= /#include.+\bwren.*\.h/' $(generated_header) >> $@

# Inline Wren's header into the wren-vala header after we run valac
all-local: $(header_for_installation)

install-data-local: $(header_for_installation)
	$(MKDIR_P) "$(DESTDIR)$(includedir)"
	$(INSTALL_DATA) "$(header_for_installation)" "$(DESTDIR)$(includedir)"

# XXX not robust against automake changes
uninstall-local:
	files="$(header_for_installation)" ; \
		dir="$(DESTDIR)$(includedir)"; \
		$(am__uninstall_files_from_dir)

# === Installed vapi ===

# Before installing libwren-vala-@APIVER@.vapi, tack basics.vapi onto the end
# of it.  The compiler only writes the declarations from vm.vala into the vapi
# file, but the client needs basics.vapi as well.
# Also, change the cheader_filename in the vapi.
vapis_to_merge = $(srcdir)/libwren-vala.vapi basics.vapi
$(srcdir)/libwren-vala-@APIVER@.vapi: $(vapis_to_merge) Makefile.am $(libinternal_stamp)
	rm -f "$@"
	perl -pe 's/wren-vala-merged\.h/wren-vala-@APIVER@.h/g' $(vapis_to_merge) >> "$@"

dist_vapi_DATA += $(srcdir)/libwren-vala-@APIVER@.vapi
MAINTAINERCLEANFILES += $(srcdir)/libwren-vala-@APIVER@.vapi
