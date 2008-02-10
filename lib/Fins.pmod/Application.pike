import Fins;
import Tools.Logging;

//! this is the base application class.

object __fin_serve;
string context_root = "";

//! The root Controller object
.FinsController controller;

//!
.FinsModel model;

//!
.FinsView view;

//!
.FinsCache cache;

//!
string static_dir;

//!
.Configuration config;

//!
Fins.Helpers.Filters.Compress _gzfilter;

static mapping processors = ([]);
static mapping controller_path_cache = ([]);
static mapping action_path_cache = ([]);
static mapping event_cache = ([]);

// breakpointing support
Stdio.Port breakpoint_port;
int breakpoint_port_no = 3333;
Stdio.File breakpoint_client;
object bp_key;
object breakpoint_cond;
object bp_lock = Thread.Mutex();
object breakpoint_hilfe;
object bpbe;
object bpbet;
int cache_events = 1;

static int exp = 24 * 10;

//! constructor for the Fins application. It is normally not necessary to override this method,
//! as @[start]() will be called immediately from this method.
static void create(.Configuration _config)
{
  config = _config;
  static_dir = Stdio.append_path(config->app_dir, "static");

  if(config["application"] && config["application"]["context_root"])
    context_root = config["application"]["context_root"];

  cache_events = (int)config["controller"]["cache_events"];
  exp = (int)config["application"]["static_expire_period"] || (24*10);

  load_breakpoint();
  load_cache();
  load_model();
  load_view();
  load_processors();
  load_controller();

#if constant(Fins.Helpers.Filters.Compress)
  _gzfilter = Fins.Helpers.Filters.Compress();
#endif

  start();
}

//! this method will be called after the cache, model, view and 
//! controller have been loaded. this is the recommended extension point for application startup.
void start()
{
}

static void load_processors()
{
  if(config["processors"] && config["processors"]["class"])
  {
     mixed plist = config["processors"]["class"];
  
     if(stringp(plist))
       plist = ({ plist });

  	 foreach(plist;; string proc)
 	   load_processor(proc);

  }
}

static void load_processor(string proc)
{
  object processor;

  if(proc)
    processor = ((program)proc)(this);
  else Log.debug("No processor defined!");

  if(!Program.implements(object_program(processor), Fins.Processor))
  {
    Log.error("class %s does not implement Fins.Processor.", proc);
  }
  else
  {
    foreach(processor->supported_protocols();; string protocol)
    {
      Log.info("Loaded processor for " + protocol);
      processors[protocol] = processor;
    }
  }   

  processor->start();
}

//! returns the processor object for a given protocol. typically used with integration processors such as 
//! @[StompProcessor].
public object get_processor(string protocol)
{
  return processors[protocol];
}

static void load_breakpoint()
{
  if(config["application"] && (int)config["application"]["breakpoint"])
  {
    bpbe = Pike.Backend();
    bpbet = Thread.Thread(lambda(){ do { catch(bpbe()); } while (1); });

    if((int)config["application"]["breakpoint_port"]) breakpoint_port_no = (int)config["application"]["breakpoint_port"];
    Log.info("Starting Breakpoint Server on port %d.", breakpoint_port_no);
    breakpoint_port = Stdio.Port(breakpoint_port_no, handle_breakpoint_client);
    breakpoint_port->set_backend(bpbe);
  }
}

static void load_cache()
{
  Log.info("Starting Cache.");

  cache = .FinsCache();
}

static void load_view()
{
  string viewclass = (config["view"] ? config["view"]["class"] :0);
  if(viewclass)
    view = ((program)viewclass)(this);
  else Log.debug("No view defined!");
}

static object low_load_controller(string controller_name)
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

  
  object o = c(this);
  o->__controller_name = cn;
  o->__controller_source = f;
  return o;
}

//! loads the controller, providing support for auto-reload of
//! updated controller classes. normally, a controller will call its local
//! @[FinsController.load_controller]() method.
//!
//! @example
//!  Fins.FinsController foo;
//!
//!  void start()
//!  {
//!    foo = load_controller("foo_controller");
//!  } 
static void load_controller()
{
  Log.debug("%O->load_controller()", this);
  string conclass = (config["controller"]? config["controller"]["class"] :0);
  if(conclass)
  {
	controller = low_load_controller(conclass);
// 	string conclassn = conclass;
// 	if(!file_stat("classes/" + conclass)) conclassn = conclass + ".pike";
// 
//     controller = (compile_file(conclass))(this);
//     controller->__controller_source = combine_path("classes" , conclassn);
//     controller->__controller_name = conclass;
// 
  }
  else Log.debug("No controller defined!");
}

