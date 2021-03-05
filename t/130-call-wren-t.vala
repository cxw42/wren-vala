// t/130-call-wren.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

private string g_str;

void writeFn(VM vm, string text)
{
  // print("# got >%s<\n", text);
  g_str += text;
}

void test_call()
{
  g_str = "";

  var conf = Wren.Configuration.default ();
  conf.writeFn = writeFn;
  var vm = new Wren.VMV.with_configuration(conf);
  assert_nonnull(vm);
  if(vm == null) {
    return; // LCOV_EXCL_LINE - unreachable on a successful test
  }

  var ok = vm.interpret("main", """
                        var answer=42
                        var message="Hello, world!"
                        """);
  assert_true(ok == SUCCESS);
  if(ok != SUCCESS) {
    return; // LCOV_EXCL_LINE - unreachable on a successful test
  }

  vm.ensure_slots(2);

  var printhandle = vm.make_call_handle("print(_)");
  assert_nonnull(printhandle);
  if(printhandle == null) {
    return; // LCOV_EXCL_LINE - unreachable on a successful test
  }

  vm.get_variable("main", "System", 0);
  vm.set_slot_string(1, "Hello");
  ok = vm.call(printhandle);
  assert_true(ok == SUCCESS);
  if(ok != SUCCESS) {
    return; // LCOV_EXCL_LINE - unreachable on a successful test
  }

  assert_cmpstr(g_str, EQ, "Hello\n");
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/130-call-wren/call", test_call);
  return Test.run();
}
