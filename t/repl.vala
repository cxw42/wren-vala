// t/repl.vala: Basic REPL for Wren.
// Part of wren-vala, https://github.com/cxw42/wren-vala
//
// By Christopher White <cxwembedded@gmail.com>
// Copyright (c) 2021 Christopher White.  All rights reserved.
// SPDX-License-Identifier: MIT

using Wren;

// Linenoise extern declarations
extern unowned string linenoise(string prompt);
extern void linenoiseHistoryAdd(string line);

// Main loop
int mainloop(VMV vm)
{
  print("Enter Wren lines.  Say `exit` to exit.\n`=foo` is short for `System.print(foo)`.\n");
  while(true) {

    var line = linenoise("> ");
    if(line == null || line == "" || line == "exit" || line == "quit") {
      break;
    }
    if(line[0] == '=') {
      line = "System.print(" + line.substring(1) + ")";
    }
    linenoiseHistoryAdd(line);
    var ok = vm.interpret("main", line);
    if(ok != SUCCESS) {
      printerr("Error: %s\n", ok.to_string());
    }
  }

  return 0;
}

/** Whether to print the version info */
bool opt_version = false;

/** Verbosity. */
int opt_verbose = 0;
bool cb_verbose()
{
  ++opt_verbose;
  return true;
}

int main(string[] args)
{
  // --- Parse args ---

  GLib.OptionEntry[] opts = {
    // --version
    { "version", 'V', 0, OptionArg.NONE, &opt_version, "Display version number", null },
    // --verbose
    { "verbose", 'v', OptionFlags.NO_ARG, OptionArg.CALLBACK,
      (void *)cb_verbose, "Verbosity (can be given multiple times)", null },
  };

  try {
      var opt_context = new OptionContext ("- a Wren REPL written in Vala");
      opt_context.set_help_enabled (true);
      opt_context.add_main_entries (opts, null);
      opt_context.set_description(
          ("Reads and executes one line of Wren code at a time.\n" +
          "Visit %s for more information.\n").printf(PACKAGE_URL()));
      opt_context.parse(ref args);
  } catch (OptionError e) {
      printerr ("error: %s\n", e.message);
      return 1;
  }

  if (opt_version) {
      print("%s\nVisit %s for more information\n", PACKAGE_STRING(), PACKAGE_URL());
      return 0;
  }

  // --- Run it ---
  var vm = new Wren.VMV();

  return mainloop(vm);
}