static void load_model()
{
  string modclass = (config["model"] ? config["model"]["class"] : 0);
  if(modclass)
  {
    Log.info("loading model from " + modclass);
    model = ((program)modclass)(this);
  }
  else Log.debug("No model defined!");
}

int controller_updated(object controller, object container, string cn)
{
  if (!controller || !controller->__controller_source) return 0;

  object stat = file_stat(combine_path(config->app_dir, controller->__controller_source));

  if(stat && stat->mtime > controller->__last_load)
  {
    Log.debug("Reloading controllers: %O", container);
	if(object_program(container) == object_program(this))
	  load_controller();
    container->start();
    action_path_cache = ([]);
    controller_path_cache = ([]);
    return 1;
  }

  return 0;
}

//! gets the controller object which will handle a given path,  not
//! including any context root.
//! 
//! @param controller
//!   an optional controller for use with relative paths. if provided, the path will be calculated
//!   relative to this controller in the virutal filespace.
//!
object get_controller_for_path(string path, object|void controller)
{
  if(!controller || path[0] == '/') controller = this->controller;

  foreach(path/"/"; int x; string comp)
  {
    controller = controller[comp];
    if(!controller || !objectp(controller)) return 0;
  }

  if(!controller || !objectp(controller)) return 0;
  else return controller;
}

//! get the path associated with a controller object
//!
//! @returns
//!  the path to the controller relative to the root of the
//!  application. does not include any context root.
string get_path_for_controller(object _controller)
{
  string path;
  array pcs = ({});
  if(controller_path_cache[_controller])
    return controller_path_cache[_controller];

  if(controller == _controller)
    path = "/";

  else
  {
    array x = ({_controller});
    int i = 0;
    object c = _controller;
    do
    {
      object p = find_parent_controller(c);
      if(!p)
        break;
      else x += ({p});
      c = p;
      i++;
    } while(i < 100);
    foreach(x;int i; object pc)
    {
      if(pc == controller) pcs += ({""});
      else pcs += ({ search(mkmapping(indices(x[i+1]),values(x[i+1])), pc) });
    }

   path = reverse(pcs)*"/";
  }  


  controller_path_cache[_controller] = path;
  return path;
}

//! find the controller which contains this controller object.
object find_parent_controller(object c)
{
  object parent = lookingfor(c, controller);

  return parent;
}

private object lookingfor(object o, object in)
{
  foreach(indices(in);int i; mixed x)
  {
    if(in[x] == o) return in;
    if(objectp(in[x]) && Program.inherits(object_program(in[x]), Fins.FinsController))
    {
      mixed r = lookingfor(o, in[x]);
      if(r) return r;
    } 
  }

  return 0;
}

//! get the path for a given controller object or handler method.
//!
//! @param action
//!   a controller or handler method
//! @param nocontextroot
//!   if true, do not prepend the application's context root to the path
string get_path_for_action(function|object action, int|void nocontextroot)
{
  string path;

    if(functionp(action))
    {
      object c = function_object(action);
      string path1 = get_path_for_controller(c);
      path = combine_path(nocontextroot?"":context_root, path1, function_name(action));
    }
    else
      path = combine_path(nocontextroot?"":context_root, get_path_for_controller(action));

  return path;
}

//! get a fully formatted path string for an action
//!
//! @param action
//!   a controller or handler method
//!
//! @param args
//!   optional arguments to be passed as path info 
//!
//! @param vars
//!    optional variables to be passed as part of the query string
//!
//! @example
//! > mixed action = application->controller->space->index;
//! > action;
//! (1) Result: app_controller.pike()->index
//! > application->url_for_action(action, 0, (["variable": 1]));
//! (2) Result: "/space/index?variable=1"

//!
string url_for_action(function|object action, array|void args, mapping|void vars)
{
  string path;
  if(!(path = action_path_cache[action]))
  {
    path = get_path_for_action(action);
    action_path_cache[action] = path;
  }

  if(args)
    path = combine_path(path, args*"/");

  if(vars)
    path = add_variables_to_path(path, vars);

  return path;
}

