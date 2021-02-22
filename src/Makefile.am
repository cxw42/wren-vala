include $(top_srcdir)/rules.mk

pkgconfig_DATA = \
	libwren-@APIVER@.pc \
	libwren-vala-@APIVER@.pc \
	$(EOL)

DISTCLEANFILES = $(pkgconfig_DATA)

lib_LTLIBRARIES = libwren-vala.la

libwren_vala_la_SOURCES = \
	basics.vapi \
	vm.vala \
	$(EOL)

libwren_vala_la_VALAFLAGS = \
	--library libwren-vala-@APIVER@.so -H libwren-vala-@APIVER@.h \
	--vapi libwren-vala.vapi \
	--pkg gobject-2.0 \
	$(EOL)

# Before installing libwren-vala-@APIVER@.vapi, tack basics.vapi onto the end
# of it.  The compiler only writes the declarations from vm.vala into the vapi
# file, but the client needs basics.vapi as well.
libwren-vala-@APIVER@.vapi: libwren-vala.vapi basics.vapi
	cat $^ > $@

dist_vapi_DATA = libwren-vala-@APIVER@.vapi

include_HEADERS = libwren-vala-@APIVER@.h

libwren_vala_la_CFLAGS = $(BASE_CFLAGS)
libwren_vala_la_LIBADD = $(BASE_LIBS)
