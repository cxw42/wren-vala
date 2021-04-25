// t/090-util-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_foreign_decl_for()
{
  // Methods
  assert_cmpstr(foreign_decl_for("static sig()"), EQ, "foreign static sig()");
  assert_cmpstr(foreign_decl_for("sig()"), EQ, "foreign sig()");

  assert_cmpstr(foreign_decl_for("static sig(_)"), EQ, "foreign static sig(p0)");
  assert_cmpstr(foreign_decl_for("sig(_)"), EQ, "foreign sig(p0)");

  assert_cmpstr(foreign_decl_for("static sig(_,_)"), EQ, "foreign static sig(p0,p1)");
  assert_cmpstr(foreign_decl_for("sig(_,_)"), EQ, "foreign sig(p0,p1)");

  // Accessors
  assert_cmpstr(foreign_decl_for("static sig"), EQ, "foreign static sig");
  assert_cmpstr(foreign_decl_for("sig"), EQ, "foreign sig");

  assert_cmpstr(foreign_decl_for("static sig=(_)"), EQ, "foreign static sig=(p0)");
  assert_cmpstr(foreign_decl_for("sig=(_)"), EQ, "foreign sig=(p0)");
}

void test_make_sig()
{
  assert_cmpstr(make_sig(false, "foo"), EQ, "foo");
  assert_cmpstr(make_sig(true, "foo"), EQ, "static foo");
  assert_cmpstr(make_sig(false, "foo(_)"), EQ, "foo(_)");
  assert_cmpstr(make_sig(true, "foo(_)"), EQ, "static foo(_)");
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/090-util/foreign_decl_for", test_foreign_decl_for);
  Test.add_func("/090-util/make_sig", test_make_sig);
  return Test.run();
}
