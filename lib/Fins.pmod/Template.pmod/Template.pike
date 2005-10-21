//!
static void create(string template);

//!
public string render(.TemplateData d);

//! we should really do more here...
static string load_template(string templatename)
{
   werror("loading template " + templatename + "\n");
   string template = Stdio.read_file("templates/" + templatename);

   if(!template || !sizeof(template))
   {
     throw(Error.Generic("Template " + templatename + " is empty.\n"));
   }
   return template;
}

public string get_type()
{
  return "text/html";
}
