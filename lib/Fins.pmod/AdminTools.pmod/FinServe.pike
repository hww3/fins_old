#!/usr/local/bin/pike

constant default_port = 8080;
constant my_version = "0.0";

string session_storagedir = "/tmp/scriptrunner_storage";
string logfile_path = "/tmp/scriptrunner.log";
string session_cookie_name = "PSESSIONID";
int session_timeout = 3600;

Session.SessionManager session_manager;

Fins.Application app;
Protocols.HTTP.Server.Port port;
#if constant(_Protocols_DNS_SD)
Protocols.DNS_SD.Service bonjour;
#endif
string project = "default";

int main(int argc, array(string) argv)
{
  int my_port = default_port;
  if(argc>1) my_port=(int)argv[1];
  if(argc>2) project = argv[2];

  write("FinServe starting on port " + my_port + "\n");

  write("Starting Session Manager...\n");
  session_startup();

  write("FinServe loading application " + project + "\n");
  load_application();

  port = Protocols.HTTP.Server.Port(handle_request, my_port);  
  port->request_program = Fins.Request;

#if constant(_Protocols_DNS_SD)
  bonjour = Protocols.DNS_SD.Service("Fins Application (" + project + ")",
                     "_http._tcp", "", my_port);
#endif
  return -1;
}

void session_startup()
{
  session_manager = Session.SessionManager();
  Session.SessionStorage s = Session.FileSessionStorage();
  s->set_storagedir(session_storagedir);
  session_manager->set_default_timeout(session_timeout);
  session_manager->set_cleaner_interval(session_timeout);
  session_manager->session_storage = ({s});

  add_constant("Session", Session.Session);
  add_constant("session_manager", session_manager);

}

void handle_request(Protocols.HTTP.Server.Request request)
{
  write(sprintf("got request: %O\n", request));
  mixed r;

  // Do we have either the session cookie or the PSESSIONID var?
  if(request->cookies && request->cookies[session_cookie_name]
         || request->variables[session_cookie_name] )
  {
    string ssid=request->cookies[session_cookie_name]||request->variables[session_cookie_name];
    Session.Session sess = session_manager->get_session(ssid);
    request->misc->_session = sess;
    request->misc->session_id = sess->id;
    request->misc->session_variables = sess->data;
  }
  // if we don't have the session identifier set, we should set one.
  else
  {
    Fins.Response response = Fins.Response();

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

    werror( "Created new session sid='%s' host='%s'\n",ssid,request->remoteaddr);
    request->response_and_finish(response->get_response());
    return;
  }

  mixed e = catch {
    r = app->handle_request(request);
  };

  if(e)
  {
    write("Error occurred while handling request!\n");
    mapping response = ([]);
    response->error=500;
    response->type="text/html";
    response->data = "<h1>An error occurred while processing your request:</h1>\n"
                     "<pre>" + describe_backtrace(e) + "</pre>";
    request->response_and_finish(response);
    return;
  }

  e = catch {
    if(mappingp(r))
    {
      request->response_and_finish(r);
    }
    else if(stringp(r))
    {
      mapping response = ([]);
      response->server="FinServe " + my_version;
      response->type = "text/html";
      response->error = 200;
      response->data = r;
      request->response_and_finish(response);
    }
  };

  if(request->misc->_session)
  {
     // we need to set this explicitly, in case the link was broken.
     request->misc->_session->data = request->misc->session_variables;
     session_manager->set_session(request->misc->_session->id, request->misc->_session,
                                  session_timeout);
  }

  if(e)
  {
    write("Internal Server Error!\n");
    mapping response = ([]);
    response->error=500;
    response->type="text/html";
    response->data = "<h1>Internal Server Error</h1>\n"
                     "<pre>" + describe_backtrace(e) + "</pre>";
    request->response_and_finish(response);
    return;
  }

  return;
}

void load_application()
{
  Fins.Application application;

  application = Fins.Loader.load_app(project);

  if(!application)
  {
    werror("No Application!\n");
    exit(1);
  }

  app = application;

}