//!
public string add_variables_to_path(string path, mapping vars)
{
  if(vars)
  {
    array e = ({});
    foreach(vars; string k;string v)
      e += ({(k + "=" + v)});
    path += "?" + (e*"&");
  }
  return path;
}

//! main request handling method. passes http requests to the internal
//! http request handler and other types of request to external 
//! processors, if defined in the application configuration.
public mixed handle_request(.Request request)
{
  object processor;

  request->fins_app = this;
  request->controller_path="";

  //  Log.info("SESSION INFO: %O", request->misc->session_variables);

  if(request->low_protocol == "HTTP")
  {
    return handle_http(request);
  }
  else if (processor = processors[request->low_protocol])
  {
    return processor->handle(request);
  }

}

//!
public mixed handle_http(.Request request)
{
  function event;

  // we have to short circuit this one...
  if(request->not_query == "/favicon.ico")
  {
    request->not_query = "/static/favicon.ico";
    return static_request(request)->get_response();
  }

  if(has_prefix(request->not_query, "/static/"))
  {
    return static_request(request)->get_response();
  }

  array x = get_event(request);

  if(sizeof(x)>=1)
    event = x[0];

  array args = ({});

  if(sizeof(x)>1)
    args = x[1..];

  .Response response = .Response(request);

  if(!request->misc->session_variables)
    request->misc->session_variables = ([]);

  if(objectp(event) || functionp(event))
  {
    mixed er;
    er = catch
    {
      event(request, response, @args);
      mixed r = response->get_response();
      return r;
    };

    if(er && objectp(er))
    {
      switch(er->error_type)
      {
        case "template":
          response->set_view(generate_template_error(er));
          response->set_error(500);
          break;
        default:
          response->set_view(generate_error(er));
          response->set_error(500);
          break;
      }
    }
    else if(er)
    {
          response->set_view(generate_error_array(er));
          response->set_error(500);
    }

  }
  else response->set_data("Unknown event: %O\n", request->not_query);

  return response->get_response();
}

object generate_template_error(object er)
{
  object t = view->get_view("internal:error_template");
  t->add("message", er->message());
             
  return t;
}

object generate_error(object er)
{
  object t = view->get_view("internal:error_500");

  t->add("error_type", String.capitalize(er->error_type || "Generic"));
  t->add("message", er->message());
  t->add("backtrace", html_describe_error(er));

  return t;
}

object generate_error_array(array er)
{
  object t = view->get_view("internal:error_500");

  t->add("error_type", String.capitalize("Generic"));
  t->add("message", er[0]);
  t->add("backtrace", html_describe_error(er));

  return t;
}

string html_describe_error(array|object er)
{
  string rv = "";
  array bt;

  if(arrayp(er))
  {
    bt = er[1];
    rv = "<b>" + er[0] + "</b><p>Backtrace:<ol>";
  }
  else
  {
    bt = er->backtrace();
    rv = "<b>" + er->message() + "</b><p>Backtrace:<ol>";
  }
  
  foreach(reverse(bt[2..]);int i; object btf)
  {
    rv += sprintf("<li> %s line %d, %O(%s)", (string)btf[0], btf[1], 
       btf[2], make_btargs(sizeof(btf)>3?btf[3..]:({}))) + "<br>";
  }

  rv += "</ol>";
  return rv;
}

string make_btargs(array args)
{
  string a = "";
  array b = ({});
  foreach(args;;mixed arg)
  {
    string s = "";
    mixed e = catch(s = sprintf("%O", arg) );
    if(e)
      s = "UNKNOWN";

    if(stringp(arg) && sizeof(arg) > 30)
    {
      s = s[0..29] + ("\" <i> + " + (sizeof(arg) - 30) + " chars</i>");
    }

    b+=({s});
  }

  a = b*", ";
  return a;
}

