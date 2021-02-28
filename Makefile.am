# Makefile.am for wren-vala
# https://github.com/cxw42/wren-vala
# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

ACLOCAL_AMFLAGS = -I m4 -I m4-bundled

SUBDIRS = wren-pkg src t doc

EXTRA_DIST = \
	bootstrap \
	README.md \
	tap-driver.sh \
	tap-test \
	.gitignore \
	.uncrustifyrc \
	$(EOL)

# Since we always regenerate the Vala source, we update files in src/ .
# As a result, normal distcheck (RO src/ directory) fails.  Rather than
# giving up on distcheck entirely, permit modifying src/ .
distcheck-hook:
	chmod -R u+w $(distdir)

phony += prettyprint
prettyprint:
	-$(AM_V_GEN)uncrustify -l VALA -c $(top_srcdir)/.uncrustifyrc --replace \
		src/basics.vapi.in \
		src/vm.vala.in \
		t/000-sanity-t.vala \
		t/100-vmv-t.vala \
		$(EOL)

phony += cleanwren
cleanwren:
	-cd wren-pkg/wren && git clean -dfx

# Used by coverage.sh --- remove the existing code-coverage data.
remove-code-coverage-data:
	-rm -rf "$(CODE_COVERAGE_OUTPUT_FILE)" "$(CODE_COVERAGE_OUTPUT_FILE).tmp" "$(CODE_COVERAGE_OUTPUT_DIRECTORY)"
	-find . -name "*.gcda" -delete
