inherit Fins.FinsBase;
import Protocols.HTTP.Server;
import Tools.Logging;

//! this is the base Controller class in Fins. The controller is used to map incoming requests
//! to functions that are called to handle the request.
//!
//! event methods have this signature:
//!
//!  void func(Fins.Request request, Fins.Response response, 
//!            mixed ... args);
//!
//! where func is the name of the event that will trigger the event function to be called.
//!
//! @note
//!   When using FinServe, an event that produces no output will return a "unable to find a handler" 
//!   404 error. The event will still fire, though.

Log.Logger log = get_logger("fins.controller");

//! set this to zero to avoid session redirects
constant __uses_session = 1;

//! set this to zero to prevent this controller from being cached in the request-to-controller mapping.
constant __is_cacheable = 1;

int __last_load;

string __controller_source;
string __controller_name;

array __before_filters = ({});
array __after_filters = ({});
array __around_filters = ({});

//! Mapping of action names to actions.
//!
//! By default, actions are looked up in a controller class by index. Sometimes, it's not possible
//! to create such an index, such as when the desired index is a reserved word like 'object', or one already
//! present in the controller but with a different purpose, like 'start'.
//!
//! An entry may be placed in this mapping and it will be used as though there were a class member with the same name.
//!
//! The presence of an entry in this mapping for a given action will take priority over any action
//! defined within the controller class.
mapping(string:function|string|object) __actions = ([]);

//! loads the controller, providing support for auto-reload of
//! updated controller classes.
//!
//! @note
//!   also exists in Fins.Application... we should fix this.
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

  if(!c) log->error("Unable to load controller %s", controller_name);

  
  object o = c(app);
  o->__controller_name = cn;
  o->__controller_source = f;
  return o;
}


//! adds a filter to be run after the event method for a request is called.
//! 
//! @param filter
//!   either an object that provides a method "filter" or a function. either the 
//!   function "filter" in the object, or the method itself should have the following
//!   signature:
//!
//!  int filter(object request, object response, mixed ... args)
//!
//!   a filter should return a true value if the filter was a success. otherwise, false (zero)
//!   should be returned, and the request will not be handled further. returning false indicates
//!   the filter wishes to perform a redirect or render function in order to preempt the request.
static void before_filter(function|object filter)
{
  __before_filters += ({ filter });
}

//! adds a filter to be run both before and after the event method for a request.
//! 
//! @param filter
//!   either an object that provides a method "filter" or a function. either the 
//!   function "filter" in the object, or the method itself should have the following
//!   signature:
//!
//!  int filter(function yield, object request, object response, mixed ... args)
//!
//!   at the point in the filter processing that the event should be called, yield() should be 
//!   called without arguments.
//!
//!   a filter should return a true value if the filter was a success. otherwise, false (zero)
//!   should be returned, and the request will not be handled further. returning false indicates
//!   the filter wishes to perform a redirect or render function in order to preempt the request.
//!
//!   around filters may be nested, in which case the first added around filter will be called closest
//!   to the event in the controller, and subsequent filters will be called surrounding it.
static void around_filter(function|object filter)
{
  __around_filters += ({ filter });
}


//! adds a filter to be run after the event method for a request is called.
//! 
//! @param filter
//!   either an object that provides a method "filter" or a function. either the 
//!   function "filter" in the object, or the method itself should have the following
//!   signature:
//!
//!  int filter(object request, object response, mixed ... args)
//!
//!   a filter should return a true value if the filter was a success. otherwise, false (zero)
//!   should be returned, and the request will not be handled further. returning false indicates
//!   the filter wishes to perform a redirect or render function in order to preempt the request.
static void after_filter(function|object filter)
{
  __after_filters += ({ filter });
}

//! it is not recommended that you override this method. use the start()
//!  method to load up your controllers.
static void create(object a)
{  
  log->debug("%O->create()", this);
  __last_load = time();
  ::create(a);

  if(functionp(start))
  {
  //  log->debug("scheduling startup of controller %O.\n", this);
    call_out(start, 0);
  }
}

//! the preferred method from which controllers are loaded.
//!
//! @seealso
//!  @[load_controller]
static void start()
{
}

//! causes control of the application to be yielded to any connected breakpoint client.
//! the breakpoint client may examine and or modify the request or response before passing
//! control back to the application.
static void breakpoint(string desc, object id, object response, 
                           void|mapping args)
{
  app->breakpoint(desc, (["app": app, "cache": cache, "model": model, 
      "view": view, "controller": this, "id": id, "response": response]) + 
              (args?args:([])));
}

//! returns a string containing the absolute URI to the desired event function or controller.
static string action_url(function|object action, array|void args, mapping|void vars)
{
  return app->url_for_action(action, args, vars);
}

// this is used with the __actions mapping to provide an alternate way to define event handlers.
protected mixed `[](mixed arg, mixed|void arg2)
{
werror("arg=%s: %O, %O\n",arg,  __actions[arg], ::`[](arg,2));
    return __actions[arg] || ::`[](arg, arg2||2);
}
