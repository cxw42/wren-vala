# common rules

# for convenience at the ends of lists
EOL =

# A convenient place to hold phony targets
.PHONY: $(phony)
phony =

# === Locations =========================================================

# From https://tecnocode.co.uk/2013/12/14/notes-on-vala-and-automake/
vapidir = $(datadir)/vala/vapi

# === Variables =========================================================

# Vala settings.
# - LOCAL_VALA_FLAGS is filled in by each Makefile.am with any other valac
#   options that Makefile.am needs.
# - TODO remove USER_VALAFLAGS once I figure out why regular VALAFLAGS
#   isn't being passed through.
AM_VALAFLAGS = \
	$(LOCAL_VALA_FLAGS) \
	--pkg gobject-2.0 \
	--pkg gio-2.0 \
	$(USER_VALAFLAGS) \
	$(EOL)

# C settings, which are the same throughout.  LOCAL_CFLAGS is filled in
# by each Makefile.am.
AM_CFLAGS = $(LOCAL_CFLAGS) $(BASE_CFLAGS) $(CODE_COVERAGE_CFLAGS)
AM_CPPFLAGS = $(CODE_COVERAGE_CPPFLAGS)

# Libs.  $(LOCAL_LIBS) is added to $(LIBS) in configure.ac.
LOCAL_LIBS = $(BASE_LIBS) $(CODE_COVERAGE_LIBS)

# === Code coverage =====================================================

# For code coverage, per
# https://www.gnu.org/software/autoconf-archive/ax_code_coverage.html
clean-local: code-coverage-clean
distclean-local: code-coverage-dist-clean

CODE_COVERAGE_OUTPUT_FILE = $(PACKAGE_TARNAME)-coverage.info
CODE_COVERAGE_OUTPUT_DIRECTORY = $(PACKAGE_TARNAME)-coverage

include $(top_srcdir)/aminclude_static.am
