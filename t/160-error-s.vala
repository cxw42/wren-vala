// t/160-error-s.vala - support for test 160

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

public static int main(string[] args)
{
  if(args.length != 2) {
    error("Usage: %s WHICHTEST", args[0]);
  }

  if(args[1] == "noSuchMethod") { // runtime error
    var vmv = new Wren.VMV();
    var ok = vmv.interpret("main", """ 123.noSuchMethod """);
    return (ok == SUCCESS) ? 1 : 0;

  } else if(args[1] == "compiletime") { // compile-time error
    var vmv = new Wren.VMV();
    var ok = vmv.interpret("main", """ ! """);
    return (ok == SUCCESS) ? 1 : 0;

  } else {
    error("Unknown test type %s", args[1]);
  }
}
