// t/105-tramp-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_hash_key()
{
  assert_cmpstr(Tramp.hash_key("m","c"), EQ, "m!c");
  assert_cmpstr(Tramp.hash_key("m","c",false,"sig()"), EQ, "m!c.sig()");
  assert_cmpstr(Tramp.hash_key("m","c",true,"sig()"), EQ, "m!c.$sig()");
}

void test_foreign_decl_for_key()
{
  assert_cmpstr(Tramp.foreign_decl_for_key("m!c"), EQ, "INVALID_FORMAT!");
  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.$sig()"), EQ, "foreign static sig()");
  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.sig()"), EQ, "foreign sig()");

  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.$sig(_)"), EQ, "foreign static sig(p0)");
  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.sig(_)"), EQ, "foreign sig(p0)");

  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.$sig(_,_)"), EQ, "foreign static sig(p0,p1)");
  assert_cmpstr(Tramp.foreign_decl_for_key("m!c.sig(_,_)"), EQ, "foreign sig(p0,p1)");
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/105-tramp/hash_key", test_hash_key);
  Test.add_func("/105-tramp/foreign_decl_for_key", test_foreign_decl_for_key);
  return Test.run();
}
