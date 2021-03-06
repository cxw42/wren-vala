dnl configure.ac for wren-vala
dnl https://github.com/cxw42/wren-vala
dnl Copyright (c) 2021 Christopher White
dnl SPDX-License-Identifier: MIT

dnl === Basic setup =======================================================

dnl Note: the version number of this package matches the version of Wren in
dnl the first three digits.
AC_INIT([Vala bindings for Wren],
  [0.4.0.1],
  [https://github.com/cxw42/wren-vala/issues], [wren-vala],
  [https://github.com/cxw42/wren-vala])

AC_PREREQ([2.65])
AC_COPYRIGHT([Copyright (C) 2021 Christopher White])

AC_MSG_NOTICE([Configuring $PACKAGE_STRING])

AC_CONFIG_SRCDIR([rules.mk])    dnl make sure the srcdir is correctly specified
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_MACRO_DIR([m4-bundled])

AM_INIT_AUTOMAKE([1.13.2 foreign subdir-objects])   dnl 1.13.2+ for better Vala support

dnl NOTE: If you add any variables to config.h, make sure to add them
dnl to src/myconfig.vapi as well.
AC_CONFIG_HEADERS([config.h])

LT_INIT

AC_PROG_CC

AM_PROG_VALAC
dnl Known to work with valac 0.40.19

dnl TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
dnl isn't being passed through.
AC_ARG_VAR([USER_VALAFLAGS], [extra options for valac(1)])

PKG_PROG_PKG_CONFIG([0.24])

dnl === pkg-config files ==================================================

dnl Thanks for boilerplate and tips to
dnl https://tecnocode.co.uk/2014/12/09/a-checklist-for-writing-pkg-config-files/

dnl Pull the first three digits out as the Wren version
AC_SUBST([WREN_VERSION])
WREN_VERSION=`perl -Mversion -E 'print join q(.), @{version->parse($ARGV[[0]])->{version}}[[0..2]]' "$PACKAGE_VERSION"`
AC_MSG_NOTICE([Wren version $WREN_VERSION])

PKG_INSTALLDIR
AC_SUBST([APIVER], [$WREN_VERSION])  dnl Just to reduce typing :)
AC_DEFINE_UNQUOTED([APIVER],["$WREN_VERSION"], [Wren API version])
AC_SUBST([APIVERSH], [AS_TR_SH([$WREN_VERSION])])

dnl === Wren ==============================================================

AC_CHECK_FILE([$srcdir/wren-pkg/wren/README.md], [],
  [AC_MSG_ERROR([You asked me to install Wren but the source tree does not appear to be full.  Try 'git submodule update --init --recursive" if you have not yet done so.])])

AC_SUBST([MERGED_HEADER], [wren-vala-$APIVER.h])

AC_SEARCH_LIBS([log2], [m],
  [], [
    AC_MSG_WARN([Could not find -lm, which Wren requires])
  ]
)

dnl === Code coverage =====================================================

dnl For some reason, the coverage data is referring to src/.../glib-2.0.vapi.
dnl Inject code to strip that from the .info file so genhtml can succeed.
dnl This is all very ugly.  For example, the variables in this section are
dnl hardwired for use in a Makefile, since they assume Makefile syntax
dnl (embedded in sh(1) escaping).

AC_CHECK_PROG([GENHTMLREAL], [genhtml], [genhtml])

GENHTMLHACK="\$(GENHTMLREAL)"
AC_CHECK_PROG([GENHTML], [genhtml], [\$(GENHTMLHACK)])

AX_AM_MACROS_STATIC
AX_CODE_COVERAGE

AM_COND_IF(
    [CODE_COVERAGE_ENABLED],
    [ dnl then
        AC_SUBST([GENHTMLHACK], ['dnl
            perl -n -i -e '"'"'dnl
              s{\bt/(libwren-vala-.*vapi)$$}{src/$$1}; dnl
              print unless m{\b(?:src|t)/?.*?/glib-2.0.vapi}..m{^end_of_record} dnl
            '"'"' "$(CODE_COVERAGE_OUTPUT_FILE)" ; dnl
            LANG=C $(GENHTMLREAL) dnl
        '])
    ]
)

dnl === Dependencies ======================================================

dnl glib: 2.38+ for g_test_build_filename()
dnl All deps are private so that the .pc file can be used for other languages
dnl than just vala.
AX_PKG_CHECK_MODULES([BASE], [], [
    gobject-2.0
    gio-2.0
    glib-2.0 >= 2.38
])

dnl === Tests =============================================================

GLIB_TESTS

dnl === Docs ==============================================================

AC_PATH_PROG([VALADOC], [valadoc], [no])
AM_CONDITIONAL([HAVE_VALADOC], [test "x$VALADOC" '!=' "xno"])

m4_ifdef([GTK_DOC_CHECK], [
GTK_DOC_CHECK([1.14],[--flavour no-tmpl])
],[
AM_CONDITIONAL([ENABLE_GTK_DOC], false)
])

dnl === Hacks =============================================================

dnl Workaround for automake's prohibiting switches in LDADD.
dnl Thanks to Gavin Smith,
dnl https://lists.gnu.org/archive/html/automake/2015-03/msg00004.html

dnl AC_SUBST([wholearchive], [-Wl,--whole-archive])
dnl AC_SUBST([nowholearchive], [-Wl,--no-whole-archive])

# Create a place to put in extra libraries project-wide
LIBS="\$(LOCAL_LIBS) $LIBS"

dnl === Output ============================================================

AC_CONFIG_FILES([
    Makefile
    doc/Makefile
    src/Makefile
    t/Makefile
    t/common.sh
    wren-pkg/Makefile
])

dnl pkg-config files: name them after the Wren version
AC_CONFIG_FILES([src/libwren-vala-"${APIVER}".pc:src/libwren-vala.pc.in], [], [APIVER=$APIVER])

AM_SILENT_RULES([yes])
AC_OUTPUT
