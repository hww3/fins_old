import Fins;
inherit Fins.Controller;


public void index(Request id, Response response, mixed ... args)
{
  response->set_data("hello from baz!\n");
}

public void foo(Request id, Response response, mixed ... args)
{
   Template.Template t = Template.Template("baz_foo.tpl");
   t->set_data((["test": "testresult", "loop": ({ (["val": "loop1"]), (["val": "loop2"])  }) ]));
   response->set_template(t);
}

public void gazonk(Request id, Response response, mixed ... args)
{
   response->redirect("foo");
}
