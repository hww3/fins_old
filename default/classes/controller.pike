import Fins;
inherit Fins.Controller;

Fins.Controller baz = ((program)"baz_controller.pike")();
object gazonk = Stdio.File();

public void index(Request id, Response response, mixed ... args)
{
  response->set_data("hello!\n");
}

public void foo(Request id, Response response, mixed ... args)
{
  response->set_data("foo! %O", args);
}

private void bar(Request id, Response response, mixed ... args)
{
  response->set_data("bar");
}
