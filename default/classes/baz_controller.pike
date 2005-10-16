import Fins;
inherit Fins.Controller;


public void index(Request id, Response response, mixed ... args)
{
  response->set_data("hello from baz!\n");
}

public void foo(Request id, Response response, mixed ... args)
{
   Template.Template t = Template.get_template(Template.Simple, "baz_foo.tpl");
   
   t->set_data((["test": "Seventy Six Trombones", "val": "Marching Band", "loop": ({ (["blah": "Trumpets"]), (["blah": "Drums"])  }) ]));
   response->set_template(t);
}

public void gazonk(Request id, Response response, mixed ... args)
{
   response->redirect("foo");
}
