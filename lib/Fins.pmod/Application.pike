//! this is the base application class.

inherit Fins.Helpers.Macros.JavaScript;
inherit Fins.Helpers.Macros.Basic;

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

//!
static void create(.Configuration _config)
{
   config = _config;
   static_dir = Stdio.append_path(config->app_dir, "static");
   
   load_cache();
   load_model();
   load_view();
   load_controller();

   load_macros();
}

void load_macros()
{
  foreach(glob("simple_macro_*", indices(this)); ; string mf)
  {
    werror("loading macro %O\n", mf[13..]);
    .Template.add_simple_macro(mf[13..], this[mf]);
  }
}

void load_cache()
{
  werror("Starting Cache...\n");

  cache = .FinsCache();
}

void load_view()
{
  string viewclass = config->get_value("view", "class");
  if(viewclass)
    view = ((program)viewclass)(this);
  else werror("No view defined!\n");

}

void load_controller()
{
  string conclass = config->get_value("controller", "class");
  if(conclass)
    controller = ((program)conclass)(this);
  else werror("No controller defined!\n");
}

void load_model()
{
  string modclass = config->get_value("model", "class");
  if(modclass)
    model = ((program)modclass)(this);
  else werror("No model defined!\n");
}

//!
public mixed handle_request(.Request request)
{
  function event;

  request->fins_app = this;

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

  if(objectp(event) || functionp(event))
    event(request, response, @args);

  else response->set_data("Unknown event: %O\n", request->not_query);

  return response->get_response();
}

//!
array get_event(.Request request)
{
  .FinsController cc = controller;
  function event;
  array args = ({});

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
           werror("undefined situation! we have to fix this.\n");
         }
         else if(cc && cc["index"])
         {
           event = cc["index"];
         }
         else
         {
            werror("cc: %O\n", cc);
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
        event = cc[comp];
      }
      else if(cc && cc[comp] && objectp(cc[comp]))
      {
        if(Program.implements(object_program(cc[comp]), Fins.Helpers.Runner))
        {
          event = cc[comp];
        }    
        else if(Program.implements(object_program(cc[comp]), Fins.FinsController))
        {
          cc = cc[comp];
        }    
        else
        {
          throw(Error.Generic("Component " + comp + " is not a Controller.\n"));
        }
      }
      else if(cc && cc["index"])
      {
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

  if(sizeof(args))
    return ({event, @args});
 
  else return ({event});

}

//!
.Response static_request(.Request request)
{
  .Response response = .Response();
  string fn = Stdio.append_path(static_dir, request->not_query[7..]);
  Stdio.Stat stat = file_stat(fn);
  if(!stat || stat->isdir)
  {
    response->not_found(request->not_query);
    return response;
  }
  
  if(request->request_headers["if-modified-since"] && 
      Protocols.HTTP.Server.http_decode_date(request->request_headers["if-modified-since"]) 
        > stat->mtime) 
  {
    response->not_modified();
    return response;
  }

  response->set_header("Cache-Control", "max-age=3600");
  response->set_type(Protocols.HTTP.Server.filename_to_type(basename(fn)));
  response->set_file(Stdio.File(fn));

  return response;
}


string macro_capitalize(.Template.TemplateData data, string|void args)
{
  return String.capitalize(data->get_data()[args]||"");
}

string macro_flash(.Template.TemplateData data, string|void args)
{
  return (data->get_flash()[args]||"");
}
