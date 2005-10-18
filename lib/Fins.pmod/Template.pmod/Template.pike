//!
static void create(string template);

//!
public string render(.TemplateData d);

//! we should really do more here...
static string load_template(string templatename)
{
   werror("loading template " + templatename);
   string template = Stdio.read_file("templates/" + templatename);
   return template;
}

public string get_type()
{
  return "text/html";
}
