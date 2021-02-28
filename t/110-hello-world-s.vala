// t/110-hello-world-s.vala - support for test 110

using Wren; // required to pull in the headers on valac 0.50.1.79-3f2a6

public static int main(string[] args)
{
  var vmv = new Wren.VMV();
  var ok = vmv.interpret("main", """ System.print("Hello, world!") """);
  return (ok == SUCCESS) ? 0 : 1;
}
