// t/105-tramp-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_hash_key()
{
  assert_cmpstr(Tramp.hash_key("m","c"), EQ, "m!c");
  assert_cmpstr(Tramp.hash_key("m","c","sig()"), EQ, "m!c:sig()");
  assert_cmpstr(Tramp.hash_key("m","c","static sig()"), EQ, "m!c:static sig()");
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/105-tramp/hash_key", test_hash_key);
  return Test.run();
}
