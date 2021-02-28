// t/110-hello-world-s.vala - support for test 110

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_print()
{
  var vmv = new Wren.VMV.with_default_config();
  assert_nonnull(vmv);
  var ok = vmv.interpret("main", """ System.print("Hello, world!") """);
  assert_true(ok == SUCCESS);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/110-hello-world/print", test_print);
  return Test.run();
}
