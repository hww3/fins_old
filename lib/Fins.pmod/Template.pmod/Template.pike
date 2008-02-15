import Tools.Logging;

static .TemplateContext context;

//!
static void create(string template, .TemplateContext c)
{
   context = c;
   context->type = object_program(this);
}

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
  string int_templatename;
  int is_internal;

  if(has_prefix(templatename, "internal:"))
  {
    is_internal = 1;
    if(has_suffix(templatename, ".phtml")) 
      int_templatename = templatename[9..sizeof(templatename)-7];
    templatename = replace(templatename[9..], "_", "/");
  }


//   werror("loading template " + templatename + " from " + context->application->config->app_dir + "\n");
  Log.debug("Loading template %s.", templatename);
    template = Stdio.read_file(
                          combine_path(context->application->config->app_dir, 
                                       "templates/" + templatename));

  if((!template || !sizeof(template)) && is_internal)
  {
    template = load_internal_template(int_templatename, compilecontext);
  }

  if(!template || !sizeof(template))
   {
     throw(Fins.Errors.Template("Template does not exist or is empty: " + templatename + "\n"));
   }
   return template;
}

string load_internal_template(string inttn, void|object context)
{
  Log.debug("Loading internal template %s.", (string)inttn);
  return Fins.Helpers.InternalTemplates[inttn];
}

public string get_type()
{
  return "text/html";
}