//! Given a request object, this method will find the appropriate event method
//! to call.
//!
//! @returns
//!   an array containing the appropriate event as its first argument and
//!   any remaining arguments as the second through final elements.
array get_event(.Request request)
{
  .FinsController cc;

  if((int)(config["controller"]["reload"]))
  {
	controller_updated(controller, this, "controller");
  }
  cc = controller;
  request->controller = cc;
  request->controller_name = cc->__controller_name;
  function event;
  array args = ({});
  array not_args = ({});
  array r = request->not_query/"/";
  mixed ci;

  // first, let's find the right function to call.
  foreach(r; int i; string comp)
  {
    if(!strlen(comp))
    {
      // ok, the last component was a slash.
      // that means we should call the index method in 
      // the current controller.
      if((i+1) == sizeof(r))
      {
  	    if(event) ; // do nothing
	    else if(cc && (ci = cc["index"]))
	    {
	      not_args += ({"index"});
	      event = ci;
              request->event_name = "index";
	      request->event = event;
	    }
	    else
	    {
	      Log.info("Controller has no index method: %O", cc);
	    }
	    break;
      }
      else
      {
	// if we have an event, we should consider the empty component as a //, where the empty
        // argument component may be significant.
	if(event)
    	{
	  args+=({comp}); 
        }
        // otherwise, we've probably got a double slash somewhere (//)
        // and can ignore it.
      }
    }
    // ok, the component was not empty.
    else
    {
      // if we already have the event, we just tack on to the arguments.
      if(event)
      {
	args+=({comp});
      }
      // if we don't already have the event, but cc[comp] is a function, that's our event.
      else if(cc && (ci = cc[comp]) && functionp(ci))
      {
	not_args += ({comp});
	event = ci;
        request->controller_path += ("/" + comp);
      }
      // if we have a controller, and cc[comp] is an object, we check to see what kind of object.
      else if(cc && ci && objectp(ci))
      {
        // if it's a Runner, well, that's as good as an event for us.
	if(Program.implements(object_program(ci), Fins.Helpers.Runner))
	{
	  not_args += ({comp});
	  event = ci;
          request->event_name = comp;
          request->event = comp;
	}    
        // if it's a controller, we make it our current controller and continue with the next component.
	else if(Program.implements(object_program(ci), Fins.FinsController))
	{ 
	  not_args += ({comp});
          request->controller_path += ("/" + comp);
	  if((int)config["controller"]["reload"])
	  {            
	    controller_updated(ci, cc, comp);
	  }

	  cc = cc[comp];
          request->controller = cc;
          request->controller_name = cc->__controller_name;
	}
	else
	{
	  throw(Error.Generic("Component " + comp + " is not a Controller.\n"));
	}
      }
      // otherwise, if it's an index function, we make it the event and add the component as an arg.
      else if(cc && (ci = cc["index"]))
      { 
	not_args += ({"index"});
	event = ci;
	request->event = ci;
        request->event_name = "index";
	args += ({comp});
      }
      else
      {
	throw(Error.Generic("Component " + comp + " does not exist.\n"));
      }
    }
  }

//  werror("got to end of path; current controller: %O, event: %O, args: %O\n", cc, event, args);

  // we got all this way without an event.
  if(!event && r[-1] != "")
  {
    event = lambda(.Request request, .Response response, mixed ... args)
    {
      response->redirect(request->not_query + "/");
    };
  }
  else if(cc->__uses_session && !request->misc->session_variables && __fin_serve)
  {
    return ({__fin_serve->new_session});
  }
  else if(sizeof(cc->__before_filters) || sizeof(cc->__after_filters) || sizeof(cc->__around_filters))
  {
     event = FilterRunner(event, cc->__before_filters, cc->__after_filters, cc->__around_filters);
  }

  request->not_args = not_args * "/";
  if(!sizeof(request->controller_path)) request->controller_path = "/";

  event_cache[request->controller_path] = event;

  if(sizeof(args))
    return ({event, @args});

  else return ({event});

}

//! handle a request for a static file; used internally by @[handle_http]()
.Response static_request(.Request request)
{
  string fn = Stdio.append_path(static_dir, request->not_query[7..]);

  .Response response = .Response(request);

  low_static_request(request, response, fn);

  return response;
}

