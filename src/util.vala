// util.vala: Utility routines used by the Vala bindings for WrenVM
// See wren-pkg/wren/src/include/wren.h for documentation.
//
// By Christopher White <cxwembedded@gmail.com>
// Copyright (c) 2021 Christopher White.  All rights reserved.
// SPDX-License-Identifier: MIT

[CCode(cprefix="wren", cheader_filename="wren-vala-merged.h")]
namespace Wren {

  // === From myconfig.c ===
  /** The Wren version */
  public extern string APIVER();
  /** The wren-vala version */
  public extern string VERSION();

  // === Defined in this file ===

  /** Regex for foreign_decl_for */
  private static Regex fdf_re_ = null;

  /** Make a foreign declaration for a particular signature */
  public string foreign_decl_for(string sig)
  {
    if(fdf_re_ == null) {
      try {
        var ident = "(?:[A-Za-z_][A-Za-z_0-9]*)";
        fdf_re_ = new Regex(
          "^(?<leadtext>(?:static\\s+)?%s)(?<rest>.*)$".printf(ident));
      } catch(RegexError e) {
        debug("Could not create regex for %s(): %s", GLib.Log.METHOD, e.message);
        assert(false);  // I can't go on
      }
    }

    MatchInfo matches;
    if(!fdf_re_.match(sig, 0, out matches)) {
      return "INVALID_FORMAT for >%s<!".printf(sig);  // an invalid function declaration
    }

    StringBuilder sb = new StringBuilder();
    sb.append("foreign ");
    sb.append(matches.fetch_named("leadtext"));

    var rest = (!)matches.fetch_named("rest");
    if(rest.data[0] == '=') { // setter
      sb.append("=");
      rest = rest.substring(1);
    }

    // Parameters, if any: convert `_` to unique identifiers
    int paramnum = -1;
    if(rest.data[0] == '(') {
      sb.append("(");
      var parms = rest.substring(1,rest.length-2).split(",");
      for(int i=0; i < parms.length; ++i) {
        if(i!=0) {
          sb.append(",");
        }
        sb.append_printf("p%d", ++paramnum);
      }
      sb.append(")");
    }

    return sb.str;
  } // foreign_decl_for()

  /** Convert from (isStatic, signature) to signature */
  public string make_sig(bool isStatic, string signature)
  {
    return "%s%s".printf(isStatic ? "static " : "", signature);
  }

} // namespace Wren
