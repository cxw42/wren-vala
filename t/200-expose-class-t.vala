// t/200-expose-class-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6


class Sample : Object, Wren.HasMethods {

  // --- How we observe Wren effects -----

  public static bool wasInitialized = false;
  public static string gMsg;
  public static unowned Object gObj;

  // --- Properties ----------------------

  public int prop { get; set; default = 42; }

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
  void join(string part2, string part1)
  {
    gMsg = part1 + part2; // opposite order of the args on purpose
  }

  /** Wren invoker for join() */
  static void wren_join(GLib.Object self, VMV vm)
  {
    ((!)(self as Sample)).join(vm.get_slot_string(1), vm.get_slot_string(2));
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
    methods["main!Sample.hello()"] = wren_sayHello;
    methods["main!Sample.stashMessage(_)"] = wren_stashMessage;
    methods["main!Sample.join(_,_)"] = wren_join;
    methods["main!Sample.$sjoin(_,_)"] = wren_sjoin;
  }
}

void test_instantiate()
{
  var vm = new Wren.VMV();

  var ok = vm.expose_class<Sample>("main");
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

  var ok = vm.expose_class<Sample>("main");
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

  var ok = vm.expose_class<Sample>("main");
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

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/200-expose-class/instantiate", test_instantiate);
  Test.add_func("/200-expose-class/methods", test_methods);
  Test.add_func("/200-expose-class/static_methods", test_static_methods);
  return Test.run();
}
