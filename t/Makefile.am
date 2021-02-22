include $(top_srcdir)/rules.mk
include $(top_srcdir)/glib-tap.mk

# So we don't have to list the sources of every test program individually
AM_DEFAULT_SOURCE_EXT = .vala
# But that messes up the linker selection, so:
CCLD = $(CXX)

AM_VALAFLAGS = \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	$(EOL)

AM_CFLAGS = $(BASE_CFLAGS)
LDADD = $(BASE_LIBS)

test_programs = 000-sanity-t
