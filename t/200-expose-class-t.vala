// t/200-expose-class-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

class Sample : Object, Wren.HasMethods {

  // --- How we observe Wren effects -----

  public static bool wasInitialized = false;
  public static string gMsg;
  public static unowned Object gObj;
  public static int gPropValue = 42;

  // --- Properties ----------------------

  public int prop {
    get { return gPropValue; }
    set { gPropValue = value; }
  }

  // --- Ctor/dtor -----------------------
  construct {
    wasInitialized = true;
    debug("Initialized!");
  }

  ~Sample() {
    debug("Dtor");
  }

  // --- Methods -------------------------

  /** Wren-visible function of no args */
  void sayHello()
  {
    gMsg = "Hello, world!";
    gObj = this;
  }

  /** Wren invoker for sayHello() */
  static void wren_sayHello(GLib.Object self, VMV vm)
  {
    ((!)(self as Sample)).sayHello();
  }

  /** Wren-visible function of one arg */
  void stashMessage(string msg)
  {
    gMsg = msg;
  }

  /** Wren invoker for sayHello() */
  static void wren_stashMessage(GLib.Object self, VMV vm)
  {
    ((!)(self as Sample)).stashMessage(vm.get_slot_string(1));
  }

  /** Wren-visible function of two args */
  string join(string part2, string part1)
  {
    gMsg = part1 + part2; // opposite order of the args on purpose
    return gMsg + "joined";
  }

  /** Wren invoker for join() */
  static void wren_join(GLib.Object self, VMV vm)
  {
    var retval = ((!)(self as Sample)).join(vm.get_slot_string(1), vm.get_slot_string(2));
    vm.set_slot_string(0, retval);
  }

  /** Wren-visible STATIC function of two args */
  static void sjoin(string part2, string part1)
  {
    gMsg = "static" + part1 + part2; // opposite order of the args on purpose
  }

  /** Wren invoker for join() */
  static void wren_sjoin(GLib.Object self, VMV vm)
  {
    sjoin(vm.get_slot_string(1), vm.get_slot_string(2));
  }

  /** Tell Wren about our methods */
  public void get_methods(ref HashTable<string, MethodImpl> methods)
  {
    methods["hello()"] = wren_sayHello;
    methods["stashMessage(_)"] = wren_stashMessage;
    methods["join(_,_)"] = wren_join;
    methods["static sjoin(_,_)"] = wren_sjoin;
  }
}

void test_instantiate()
{
  var vm = new Wren.VMV();

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  Sample.wasInitialized = false;
  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        //var Prop = Obj.prop
                        """);
  assert_true(ok == SUCCESS);
  assert_true(Sample.wasInitialized);
}

void test_methods()
{
  var vm = new Wren.VMV();

  Sample.gMsg = null;
  Sample.gObj = null;

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  // No args
  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        Obj.hello()
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpstr(Sample.gMsg, EQ, "Hello, world!");
  assert_true(Sample.gObj != null);

  // One arg
  Sample.gMsg = null;
  ok = vm.interpret("main", """
                        Obj.stashMessage("Yep!")
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpstr(Sample.gMsg, EQ, "Yep!");

  // Two args
  Sample.gMsg = null;
  ok = vm.interpret("main", """
                        Obj.join("A","B")
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpstr(Sample.gMsg, EQ, "BA");
}

void test_static_methods()
{
  var vm = new Wren.VMV();

  Sample.gMsg = null;
  Sample.gObj = null;

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  // Instance function
  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        Obj.join("A","B")
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpstr(Sample.gMsg, EQ, "BA");

  // Static function
  ok = vm.interpret("main", """
                        Sample.sjoin("C","D")
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpstr(Sample.gMsg, EQ, "staticDC");
}

void test_retvals()
{
  var vm = new Wren.VMV();

  Sample.gMsg = null;
  Sample.gObj = null;

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  // Instance function
  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        var Ret = Obj.join("A","B")
                        """);
  assert_true(ok == SUCCESS);
  vm.ensure_slots(1);
  vm.get_variable("main", "Ret", 0);
  assert_true(vm.get_slot_type(0) == Wren.Type.STRING);
  assert_cmpstr(vm.get_slot_string(0), EQ, "BAjoined");
}

void test_properties()
{
  var vm = new Wren.VMV();

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);

  assert_cmpint(Sample.gPropValue, EQ, 42);

  // Set
  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        Obj.prop = 128
                        """);
  assert_true(ok == SUCCESS);
  assert_cmpint(Sample.gPropValue, EQ, 128);

  // Get
  Sample.gPropValue = 1337;
  ok = vm.interpret("main", """
                        var Got = Obj.prop
                        """);
  assert_true(ok == SUCCESS);

  vm.ensure_slots(1);
  vm.get_variable("main", "Got", 0);
  assert_true(vm.get_slot_type(0) == Wren.Type.NUM);
  assert_cmpfloat(vm.get_slot_double(0), EQ, 1337);
}

void test_add_type_succeeds_twice()
{
  var vm = new Wren.VMV();

  var ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);
  ok = vm.expose_class(typeof(Sample), "main");
  assert_true(ok == SUCCESS);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();

  Test.add_func("/200-expose-class/instantiate", test_instantiate);
  Test.add_func("/200-expose-class/methods", test_methods);
  Test.add_func("/200-expose-class/static_methods", test_static_methods);
  Test.add_func("/200-expose-class/retvals", test_retvals);
  Test.add_func("/200-expose-class/properties", test_properties);
  Test.add_func("/200-expose-class/add_type_succeeds_twice", test_add_type_succeeds_twice);

  return Test.run();
}
