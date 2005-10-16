import Fins;
inherit Fins.Controller;

Fins.Controller baz = ((program)"baz_controller.pike")();

public void index(Request id, Response response, mixed ... args)
{
   Template.Template t = Template.get_template(Template.XSLT, "index.xsl");
   Template.TemplateData dta = Template.TemplateData();
   
   Public.Parser.XML2.Node n = Public.Parser.XML2.new_xml("1.0", "catalog");
   
   n->new_child("cd", "");
   n->new_child("cd", "");
   
   int i = 1;
   
   foreach(n->children(), Public.Parser.XML2.Node cd)
   {
      cd->new_child("title", "Greatest Hits Volume " + i);
      cd->new_child("artist", "Juice Newton");

      i++;
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
