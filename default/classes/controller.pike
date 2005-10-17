import Fins;
inherit Fins.Controller;

Fins.Controller baz = ((program)"baz_controller.pike")();

public void index(Request id, Response response, mixed ... args)
{
   Template.Template t = Template.get_template(Template.XSLT, "index.xsl");
   Template.TemplateData dta = Template.TemplateData();
   
   Public.Parser.XML2.Node n = Public.Parser.XML2.new_xml("1.0", "events");

   foreach(indices(this); int index; string name)
   {
      mixed event;
      string t;
      event = this[name];
      if(functionp(event))
      {
        t = "Event";
      }
      else if(objectp(event))
      {
        t = "Sub-Controller";
      }
      else {werror("continuing.\n"); continue; }

      object e = Public.Parser.XML2.new_node("event");
      e->new_child("name", name);
      e->new_child("type", t);
      n->add_child(e);
   }

      
   dta->add("node", n);
  response->set_template(t, dta);
}

public void foo(Request id, Response response, mixed ... args)
{
  response->set_data("foo! %O", args);
}

private void bar(Request id, Response response, mixed ... args)
{
  response->set_data("bar");
}
