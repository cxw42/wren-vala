// t/100-vmv-t.vala

void test_instantiate()
{
  print("# No configuration\n");
  var vmv = new Wren.VMV();
  assert_nonnull(vmv);

  print("# Empty configuration\n");
  var conf = Wren.Configuration();
  Wren.InitConfiguration(ref conf);
  vmv = new Wren.VMV(conf);
  assert_nonnull(vmv);

  print("# Default configuration\n");
  conf = Wren.Configuration.default ();
  vmv = new Wren.VMV(conf);
  assert_nonnull(vmv);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/100-sanity/instantiate", test_instantiate);
  return Test.run();
}
