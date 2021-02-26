dnl configure.ac for wren-vala
dnl https://github.com/cxw42/wren-vala
dnl Copyright (c) 2021 Christopher White
dnl SPDX-License-Identifier: MIT

dnl === Basic setup =======================================================

dnl Note: the version number of this package matches the version of Wren.
AC_INIT([Vala bindings for Wren],
  [0.4.0],
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
dnl AC_CONFIG_HEADER([config.h])

LT_INIT

AC_PROG_CC

AM_PROG_VALAC
dnl Known to work with valac 0.40.19

dnl TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
dnl isn't being passed through.
AC_ARG_VAR([USER_VALAFLAGS], [extra options for valac(1)])

PKG_PROG_PKG_CONFIG([0.24])

dnl === pkg-config file for wren-vala =====================================

dnl Thanks for boilerplate and tips to
dnl https://tecnocode.co.uk/2014/12/09/a-checklist-for-writing-pkg-config-files/

PKG_INSTALLDIR
AC_SUBST([APIVER], [$PACKAGE_VERSION])  dnl Just to reduce typing :)
AC_SUBST([APIVERSH], [AS_TR_SH([$PACKAGE_VERSION])])

dnl === Installing Wren from wren-pkg/ ====================================

AC_ARG_ENABLE([wren-install],
  AS_HELP_STRING([--enable-wren-install],
    [Build and install Wren itself INSTEAD OF wren-vala.  You will need to re-run
     configure without this option to install wren-vala.])
)
AM_CONDITIONAL([WREN_INSTALL], [test "x$enable_wren_install" '=' 'xyes'])

dnl Set up for the Wren compilation
whichtarget='wren-vala'
AM_COND_IF([WREN_INSTALL],
  [
    dnl Sanity check
    AC_CHECK_FILE([wren-pkg/wren/README.md], [],
      [AC_MSG_ERROR([You asked me to install Wren but the source tree does not appear to be full.  Try 'git submodule update --init --recursive" if you have not yet done so.])])

    whichtarget='Wren itself (after installing, re-run ./configure to build wren-vala)'
  ]
)

dnl === Check for Wren ====================================================
dnl Don't use pkg-config since Wren itself does not provide a .pc file.
dnl However, we could be using a hand-installed Wren or a Wren we installed
dnl using versioned names.

wren_exists='yes'
AC_SUBST([WREN_HEADER])
AC_CHECK_HEADERS([wren.h "wren-$APIVER.h"],
  [
    WREN_HEADER="$ac_header"
    break
  ],
)
AS_IF([test "x$WREN_HEADER" '=' 'x'],
  [
    dnl No wren.h found
    AC_MSG_WARN([Could not find wren.h])
    wren_exists=''
  ]
)

AC_SEARCH_LIBS([wrenNewVM], [wren "wren-$APIVER"],
  [], [
    AC_MSG_WARN([Could not find -lwren])
    wren_exists=''
  ],
  [-lm]
)

AS_IF([ test "x$wren_exists" '!=' 'xyes' && test "x$enable_wren_install" '!=' 'xyes' ],
  [
    AC_MSG_WARN([I could not find Wren on your system.  Try "$0 --enable-wren-install" to build and install a Wren package.])
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
            perl -n -i -e '"'"'print unless m{\b(?:src|t)/?.*?/glib-2.0.vapi}..m{^end_of_record}'"'"' "$(CODE_COVERAGE_OUTPUT_FILE)" ; dnl
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

dnl === Output ============================================================

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/basics.vapi
    src/vm.vala
    t/Makefile
    wren-pkg/Makefile
])
    dnl doc/Makefile

dnl pkg-config files: name them after the Wren version
AC_CONFIG_FILES([src/libwren-"$APIVER".pc:src/libwren.pc.in], [], [APIVER="$APIVER"])
AC_CONFIG_FILES([src/libwren-vala-"$APIVER".pc:src/libwren-vala.pc.in], [], [APIVER="$APIVER"])

dnl Tell the user what is going to happen
AC_CONFIG_COMMANDS([notify],
  [echo "*** Ready to build $whichtarget ***"],
  [whichtarget="$whichtarget"]
)

AM_SILENT_RULES([yes])
AC_OUTPUT
