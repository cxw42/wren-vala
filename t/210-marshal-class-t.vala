// t/200-marshal-class-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

class Sample : Object, Wren.HasMethods {

  // --- How we observe Wren effects -----

  public static bool wasInitialized = false;
  public string instanceMessage;

  // --- Ctor/dtor -----------------------
  construct {
    wasInitialized = true;
    debug("Initialized!");
  }

  ~Sample() {
    debug("Dtor");
  }

  // --- Methods -------------------------

  /** Wren accessor for instanceMessage */
  static void wren_get_message(GLib.Object self, VMV vm)
  {
    var instance = (!)(self as Sample);
    vm.ensure_slots(1);
    vm.set_slot_string(0,instance.instanceMessage);
  }

  public void stash_message(string msg)
  {
    instanceMessage = msg;
  }

  /** Tell Wren about our methods */
  public void get_methods(ref HashTable<string, MethodImpl> methods)
  {
    methods["getMessage"] = wren_get_message;
  }
}

void test_from_wren()
{
  try {
    var vmv = new Wren.VMV();

    var ok = vmv.expose_class(typeof(Sample), "main");
    assert_true(ok == SUCCESS);

    Sample.wasInitialized = false;
    ok = vmv.interpret("main", """
                          var Obj = Sample.new()
                          """);
    assert_true(ok == SUCCESS);
    assert_true(Sample.wasInitialized);

    vmv.ensure_slots(1);
    vmv.get_variable("main", "Obj", 0);
    assert_true(vmv.get_slot_type(0) == Wren.Type.FOREIGN);

    unowned var vm = vmv.raw_vm();
    assert_nonnull(vm);
    var obj_val = Marshal.value_from_slot(vm, 0);
    assert_true(obj_val.type() == GLib.Type.OBJECT);
    var sample = obj_val.get_object() as Sample;
    assert_nonnull(sample);

    // TODO make sure modifications to `sample` are visible in Wren
    sample.stash_message("from Vala");
    ok = vmv.interpret("main", """
                          if(Obj.getMessage != "from Vala") {
                            Fiber.abort("mismatch: got '%(Obj.getMessage)'")
                          }
                          """);
    assert_true(ok == SUCCESS);

  } catch(Marshal.Error e) {  // LCOV_EXCL_START - unreached if tests pass
    warning("marshalling error: %s", e.message);
    assert_not_reached();
  }   // LCOV_EXCL_STOP

} // test_from_wren()

void test_to_wren()
{
  var vmv = new Wren.VMV();

  var ok = vmv.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  var s = new Sample();
  vmv.ensure_slots(1);
  try {
    Marshal.slot_from_value(vmv.raw_vm(), 0, s);
    assert_not_reached(); // LCOV_EXCL_LINE - unreachable on a successful test
  } catch(Marshal.Error e) {
    debug("got error: %s\n", e.message);
    assert_true(e is Marshal.Error.EINVAL);
  }

} // test_to_wren()

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();

  Test.add_func("/210-marshal-class/from_wren", test_from_wren);
  Test.add_func("/210-marshal-class/to_wren", test_to_wren);

  return Test.run();
}
