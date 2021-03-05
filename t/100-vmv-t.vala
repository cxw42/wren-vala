// t/100-vmv-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_instantiate()
{
  print("# Default configuration\n");
  var vm = new Wren.VMV();
  assert_nonnull(vm);

  print("# null configuration\n");
  vm = new Wren.VMV.with_configuration(null);
  assert_nonnull(vm);

  print("# Empty configuration\n");
  var conf = Wren.Configuration();
  Wren.InitConfiguration(ref conf);
  vm = new Wren.VMV.with_configuration(conf);
  assert_nonnull(vm);

  print("# Default configuration\n");
  conf = Wren.Configuration.default ();
  vm = new Wren.VMV.with_configuration(conf);
  assert_nonnull(vm);
}

void test_misc()  // for coverage
{
  var vm = new Wren.VMV();
  assert_nonnull(vm);

  // get_slot_count()
  vm.ensure_slots(1);
  assert_cmpint(vm.get_slot_count(), EQ, 1);
  vm.ensure_slots(2);
  assert_cmpint(vm.get_slot_count(), EQ, 2);

  // collect_garbage()
  vm.collect_garbage();
  assert_true(true);

  // has_variable() and has_module()
  assert_false(vm.has_module("main"));
  // Can't => assert_false(vm.has_variable("main", "answer"));
  // --- it is an error to try to look for a variable in a nonexistent module.

  var ok = vm.interpret("main", """
                        var answer=42
                        """);
  assert_true(ok == SUCCESS);
  if(ok != SUCCESS) {
    return; // LCOV_EXCL_LINE - unreachable on a successful test
  }

  assert_true(vm.has_module("main"));
  assert_true(vm.has_variable("main", "answer"));
}

void test_userdata()
{
  var vm = new Wren.VMV();
  assert_nonnull(vm);

  string test = "Yowza";
  vm.set_user_data((void *)test);

  string got = (string)vm.get_user_data();
  assert_cmpstr(got, EQ, test);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/100-vmv/instantiate", test_instantiate);
  Test.add_func("/100-vmv/misc", test_misc);
  Test.add_func("/100-vmv/userdata", test_userdata);
  return Test.run();
}
