# common rules

# for convenience at the ends of lists
EOL =

# For code coverage, per
# https://www.gnu.org/software/autoconf-archive/ax_code_coverage.html
clean-local: code-coverage-clean
distclean-local: code-coverage-dist-clean

CODE_COVERAGE_OUTPUT_FILE = $(PACKAGE_TARNAME)-coverage.info
CODE_COVERAGE_OUTPUT_DIRECTORY = $(PACKAGE_TARNAME)-coverage

include $(top_srcdir)/aminclude_static.am
