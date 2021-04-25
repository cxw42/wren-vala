# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

EXTRA_DIST += .gitignore

phony += build-tests
build-tests: $(check_PROGRAMS)

# Tests themselves: executables ending in -t, and scripts ending in -t.sh
test_programs =
dist_test_scripts =

# Support programs: executables ending in -s, and scripts ending in -s.sh
test_extra_programs =
dist_test_extra_scripts =

# So we don't have to list the sources of every test program individually
AM_DEFAULT_SOURCE_EXT = .vala
# But that messes up the linker selection, so:
CCLD = $(CXX)

# --- Flags ---

LOCAL_VALA_FLAGS = \
	--vapidir $(top_srcdir)/src \
	--vapidir $(top_builddir)/src \
	--pkg libwren-vala-@APIVER@ \
	$(EOL)

# XXX: the json-glib is just for serializing values when debugging
# --pkg json-glib-1.0

LOCAL_CFLAGS = \
	-I $(top_srcdir)/src \
	-I $(top_builddir)/src \
	$(EOL)
# XXX $(shell pkg-config --cflags json-glib-1.0)

AM_LDFLAGS = \
	$(EOL)
# XXX $(shell pkg-config --libs json-glib-1.0)

# Libs: -lwren is in LIBS, which is included by default.
LDADD = \
	-L$(top_builddir)/src \
	-lwren-vala-@APIVER@ \
	$(EOL)

# --- Test definitions ---

# When you add files here, also add them to the list in the `prettyprint` target
test_programs += \
	000-sanity-t \
	090-util-t \
	100-vmv-t \
	105-tramp-t \
	120-read-var-from-wren-t \
	130-call-wren-t \
	140-roundtrip-data-t \
	150-marshal-t \
	200-expose-class-t \
	210-marshal-class-t \
	$(EOL)

dist_test_scripts += \
	110-hello-world-t.sh \
	160-error-t.sh
	$(EOL)

test_extra_programs += \
	110-hello-world-s \
	160-error-s \
	$(EOL)

dist_test_extra_scripts += \
	bash-test-utils-s.sh \
	$(EOL)

# Make sure common.sh gets remade if necessary before running tests
all-local: common.sh