.Response low_static_request(.Request request, .Response response, 
    string fn)
{
  Stdio.Stat stat = file_stat(fn);
  if(!stat || stat->isdir)
  {
    response->not_found(request->not_query);
    return response;
  }

  if(request->request_headers["if-modified-since"] && 
      Protocols.HTTP.Server.http_decode_date(request->request_headers["if-modified-since"]) 
      >= stat->mtime) 
  {
    response->not_modified();
    return response;
  }

  response->set_header("Cache-Control", "max-age=" + (3600*exp));
  response->set_header("Expires", (Calendar.Second() + (3600*exp*2))->format_http());
  response->set_type(Protocols.HTTP.Server.filename_to_type(basename(fn)));
  response->set_file(Stdio.File(fn));

  int _handled;
  string t = response->get_type();

  // content compression
  if (t && _gzfilter) {
    if (has_prefix(t, "text") || has_suffix(t, "xml")) {
      _handled = 1;
      _gzfilter->filter(request, response);
    }
    int pos = search(t, "/");
    if (!_handled && pos != -1) {
      switch(t[0..pos-1]) {
	case "text":
	case "application":
   	  _gzfilter->filter(request, response);
        break;
      }
    }
  }

  return response;
}

//! trigger a breakpoint in execution, if breakpointing is enabled.
//! @param desc
//!   description of breakpoint, to be passed to breakpoint client
//! @param state
//!   a mapping of data to make available for query at breakpoint client
//!
public void breakpoint(string desc, mapping state)
{
  if(config["application"] && config["application"]["breakpoint"])
  {
    do_breakpoint(desc, state, backtrace());
  }
  else
  {
    Log.debug("breakpoints disabled, skipping breakpoint set from %O",
                 backtrace()[-2][2]);
  }
  return;
}

private void do_breakpoint(string desc, mapping state, array bt)
{
  if(!breakpoint_client) return;
   object key = bp_lock->lock();
  breakpoint_cond = Thread.Condition();
  bpbe->call_out(lambda(){breakpoint_hilfe = Helpers.Hilfe.BreakpointHilfe(breakpoint_client, this, state, desc, bt);}, 0);
  Log.info("Hilfe started for Breakpoint on %s.", desc);
  breakpoint_cond->wait(key);
  key = 0;
  // now, we must wait for the hilfe session to end.
}


private void handle_breakpoint_client(int id)
{
  if(breakpoint_client) {
    breakpoint_port->accept()->close();
  }
  else breakpoint_client = breakpoint_port->accept();
  breakpoint_client->write("Welcome to Fins Breakpoint Service.\n");
  breakpoint_client->set_backend(bpbe);
  breakpoint_client->set_nonblocking(breakpoint_read, breakpoint_write, breakpoint_close);

}

private void breakpoint_close()
{
  breakpoint_hilfe = 0;
  breakpoint_client = 0;
}

private void breakpoint_write(int id)
{
}

private void breakpoint_read(int id, string data)
{
}

// this is the "helper" runner that handles filters for a given event. 
// we could probably do a fair amount with respect to optimization; right now
// everything is handled dynamically, for each request.
private class FilterRunner(mixed event, array before_filters, array after_filters, array around_filters)
{
  inherit .Helpers.Runner;

  static mixed `()(Fins.Request request, Fins.Response response, mixed ... args)
  {
    run(request, response, @args);
    return 0;
  }

  static int(0..1) _is_type(string bt)
  {
    if(bt=="function")
      return 1;
    else
      return 0;
  }

  void run(Fins.Request request, Fins.Response response, mixed ... args)
  {
    foreach(before_filters;; function|object filter)
    {
      if(objectp(filter))
      { 
        if(!filter->filter(request, response, @args))
          return;
      }
      else if(functionp(filter))
      {
        if(!filter(request, response, @args))
          return;
      }
    }

    if(around_filters && sizeof(around_filters))
	{
		function rr;
		foreach(around_filters;; mixed f)
		{
			if(!rr) rr = lambda(){event(request, response, @args);};
			rr = gen_fun(rr, f, request, response, @args);
		}
		
    	rr();
	}
	
	else
		event(request, response, @args);

    response->render();

    foreach(after_filters;; function|object filter)
    {
      if(objectp(filter))
      { 
        if(!filter->filter(request, response, @args))
          return;
      }
      else if(functionp(filter))
      {
        if(!filter(request, response, @args))
          return;
      }
    }

  }

  function gen_fun(function q, object|function f, object id, object response, mixed ... args)
	{
		return lambda()
			{	
				if(objectp(f))
				{
				//	werror("calling around filter with %O, %O, %O", id, response, args);
					f->filter(q, id, response, @args);
				}	
				else
				{
				//	werror("calling around filter with %O, %O, %O", id, response, args);
					f(q, id, response, @args);
				}				
			};
	}

}
