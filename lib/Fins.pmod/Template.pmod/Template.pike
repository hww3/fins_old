
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
  string template;

  if(has_prefix(templatename, "internal:"))
  {
    if(has_suffix(templatename, ".phtml")) 
      templatename = templatename[9..sizeof(templatename)-7];
    template = load_internal_template(templatename, compilecontext);
  }
  else
  {
//   werror("loading template " + templatename + " from " + context->application->config->app_dir + "\n");
    template = Stdio.read_file(
                          combine_path(context->application->config->app_dir, 
                                       "templates/" + templatename));
  }
   if(!template || !sizeof(template))
   {
     werror("!Template Error!\n");
     throw(Fins.Errors.Template("Template does not exist or is empty: " + templatename));
   }
   return template;
}

string load_internal_template(string inttn, void|object context)
{
  return Fins.Helpers.InternalTemplates[inttn];
}

public string get_type()
{
  return "text/html";
}
