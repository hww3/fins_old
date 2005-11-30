#!/usr/local/bin/pike -M/Users/hww3/Fins/lib
#define RUN_THREADED 1
constant my_version = "0.1";

string session_storagedir = "/tmp/finsrunner_storage";
#ifdef LOGGING
string logfile_path = "/tmp/finsrunner.log";
#endif
string session_cookie_name = "PSESSIONID";
int session_timeout = 3600;

Session.SessionManager session_manager;

Fins.Application app;
Stdio.File f;
#ifdef LOGGING
Stdio.File logfile;
#endif
int shutdown = 0;
int requests = 0;


string project_dir = "/Users/hww3/Fins/FinBlog";
string config_name = "dev";

int main(int argc, array(string) argv)
{
  int sock;
  
  write("Starting Session Manager...\n");
  session_startup();

  write("FinsRunner loading application " + project_dir + " using configuration " + config_name + "\n");
  load_application();

#ifdef LOGGING
    if(logfile_path)
      logfile=Stdio.File(logfile_path, "rwac");
#endif
    f = Stdio.stdin.dup();

  #ifdef RUN_THREADED
  	for (int i = 0; i < 8; i++) {
  		Thread.Thread(request_loop, f->query_fd(), i);
  	}
  	return (-1);
  #else 
  	request_loop(f->query_fd(),0);
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

}

void request_loop(int sock, int id)
{
        String.Buffer response_string = String.Buffer();
  mixed e;
#ifdef RUN_THREADED 
  Thread.Mutex lock;
	Thread.MutexKey key;
	lock = Thread.Mutex();  
  key = lock->lock();
#endif
	object request = Public.Web.FCGI.FCGI(sock);
#ifdef RUN_THREADED
        key = 0;
#endif

        do{
		request->accept();
                requests ++;
                object request_id;

                if(catch(request_id = Fins.FCGIRequest(request)))
                {
#ifdef RUN_THREADED
                  key = lock->lock();
#endif
                  request->write("Status: 500 Server Error\r\n");
                  request->write("Content-type: text/html\r\n\r\n");
                  request->write("<h1>Error 500: Internal Server Error</h1>");
                  request->write("The server was unable to parse your request.\n");
                  request->finish();
#ifdef RUN_THREADED
                  key = 0;
#endif
 		              continue;
                }


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
                    else 
                    {
		                  Fins.Response response = Fins.Response(request_id);

                      string ssid=session_manager->new_sessionid();
                      response->set_cookie(session_cookie_name,
                                             ssid, time() + session_timeout);

                      string req=request_id->not_query;
                      req += "?PSESSIONID="+ssid;
                      if( sizeof(request_id->query) )
                      {
                        req += "&"+request_id->query;
                      }
                      response->redirect(req);
#ifdef LOGGING
		                  log( "Created new session sid='%s' host='%s'\n",ssid,request_id->remoteaddr);
#endif
                      request_id->response_write_and_finish(response_to_string(response));
                      continue;
                    }

                  // the moment of truth!
                  mixed response;
                  
                  e = catch {
                    response = app->handle_request(request_id);
                  };
                  
                 
                  if(e)
                  {
#ifdef LOGGING
                    if(objectp(e))
                      log("got an error: %s\n", e->describe());
                    else
                      log("got an error: %O\n", e);
#endif
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
#ifdef LOGGING
              log("request finished\n");
#endif  
	} while(!shutdown);
}

#ifdef LOGGING
void log(string t, mixed ... args)
{
  if(!logfile) return;

  if(args)
    t = sprintf(t, @args);
  logfile->write(sprintf("[%s] %s", (ctime(time())- "\n"), t));
}

#endif

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
