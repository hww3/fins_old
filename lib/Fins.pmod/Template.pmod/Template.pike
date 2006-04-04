
static .TemplateContext context;

//!
static void create(string template, .TemplateContext c);

//!
public string render(.TemplateData d);

static int template_updated(string templatename, int last_update)
{
   string template =
                          combine_path(context->application->config->app_dir, 
                                       "templates/" + templatename);

   object s = file_stat(template);

   if(s && s->mtime > last_update)
     return 1;

   else return 0;
}

//! we should really do more here...
static string load_template(string templatename, void|object compilecontext)
{
//   werror("loading template " + templatename + " from " + context->application->config->app_dir + "\n");
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
