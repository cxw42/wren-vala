# Copyright (c) 2021 Christopher White.  All rights reserved.
# SPDX-License-Identifier: MIT

include $(top_srcdir)/rules.mk

EXTRA_DIST = .gitignore

phony += valadoc clean-valadoc

html-local: valadoc

clean-local: clean-valadoc

if HAVE_VALADOC

valadoc:
	$(AM_V_GEN)valadoc -o valadoc -b $(top_srcdir)/src --verbose --force \
		--package-name='@PACKAGE_TARNAME@' \
		--package-version='@PACKAGE_VERSION@' \
		$(vala_all_sources) \
		--doclet=html \
		$(MY_VALA_PKGS) \
		$(EOL)

clean-valadoc:
	-rm -rf valadoc

else

valadoc:
	echo "Please check your valadoc installation and try again"

clean-valadoc:
	@: #Nothing to do

endif
