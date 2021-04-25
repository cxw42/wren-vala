# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

# common rules

# for convenience at the ends of lists
EOL =

# A convenient place to hold phony targets
.PHONY: $(phony)
phony =

# === Locations =========================================================

# From https://tecnocode.co.uk/2013/12/14/notes-on-vala-and-automake/
vapidir = $(datadir)/vala/vapi

# === Variables =========================================================

vala_all_sources = \
	$(top_srcdir)/src/basics.vapi \
	$(top_srcdir)/src/marshal.vala \
	$(top_srcdir)/src/trampoline.vala \
	$(top_srcdir)/src/util.vala \
	$(top_srcdir)/src/vm.vala \
	$(EOL)

c_all_sources = \
	$(top_srcdir)/src/myconfig.c \
	$(top_srcdir)/src/shim.c \
	$(EOL)

# Vala settings.
# - LOCAL_VALA_FLAGS is filled in by each Makefile.am with any other valac
#   options that Makefile.am needs.
# - TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
#   isn't being passed through.
AM_VALAFLAGS = \
	$(LOCAL_VALA_FLAGS) \
	$(MY_VALA_PKGS) \
	$(USER_VALAFLAGS) \
	$(EOL)

MY_VALA_PKGS = \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	$(EOL)

# C settings, which are the same throughout.  LOCAL_CFLAGS is filled in
# by each Makefile.am.
AM_CFLAGS = \
	-I$(top_srcdir)/wren-pkg -I$(top_builddir)/wren-pkg \
	$(LOCAL_CFLAGS) $(BASE_CFLAGS) \
	$(CODE_COVERAGE_CFLAGS) \
	$(EOL)

AM_CPPFLAGS = $(CODE_COVERAGE_CPPFLAGS)

# Libs.  $(LOCAL_LIBS) is added to $(LIBS) in configure.ac.
LOCAL_LIBS = $(BASE_LIBS) $(CODE_COVERAGE_LIBS)

# === Code coverage =====================================================

# For code coverage, per
# https://www.gnu.org/software/autoconf-archive/ax_code_coverage.html
clean-local: code-coverage-clean
distclean-local: code-coverage-dist-clean

CODE_COVERAGE_OUTPUT_FILE = $(PACKAGE_TARNAME)-coverage.info
CODE_COVERAGE_OUTPUT_DIRECTORY = $(PACKAGE_TARNAME)-coverage

include $(top_srcdir)/aminclude_static.am
