// t/120-read-var-from-wren.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_read()
{
  var vm = new Wren.VMV();
  assert_nonnull(vm);

  var ok = vm.interpret("main", """
                        var answer=42
                        var message="Hello, world!"
                        """);
  assert_true(ok == SUCCESS);
  if(ok != SUCCESS) {
    return;
  }

  vm.ensure_slots(1);

  vm.get_variable("main", "answer", 0);
  var answer = vm.get_slot_double(0);
  assert_cmpfloat(answer, EQ, 42.0);

  vm.get_variable("main", "message", 0);
  var message = vm.get_slot_string(0);
  assert_cmpstr(message, EQ, "Hello, world!");

}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/120-read-var-from-wren/read", test_read);
  return Test.run();
}
