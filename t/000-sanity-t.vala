// t/000-sanity-t.vala

using Wren;

void test_sanity()
{
  debug("Wren API version %s, wren-vala version %s",
    Wren.APIVER(), Wren.VERSION());
  assert_true(true);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/000-sanity/sanity", test_sanity);
  return Test.run();
}
