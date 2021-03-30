// t/150-marshal-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

private Wren.VM g_vm;

// Test reading Wren data into a GValue
void test_from_wren()
{
  Value v;
  g_vm.EnsureSlots(1);

  g_vm.SetSlotBool(0, true);
  v = Marshal.to_value_raw(g_vm, 0);
  assert_true(v.type() == GLib.Type.BOOLEAN);
  assert_true(v.get_boolean());

  g_vm.SetSlotDouble(0, 42);
  v = Marshal.to_value_raw(g_vm, 0);
  assert_true(v.type() == GLib.Type.DOUBLE);
  assert_cmpfloat(v.get_double(), EQ, 42);

  // TODO FOREIGN, LIST, MAP

  g_vm.SetSlotNull(0);
  v = Marshal.to_value_raw(g_vm, 0);
  assert_true(v.type() == Wren.get_null_type());

  g_vm.SetSlotString(0, "hello");
  v = Marshal.to_value_raw(g_vm, 0);
  assert_true(v.type() == GLib.Type.STRING);
  assert_true(v.get_string() == "hello");

  // TODO UNKNOWN

} // test_from_wren

public static int main(string[] args)
{
  Wren.static_init();
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/150-marshal/from-wren", test_from_wren);

  // Make the VM
  var conf = Wren.Configuration();
  Wren.InitConfiguration(ref conf);
  conf.writeFn = Wren.defaultWriteFn;
  conf.errorFn = Wren.defaultErrorFn;

  g_vm = new Wren.VM(conf);
  assert_nonnull(g_vm);
  if(g_vm == null) {
    print("# Could not create VM\n");
    return 1;
  }

  // Run the tests
  return Test.run();
}
