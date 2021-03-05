// t/140-roundtrip-data-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

errordomain Err {
  /** Can't go on */
  BAIL,
  /** Can go on */
  OOPS,
}

private Wren.VMV g_vm;
private HandleV g_stash;

// Writes the variable in g_vm's slot 1 to g_vm's main.Answer.
private void stash() throws Err
{
  g_vm.get_variable("main", "C", 0);
  var ok = g_vm.call(g_stash);
  assert_cmpuint(ok, EQ, InterpretResult.SUCCESS);
  if(ok != InterpretResult.SUCCESS) {
    throw new Err.OOPS("Couldn't set string value");  // LCOV_EXCL_LINE - unreachable on a successful test
  }
}

// Throws unless g_vm's main.Answer holds a value of the given type
void confirm(Wren.Type want) throws Err
{
  g_vm.get_variable("main", "Answer", 0);
  var ty = g_vm.get_slot_type(0);
  assert_cmpuint(ty, EQ, want);
  if(ty != want) {
    // LCOV_EXCL_START
    throw new Err.OOPS("Wrong type --- got %s but expected %s",
            ty.to_string(), want.to_string());
  } // LCOV_EXCL_STOP
}

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
      throw new Err.OOPS("Got %s; expected SUCCESS\n".printf(ok.to_string()));  // LCOV_EXCL_LINE - unreachable on a successful test
    }

    g_vm.ensure_slots(2);

    g_stash = g_vm.make_call_handle("stash(_)");
    if(g_stash == null) {
      throw new Err.OOPS("Couldn't get stash(_) handle"); // LCOV_EXCL_LINE - unreachable on a successful test
    }

    confirm(NULL);  // Before writing anything

    // Now, for each type of Wren value, write by calling stash() and then
    // read using confirm() and get_slot_*().  Tests are in order of
    // Wren.Type value.

    // BOOL
    g_vm.set_slot_bool(1, true);
    stash();
    confirm(BOOL);
    var boo = g_vm.get_slot_bool(0);
    assert_true(boo);

    // NUM
    g_vm.set_slot_double(1, 42);
    stash();
    confirm(NUM);
    assert_cmpfloat(g_vm.get_slot_double(0), EQ, 42);

    g_vm.set_slot_double(1, 3.14159);
    stash();
    confirm(NUM);
    assert_cmpfloat(g_vm.get_slot_double(0), EQ, 3.14159);

    // FOREIGN

    // LIST
    g_vm.set_slot_new_list(1);
    stash();
    confirm(LIST);
    assert_cmpint(g_vm.get_list_count(0), EQ, 0);

    // MAP
    g_vm.set_slot_new_map(1);
    stash();
    confirm(MAP);
    assert_cmpint(g_vm.get_map_count(0), EQ, 0);

    // NULL
    g_vm.set_slot_null(1);
    stash();
    confirm(NULL);

    // STRING
    g_vm.set_slot_string(1, "Hello");
    stash();

    confirm(STRING);
    var str = g_vm.get_slot_string(0);
    assert_cmpstr(str, EQ, "Hello");

    // byte arrays - also STRING
    uint8 arr[3] = {0x00, 0xc1, 0x40};
    g_vm.set_slot_bytes(1, arr);
    stash();

    confirm(STRING);
    var otherarr = g_vm.get_slot_bytes(0);
    assert_cmpuint(arr.length, EQ, otherarr.length);
    for(int i=0; i<otherarr.length; ++i) {
      print("# %d %02x\n", i, otherarr[i]);
    }
    if(arr.length != otherarr.length)
    {
      throw new Err.OOPS("Length mismatch");  // LCOV_EXCL_LINE - unreachable on a successful test
    }

    for(int i=0; i<arr.length; ++i) {
      assert_cmpuint(arr[i], EQ, otherarr[i]);
    }

    // UNKNOWN - any way to test this?

    assert_true(true);
  } catch(Err e) {  // LCOV_EXCL_START
    if(e is Err.BAIL) {
      print("Bail out! %s\n", e.message);
    } else {
      print("# Got error %s\n", e.message);
    }
    assert_not_reached();
  } // LCOV_EXCL_STOP
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
      throw new Err.BAIL("Couldn't create VM"); // LCOV_EXCL_LINE - unreachable on a successful test
    }
    exitcode = Test.run();

  } catch(Err e) {  // LCOV_EXCL_START
    if(e is Err.BAIL) {
      print("Bail out! %s\n", e.message);
    } else {
      print("# Got error %s\n", e.message);
    }
    exitcode = 1;
    assert_not_reached();
  } // LCOV_EXCL_STOP

  g_vm = null;

  return exitcode;
}
