// t/200-expose-class-t.vala

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6


class Sample : Object {
  public static bool wasInitialized = false;

  public int prop {get; set; default = 42; }
  construct {
    wasInitialized = true;
    debug("Initialized!");
  }

  ~Sample() {
    debug("Dtor");
  }
}

void test_instantiate()
{
  var vm = new Wren.VMV();

  var ok = vm.expose_class<Sample>("main");
  assert_true(ok == SUCCESS);

  ok = vm.interpret("main", """
                        var Obj = Sample.new()
                        //var Prop = Obj.prop
                        """);
  assert_true(ok == SUCCESS);
  assert_true(Sample.wasInitialized);
}

public static int main(string[] args)
{
  Test.init(ref args);
  Test.set_nonfatal_assertions();
  Test.add_func("/200-expose-class/instantiate", test_instantiate);
  return Test.run();
}
