import Fins;
inherit Fins.Controller;


public void index(Request id, Response response, mixed ... args)
{
  response->set_data("hello from baz!\n");
}

public void foo(Request id, Response response, mixed ... args)
{
  response->set_data(sprintf("foobaz! %O", args));
}

public void gazonk(Request id, Response response, mixed ... args)
{
}
