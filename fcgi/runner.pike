#!/usr/local/bin/pike -M/Users/hww3/Fins/lib
#define RUN_THREADED 1
constant my_version = "0.1";

import Tools.Logging;

string session_storagedir = "/tmp/finsrunner_storage";
string session_cookie_name = "PSESSIONID";
int session_timeout = 3600;

Session.SessionManager session_manager;

int my_port;
Fins.Application app;
Stdio.File f;
int shutdown = 0;
int requests = 0;


string project_dir = "";
string config_name = "dev";


void print_help(string v)
{
        werror("Help:  %s [-p portnum|--port=portnum] [-c configname|--config=configname] [-a appdir|--appdir=appdir]\n", v);
}

int main(int argc, array(string) argv)
{
  int sock;

  foreach(Getopt.find_all_options(argv,aggregate(
    ({"port",Getopt.HAS_ARG,({"-p", "--port"}) }),
    ({"appdir",Getopt.HAS_ARG,({"-a", "--appdir"}) }),
    ({"config",Getopt.HAS_ARG,({"-c", "--config"}) }),
    ({"help",Getopt.NO_ARG,({"--help"}) }),
    )),array opt)
    {
      switch(opt[0])
      {
              case "help":
                print_help(argv[0]);
                exit(1);
                break;

              case "port":
                my_port = opt[1];
                break;

              case "appdir":
                project_dir = opt[1];
                break;

              case "config":
                config_name = opt[1];
                break;

      }
    }
  
  write("Starting Session Manager...\n");
  session_startup();

  write("FinsRunner loading application " + project_dir + " using configuration " + config_name + "\n");
  load_application();

   return start_listener(my_port);

}

int start_listener(int port)
{
  return 0;
}

void session_startup()
{
  session_manager = Session.SessionManager();
  Session.SessionStorage s = Session.FileSessionStorage();
  s->set_storagedir(session_storagedir);
  session_manager->set_default_timeout(session_timeout);
  session_manager->set_cleaner_interval(session_timeout);
  session_manager->session_storage = ({s});
}

void load_application()
{
  Fins.Application application;

  application = Fins.Loader.load_app(project_dir, config_name);

  if(!application)
  {
    werror("No Application!\n");
    exit(1);
  }

  app = application;
  app->__fin_serve = this;
}

void handle_request(object request_id)
{
  String.Buffer response_string = String.Buffer();
  mixed e;


		    // Do we have either the session cookie or the PSESSIONID var?
                    if(request_id->cookies && request_id->cookies[session_cookie_name] 
                      || request_id->variables[session_cookie_name] )
                    {
                      string ssid=request_id->cookies[session_cookie_name]||request_id->variables[session_cookie_name];
                      Session.Session sess = session_manager->get_session(ssid);
                      request_id->misc->_session = sess;
                      request_id->misc->session_id = sess->id;
                      request_id->misc->session_variables = sess->data;
                    }

                  // the moment of truth!
                  mixed response;
    
                  Log.debug("Got Request: %O", request_id);
                  e = catch {
                    response = app->handle_request(request_id);
                  };
                  
                 
                  if(e)
                  {
                    if(objectp(e))
                      Log.error("got an error: %s\n", e->describe());
                    else
                      Log.error("got an error: %O\n", e);
                    response_string+="Content-type: text/html\r\n\r\n";
                    response_string+=sprintf("<h1>\n%s\n</h1>", describe_error(e)); 
                    response_string+=sprintf("<pre>\n%s\n</pre>", describe_backtrace(e)); 
                  }
                else {
                    if(request_id->misc->_session)
                    {
                      // we need to set this explicitly, in case the link was broken.
                      request_id->misc->_session->data = request_id->misc->session_variables;
                      session_manager->set_session(request_id->misc->_session->id, request_id->misc->_session, 
                                                   session_timeout);
                    }

                  response_string += response_to_string(response);
                }
              request_id->response_write_and_finish(response_string->get());
}


string response_to_string(mixed r)
{
   string response="";
   mapping retval;
   
   if(stringp(r))
   {
     response+=sprintf("Status: %d\r\n", 200);
     response+="Content-type: text/plain\r\n\r\n";
     response+=r;
   }
   
   if(!r) return "";
   if(objectp(r))
    retval = r->get_response();
   else retval = r;
   response+=sprintf("Status: %d\r\n", retval->error);

   if(retval->extra_heads["content-type"]) ; // DO NOTHING!
   else 
     response+=sprintf("Content-type: %s\r\n", retval->type);

    foreach(retval->extra_heads; string hname; string hvalue)
      response+=sprintf("%s: %s\r\n", String.capitalize(hname), hvalue);

    response+="\r\n";

    if(retval->file && objectp(retval->file))
      response+=retval->file->read();
    else if(retval->data)
      response+=retval->data;
  
  return response;
}


  void new_session(object request, object response, mixed ... args)
  {
    string ssid=session_manager->new_sessionid();
    response->set_cookie(session_cookie_name,
                           ssid, time() + session_timeout);

    string req=request->not_query;
    req += "?PSESSIONID="+ssid;
    if( sizeof(request->query) )
    {
      req += "&"+request->query;
    }
    response->redirect(req);

    Log.debug( "Created new session sid='%s' host='%s'",ssid,request->remoteaddr);
  }

