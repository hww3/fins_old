
static .TemplateContext context;

//!
static void create(string template, .TemplateContext c);

//!
public string render(.TemplateData d);

//! we should really do more here...
static string load_template(string templatename)
{
   werror("loading template " + templatename + "\n");
   string template = Stdio.read_file(
                          combine_path(context->application->config->app_dir, 
                                       "templates/" + templatename));

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
