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

# --- Code hygiene -------------------------------------------

phony += prettyprint
prettyprint:
	-$(AM_V_GEN)uncrustify -l VALA -c $(top_srcdir)/.uncrustifyrc --replace \
		$(vala_all_sources) \
		t/000-sanity-t.vala \
		t/090-util-t.vala \
		t/105-tramp-t.vala \
		t/100-vmv-t.vala \
		t/110-hello-world-s.vala \
		t/120-read-var-from-wren-t.vala \
		t/130-call-wren-t.vala \
		t/140-roundtrip-data-t.vala \
		t/150-marshal-t.vala \
		t/200-expose-class-t.vala \
		$(EOL)
	-$(AM_V_GEN)uncrustify -c $(top_srcdir)/.uncrustifyrc --replace \
		$(c_all_sources) \
		$(EOL)

phony += p
p: prettyprint
	-ctags -R --exclude='doc/*' --exclude='wren-vala-coverage/*'

phony += cleanwren
cleanwren:
	-cd wren-pkg/wren && git clean -dfx

# --- Testing ------------------------------------------------

# Shortcuts for tests
phony += test
test: check

phony += build-tests
build-tests: all
	+$(MAKE) -C t $@

# --- Coverage -----------------------------------------------

# Used by coverage.sh --- remove the existing code-coverage data.
remove-code-coverage-data:
	-rm -rf "$(CODE_COVERAGE_OUTPUT_FILE)" "$(CODE_COVERAGE_OUTPUT_FILE).tmp" "$(CODE_COVERAGE_OUTPUT_DIRECTORY)"
	-find . -name "*.gcda" -delete
