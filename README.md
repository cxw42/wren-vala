# wren-vala: Vala bindings for the Wren scripting language

# Installing

## Requirements

- `valac`
- autotools (those are probably already installed)

## From a dist tarball

  tar xvzf wren-vala-VERSION.tar.gz
  cd wren-vala-VERSION

Then skip down to the "Common" subsection below.

## From git

After cloning:
- run `git submodule update --init --recursive` if you do not
  already have Wren installed on your system.
- run `./bootstrap`
- follow the instructions in the next section, "Common".

## Common

After doing one of the above "From" subsections:

If you do not already have Wren installed, run
`./configure --enable-wren-install && make -j && sudo make -j install`

After that, or if you do have Wren installed, run
`./configure && make -j && sudo make -j install`.

Note that `make` will only build EITHER Wren OR `wren-vala`.  The default
is `wren-vala`.  To build Wren itself, pass `--enable-wren-install` to
`./configure`.  Yes, this is a bit odd, but it's the best I can think of
at the moment! :)

## After building from a Git repo

The `wren-pkg/wren` submodule may be dirty.  To restore it to its clean state,
run `make cleanwren`.  This will **remove** any files in `wren-pkg/wren` that
are not checked in, so use this command carefully!

# Repo contents

- `src/`: source code for the Vala bindings
- `t/`: tests for the Vala bindings
- `doc/`: documentation for the Vala bindings
- `wren-pkg/`: Code to install wren to the system.  Only tested on Linux,
  as of present.
  - `wren-pkg/wren/`: [wren-lang/wren](https://github.com/wren-lang/wren),
    as a git submodule

# Useful things

- Code coverage of the test suite: run `./coverage.sh`, then open
  `wren-vala-coverage/index.html` in a Web browser.  Requires gcov(1) and
  lcov(1).
- Documentation: run `make html`, then open `doc/valadoc/index.html` in a
  Web browser.

## Legal

Licensed MIT (the same as Wren itself).
Copyright (c) 2021 Christopher White.  All rights reserved.  See file
[LICENSE](LICENSE) for details.

Contains material derived from Wren, which is
Copyright (c) 2021 Robert Nystrom and Wren Contributors, licensed MIT.

`t/bash-test-utils-s.sh` is Copyright (c) 2008-2012, Advanced Micro Devices,
Inc., and is licensed BSD 2-clause (see that file for details of its license).
