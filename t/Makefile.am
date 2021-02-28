include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

test_programs =

# So we don't have to list the sources of every test program individually
AM_DEFAULT_SOURCE_EXT = .vala
# But that messes up the linker selection, so:
CCLD = $(CXX)

AM_VALAFLAGS = \
	--vapidir $(top_srcdir)/src \
	--vapidir $(top_builddir)/src \
	--pkg libwren-vala-@APIVER@ \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	$(EOL)

AM_CFLAGS = \
	-I $(top_srcdir)/src \
	-I $(top_builddir)/src \
	$(BASE_CFLAGS) \
	$(EOL)

# Libs: -lwren is in LIBS, which is included by default.
LDADD = \
	-L$(top_builddir)/src \
	-lwren-vala \
	$(BASE_LIBS) \
	$(EOL)

if !WREN_INSTALL
test_programs += \
	000-sanity-t \
	100-vmv-t \
	$(EOL)
endif
