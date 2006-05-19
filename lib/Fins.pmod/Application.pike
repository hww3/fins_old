import Fins;
import Tools.Logging;

//! this is the base application class.

object __fin_serve;

//!
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




// breakpointing support
Stdio.Port breakpoint_port;
int breakpoint_port_no = 3333;
Stdio.File breakpoint_client;
object bp_key;
object breakpoint_cond;
object bp_lock = Thread.Mutex();
object breakpoint_hilfe;
object bpbe = Pike.Backend();
object bpbet = Thread.Thread(lambda(){ do { catch(bpbe()); } while (1); });




//!
static void create(.Configuration _config)
{
  

  config = _config;
  static_dir = Stdio.append_path(config->app_dir, "static");

  load_breakpoint();
  load_cache();
  load_model();
  load_view();
  load_controller();

  start();
}

//! this method will be called after the cache, model, view and 
//! controller have been loaded.
void start()
{

}

static void load_breakpoint()
{
  if(config["app"] && config["app"]["breakpoint"])
  {
    if((int)config["app"]["breakpoint_port"]) breakpoint_port_no = 
                                             (int)config["app"]["breakpoint_port"];
    Log.info("Starting Breakpoint Server on port %d.", breakpoint_port_no);
    breakpoint_port = Stdio.Port(breakpoint_port_no, handle_breakpoint_client);
    breakpoint_port->set_backend(bpbe);
  }
}

static void load_cache()
{
  Log.info("Starting Cache...\n");

  cache = .FinsCache();
}

static void load_view()
{
  string viewclass = (config["view"] ? config["view"]["class"] :0);
  if(viewclass)
    view = ((program)viewclass)(this);
  else Log.debug("No view defined!");
}

static void load_controller()
{
  string conclass = (config["controller"]? config["controller"]["class"] :0);
  if(conclass)
    controller = ((program)conclass)(this);
  else Log.debug("No controller defined!");
}

static void load_model()
{
  string modclass = (config["model"] ? config["model"]["class"] : 0);
  if(modclass)
  {
    Log.info("loading model from " + modclass + "\n");
    model = ((program)modclass)(this);
  }
  else Log.debug("No model defined!");
}

int controller_updated(object controller, object container, string cn)
{
  string filename = master()->programs_reverse_lookup(object_program(controller));
  //  werror("filename: %O program: %O\n", filename, object_program(controller));
  object stat = file_stat(filename);
  if(stat && stat->mtime > controller->__last_load)
  {
    string key = search(master()->programs, object_program(controller));
    // werror("key is " + key + "\n");
    //     m_delete(master()->programs, key);

    Log.debug("Reloading controllers...");
    load_controller();

    return 1;
  }

  return 0;
}

//!
public mixed handle_request(.Request request)
{
  function event;

  request->fins_app = this;

  //  Log.info("SESSION INFO: %O", request->misc->session_variables);

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
    event(request, response, @args);

  else response->set_data("Unknown event: %O\n", request->not_query);

  return response->get_response();
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

  function event;
  array args = ({});
  array not_args = ({});
  array r = request->not_query/"/";

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
	if(event)
	{
	  Log.error("undefined situation! we have to fix this.\n");
	}
	else if(cc && cc["index"])
	{
	  not_args += ({"index"});
	  event = cc["index"];
	}
	else
	{
	  Log.info("cc: %O\n", cc);
	}
	break;
      }
      else
      {
	// what should we do?
	if(event)
	{
	  args+=({comp});
	}
      }
    }

    // ok, the component was not empty.
    else
    {
      if(event)
      {
	args+=({comp});
      }
      else if(cc && cc[comp] && functionp(cc[comp]))
      {
	not_args += ({comp});
	event = cc[comp];
      }
      else if(cc && cc[comp] && objectp(cc[comp]))
      {
	if(Program.implements(object_program(cc[comp]), Fins.Helpers.Runner))
	{
	  not_args += ({comp});
	  event = cc[comp];
	}    
	else if(Program.implements(object_program(cc[comp]), Fins.FinsController))
	{ 
	  not_args += ({comp});
	  if((int)config["controller"]["reload"])
	  {            
	    controller_updated(cc[comp], cc, comp);
	  }

	  cc = cc[comp];
	}
	else
	{
	  throw(Error.Generic("Component " + comp + " is not a Controller.\n"));
	}
      }
      else if(cc && cc["index"])
      { 
	not_args += ({"index"});
	event = cc["index"];
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
  else if(sizeof(cc->__before_filters) || sizeof(cc->__after_filters))
  {
     event = FilterRunner(event, cc->__before_filters, cc->__after_filters);
  }

  request->not_args = not_args * "/";


  if(sizeof(args))
    return ({event, @args});

  else return ({event});

}

//!
.Response static_request(.Request request)
{
  string fn = Stdio.append_path(static_dir, request->not_query[7..]);

  .Response response = .Response();

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

  response->set_header("Cache-Control", "max-age=" + (3600*12));
  response->set_header("Expires", (Calendar.Second() + (3600*12))->format_http());
  response->set_type(Protocols.HTTP.Server.filename_to_type(basename(fn)));
  response->set_file(Stdio.File(fn));

  return response;
}

public void breakpoint(string desc, mapping state)
{
  if(config["app"] && config["app"]["breakpoint"])
  {
    do_breakpoint(desc, state, backtrace());
    return;
  }
  else return;
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

private class FilterRunner(mixed event, array before_filters, array after_filters)
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

}

