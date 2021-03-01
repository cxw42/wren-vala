// t/140-roundtrip-data-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

void test_call()
{
  var vm = new Wren.VMV();
  assert_nonnull(vm);
  if(vm == null) {
    return;
  }

  var ok = vm.interpret("main", """
                        var Answer = null   // must be uppercase ...
                        class C {
                          static stash(v) {
                            Answer = v      // ... to be found here.
                          }
                        }
                        """);
  assert_true(ok == InterpretResult.SUCCESS);
  if(ok != InterpretResult.SUCCESS) {
    print("# Got %s; expected SUCCESS\n", ok.to_string());
    return;
  }

  vm.ensure_slots(2);

  var stashhandle = vm.make_call_handle("stash(_)");
  assert_nonnull(stashhandle);
  if(stashhandle == null) {
    return;
  }

  vm.get_variable("main", "Answer", 0);
  var ty = vm.get_slot_type(0);
  assert_true(ty == Wren.Type.NULL);

  // Write by calling C.stash()
  vm.get_variable("main", "C", 0);
  vm.set_slot_string(1, "Hello");
  ok = vm.call(stashhandle);
  assert_true(ok == InterpretResult.SUCCESS);
  if(ok != InterpretResult.SUCCESS) {
    print("# Got %s; expected SUCCESS\n", ok.to_string());
    return;
  }

  vm.get_variable("main", "Answer", 0);
  ty = vm.get_slot_type(0);
  assert_true(ty == Wren.Type.STRING);
  if(ty != Wren.Type.STRING) {
    print("# Got %s; expected STRING\n", ty.to_string());
    return;
  }

  var str = vm.get_slot_string(0);
  assert_cmpstr(str, EQ, "Hello");
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/140-roundtrip-data/call", test_call);
  return Test.run();
}
