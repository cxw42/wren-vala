# Makefile.am for wren-vala
# https://github.com/cxw42/wren-vala
# Copyright (c) 2021 Christopher White
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

ACLOCAL_AMFLAGS = -I m4 -I m4-bundled

SUBDIRS = wren-pkg src t

EXTRA_DIST = \
	bootstrap \
	README.md \
	tap-driver.sh \
	tap-test \
	.uncrustifyrc \
	$(EOL)

phony += prettyprint
prettyprint:
	-$(AM_V_GEN)uncrustify -l VALA -c $(top_srcdir)/.uncrustifyrc --replace \
		src/basics.vapi \
		src/vm.vala \
		t/000-sanity-t.vala \
		t/100-vmv-t.vala \
		$(EOL)

phony += cleanwren
cleanwren:
	-cd wren-pkg/wren && git clean -dfx
