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


class _error_handler {

  //!
  void compile_error(string a,int b,string c);

  //!
  void compile_warning(string a,int b,string c);
}

array(_error_handler) compile_error_handlers = ({});

//!
void push_compile_error_handler( _error_handler q )
{
  compile_error_handlers = ({q})+compile_error_handlers;
}

//!
void pop_compile_error_handler()
{
  compile_error_handlers = compile_error_handlers[1..];
}


class LowErrorContainer
{
  string d;
  string errors="", warnings="";
  int has_errors;

  string get()
  {  
    return errors;
  }

  //!
  string get_warnings()
  {
    return warnings;
  }
  
  //!
  void print_warnings(string prefix) {
    if(warnings && strlen(warnings))
      werror(prefix+"\n"+warnings);
  }

  //!
  void got_error(string file, int line, string err, int|void is_warning)
  {
	has_errors++;
    if (file[..sizeof(d)-1] == d) {
      file = file[sizeof(d)..];
    }
    if( is_warning)
      warnings+= sprintf("%s:%s\t%s\n", file, line ? (string) line : "-", err);
    else
      errors += sprintf("%s:%s\t%s\n", file, line ? (string) line : "-", err);
  }

  //!
  void compile_error(string file, int line, string err)
  {
    got_error(file, line, "Error: " + err);
  }

  //!
  void compile_warning(string file, int line, string err)
  {
    got_error(file, line, "Warning: " + err, 1);
  }

  //!
  void create()
  {
    d = getcwd();
    if (sizeof(d) && (d[-1] != '/') && (d[-1] != '\\'))
      d += "/";
  }
}

//! @appears ErrorContainer
class ErrorContainer
{
  inherit LowErrorContainer;

  //!
  void compile_error(string file, int line, string err)
  {
//	werror("compile_error()\n");
	    if( sizeof(compile_error_handlers) )
	      compile_error_handlers->compile_error( file,line, err );
	    else
	      ::compile_error(file,line,err);
  }  

	  //!
	  void compile_warning(string file, int line, string err)
	  {
	    if( sizeof(compile_error_handlers) )
	      compile_error_handlers->compile_warning( file,line, err );
	    else
	      ::compile_warning(file,line,err);
	  }
}

