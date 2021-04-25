// t/150-marshal-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

private Wren.Configuration g_conf;

/** Make a new vm using g_conf */
private Wren.VM new_vm()
{
  var retval = new Wren.VM(g_conf);
  assert_nonnull(retval);
  if(retval == null) {  // LCOV_EXCL_START
    print("# Could not create VM\n");
    assert_not_reached();
  } // LCOV_EXCL_STOP
  return retval;
}

// Test reading Wren data into a GValue
void test_from_wren()
{
  try {
    var vm = new_vm();
    Value v;

    vm.EnsureSlots(1);

    vm.SetSlotBool(0, true);
    v = Marshal.value_from_slot(vm, 0);
    assert_true(v.type() == GLib.Type.BOOLEAN);
    assert_true(v.get_boolean());

    vm.SetSlotDouble(0, 42);
    v = Marshal.value_from_slot(vm, 0);
    assert_true(v.type() == GLib.Type.DOUBLE);
    assert_cmpfloat(v.get_double(), EQ, 42);

    // FOREIGN is tested in t/210

    var interpok = vm.Interpret("main", """var listfromwren = [1, "yes", true]""");
    assert_true(interpok == SUCCESS);
    vm.EnsureSlots(2);
    vm.GetVariable("main", "listfromwren", 0);

    // Check Wren's view of the list as well as Marshal's view
    {
      Wren.Type types[] = { Wren.Type.NUM, Wren.Type.STRING, Wren.Type.BOOL };
      Value values[] = { 1.0, "yes", true };
      assert_cmpuint(vm.GetSlotType(0), EQ, Wren.Type.LIST);
      assert_cmpint(vm.GetListCount(0), EQ, 3);
      for(int i = 0; i < vm.GetListCount(0); ++i) {
        vm.GetListElement(0, i, 1); // slot 1 := (slot 0)[i]
        assert_cmpuint(vm.GetSlotType(1), EQ, types[i]);
        var val = Marshal.value_from_slot(vm, 1);

#if 0
        // XXX: the json-glib is just for serializing values when debugging
        var node = new Json.Node(VALUE);
        node.set_value(values[i]);
        debug("%d: expected %s", i, Json.to_string(node, true));
        node.set_value(val);
        debug("%d:      got %s", i, Json.to_string(node, true));
#endif

        // Note: == just checks for pointer equality, not equality
        // of the contained values.  Do it brute-force.
        switch(i) {
        case 0:
          assert_true(val.type() == GLib.Type.DOUBLE);
          assert_cmpfloat(val.get_double(), EQ, values[0].get_double());
          break;
        case 1:
          assert_true(val.type() == GLib.Type.STRING);
          assert_cmpstr(val.get_string(), EQ, values[1].get_string());
          break;
        case 2:
          assert_true(val.type() == GLib.Type.BOOLEAN);
          assert_true(val.get_boolean() == values[2].get_boolean());
          break;
        default:
          assert_not_reached(); // LCOV_EXCL_LINE
        }
      }
    } // lists

    // TODO MAP

    vm.SetSlotNull(0);
    v = Marshal.value_from_slot(vm, 0);
    assert_true(v.type() == Wren.get_null_type());

    vm.SetSlotString(0, "hello");
    v = Marshal.value_from_slot(vm, 0);
    assert_true(v.type() == GLib.Type.STRING);
    assert_true(v.get_string() == "hello");

    // Marshal.values_from_slots()
    vm.EnsureSlots(3);

    vm.SetSlotBool(0, true);
    vm.SetSlotDouble(1, 42.0);
    vm.SetSlotString(2, "Yep!");
    var values = Marshal.values_from_slots(vm, 0, 3);

    assert_cmpuint(values.length, EQ, 3);
    assert_true(values[0].type() == GLib.Type.BOOLEAN);
    assert_true(values[0].get_boolean());
    assert_true(values[1].type() == GLib.Type.DOUBLE);
    assert_cmpfloat(values[1].get_double(), EQ, 42.0);
    assert_true(values[2].type() == GLib.Type.STRING);
    assert_cmpstr(values[2].get_string(), EQ, "Yep!");

  } catch(Marshal.Error e) {  // LCOV_EXCL_START - unreached if tests pass
    warning("marshalling error: %s", e.message);
    assert_not_reached();
  }   // LCOV_EXCL_STOP

  // TODO UNKNOWN

} // test_from_wren()

void test_to_wren()
{
  try {
    var vm = new_vm();
    Value val;
    vm.EnsureSlots(1);

    val = true;
    Marshal.slot_from_value(vm, 0, val);
    assert_true(vm.GetSlotBool(0));
    val = false;
    Marshal.slot_from_value(vm, 0, val);
    assert_true(!vm.GetSlotBool(0));

    val = 42;
    Marshal.slot_from_value(vm, 0, val);
    assert_cmpfloat(vm.GetSlotDouble(0), EQ, 42.0);
    // TODO other types of number

    // TODO FOREIGN, LIST, MAP

    val = Value(Wren.get_null_type());
    Marshal.slot_from_value(vm, 0, val);
    assert_cmpuint(vm.GetSlotType(0), EQ, Wren.Type.NULL);

    val = "Hello, world!";
    Marshal.slot_from_value(vm, 0, val);
    assert_cmpstr(vm.GetSlotString(0), EQ, "Hello, world!");

    // TODO UNKNOWN
  } catch(Marshal.Error e) {  // LCOV_EXCL_START - unreached if tests pass
    warning("marshalling error: %s", e.message);
    assert_not_reached();
  }   // LCOV_EXCL_STOP
} // test_to_wren()

void test_vmv_marshal()
{
  try {
    var vm = new VMV();
    vm.ensure_slots(1);

    Value val = "message";
    vm.set_slot(0, val);
    Value val2 = vm.get_slot(0);
    assert_true(val2.type() == GLib.Type.STRING);
    assert_cmpstr(val2.get_string(), EQ, val.get_string());
    assert_true(&val != &val2);  // didn't just get the same one back

    var vals = vm.get_slots();
    assert_cmpuint(vals.length, EQ, 1);
    assert_true(vals[0].type() == GLib.Type.STRING);
    assert_cmpstr(vals[0].get_string(), EQ, val.get_string());

  } catch(Marshal.Error e) {  // LCOV_EXCL_START - unreached if tests pass
    warning("marshalling error: %s", e.message);
    assert_not_reached();
  }   // LCOV_EXCL_STOP
} // test_vmv_marshal()

public static int main(string[] args)
{
  Wren.static_init();
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/150-marshal/from-wren", test_from_wren);
  Test.add_func("/150-marshal/to-wren", test_to_wren);
  Test.add_func("/150-marshal/vmv_marshal", test_vmv_marshal);

  // Make the VM
  g_conf = Wren.Configuration();
  Wren.InitConfiguration(ref g_conf);
  g_conf.writeFn = Wren.defaultWriteFn; // LCOV_EXCL_LINE - GNOME/vala#1165
  g_conf.errorFn = Wren.defaultErrorFn; // LCOV_EXCL_LINE - GNOME/vala#1165

  // Run the tests
  return Test.run();
}
