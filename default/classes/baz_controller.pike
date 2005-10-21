import Fins;
inherit Fins.Controller;


public void index(Request id, Response response, mixed ... args)
{
  response->set_data("hello from baz!\n");
}

public void foo(Request id, Response response, mixed ... args)
{
   Template.Template t = Template.get_template(Template.Simple, "baz_foo.tpl");
   Template.TemplateData d = Template.TemplateData();
   
   d->set_data((["test": "Seventy Six Trombones", "val": "marching band", "loop": ({ (["blah": "Trumpets"]), (["blah": "Drums"])  }) ]));

   response->set_template(t, d);
}

public void gazonk(Request id, Response response, mixed ... args)
{
   response->redirect("foo");
}
