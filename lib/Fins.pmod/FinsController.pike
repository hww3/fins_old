inherit Fins.FinsBase;
import Protocols.HTTP.Server;
import Tools.Logging;

//! methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!

//! set this to zero to avoid session redirects
constant __uses_session = 1;
int __last_load;

string __controller_source;

array __before_filters = ({});
array __after_filters = ({});

//! loads the controller, providing support for auto-reload of
//! updated controller classes.
//!
//! @example
//!  Fins.FinsController foo;
//!
//!  void start()
//!  {
//!    foo = load_controller("foo_controller");
//!  } 
static object load_controller(string controller_name)
{
  program c;
  string cn;
  string f;

  cn = controller_name;

  if(!has_suffix(cn, ".pike"))
    cn = cn + ".pike";

  foreach( ({""}) + master()->pike_program_path;; string p)
  {
    f = Stdio.append_path(p, cn);
    object stat = file_stat(f);
     
    if(stat && stat->isreg)
    {
      break;
    }
    else f = 0;
  }

  if(f)
  {
    c = compile_string(Stdio.read_file(f), f);
  }
  else return 0;

  if(!c) Log.error("Unable to load controller %s", controller_name);

  
  object o = c(app);
  o->__controller_source = f;
  return o;
}

//!
static void before_filter(function|object filter)
{
  __before_filters += ({ filter });
}

//!
static void after_filter(function|object filter)
{
  __after_filters += ({ filter });
}

//! it is not recommended that you override this method. use the start()
//!  method to load up your controllers.
static void create(.Application a)
{  
  __last_load = time();
  ::create(a);

  if(functionp(start))
    start();
}

//! the preferred method from which controllers are loaded.
static void start()
{
}

//!
static void breakpoint(string desc, object id, object response, 
                           void|mapping args)
{
  app->breakpoint(desc, (["app": app, "cache": cache, "model": model, 
      "view": view, "controller": this, "id": id, "response": response]) + 
              (args?args:([])));
}

