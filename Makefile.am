# Makefile.am for wren-vala
# https://github.com/cxw42/wren-vala
# Copyright (c) 2021 Christopher White
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

SUBDIRS = src t

EXTRA_DIST = \
	.uncrustifyrc \
	bootstrap \
	tap-driver.sh \
	tap-test \
	$(EOL)

prettyprint:
	-$(AM_V_GEN)uncrustify -l VALA -c $(top_srcdir)/.uncrustifyrc --replace \
		src/basics.vapi \
		src/vm.vala \
		t/000-sanity-t.vala \
		t/100-vmv-t.vala \
		$(EOL)
