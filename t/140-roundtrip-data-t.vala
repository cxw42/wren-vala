// t/140-roundtrip-data-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

errordomain Err {
  /** Can't go on */
  BAIL,
  /** Can go on */
  OOPS,
}

private Wren.VMV g_vm;

void test_call()
{
  try {
    var ok = g_vm.interpret("main", """
                          var Answer = null   // must be uppercase ...
                          class C {
                            static stash(v) {
                              Answer = v      // ... to be found here.
                            }
                          }
                          """);
    if(ok != InterpretResult.SUCCESS) {
      throw new Err.OOPS("Got %s; expected SUCCESS\n".printf(ok.to_string()));
    }

    g_vm.ensure_slots(2);

    var stashhandle = g_vm.make_call_handle("stash(_)");
    if(stashhandle == null) {
      throw new Err.OOPS("Couldn't get stash(_) handle");
    }

    g_vm.get_variable("main", "Answer", 0);
    var ty = g_vm.get_slot_type(0);
    assert_cmpuint(ty, EQ, Wren.Type.NULL);

    // Write a string by calling C.stash()
    g_vm.get_variable("main", "C", 0);
    g_vm.set_slot_string(1, "Hello");
    ok = g_vm.call(stashhandle);
    assert_cmpuint(ok, EQ, InterpretResult.SUCCESS);
    if(ok != InterpretResult.SUCCESS) {
      throw new Err.OOPS("Couldn't set string value");
    }

    // Check the string
    g_vm.get_variable("main", "Answer", 0);
    ty = g_vm.get_slot_type(0);
    assert_cmpuint(ty, EQ, Wren.Type.STRING);
    if(ty == Wren.Type.STRING) {
      var str = g_vm.get_slot_string(0);
      assert_cmpstr(str, EQ, "Hello");
    }

    // TODO test other types

    assert_true(true);
  } catch(Err e) {
    if(e is Err.BAIL) {
      print("Bail out! %s\n", e.message);
    } else {
      print("# Got error %s\n", e.message);
    }
    assert_not_reached();
  }
} // test_call

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/140-roundtrip-data/call", test_call);
  var exitcode = 1;

  try {
    g_vm = new Wren.VMV();
    assert_nonnull(g_vm);
    if(g_vm == null) {
      throw new Err.BAIL("Couldn't create VM");
    }
    exitcode = Test.run();

  } catch(Err e) {
    if(e is Err.BAIL) {
      print("Bail out! %s\n", e.message);
    } else {
      print("# Got error %s\n", e.message);
    }
    exitcode = 1;
    assert_not_reached();
  }

  g_vm = null;

  return exitcode;
}
