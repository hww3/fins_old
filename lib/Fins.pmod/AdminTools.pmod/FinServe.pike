#!/usr/local/bin/pike

constant default_port = 8080;
constant my_version = "0.0";

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
  write("FinServer loading application " + project + "\n");

  load_application();

  port = Protocols.HTTP.Server.Port(handle_request, my_port);  
#if constant(_Protocols_DNS_SD)
  bonjour = Protocols.DNS_SD.Service("Fins Application (" + project + ")",
                     "_http._tcp", "", my_port);
#endif
  return -1;
}

void handle_request(Protocols.HTTP.Server.Request request)
{
  write(sprintf("got request: %O\n", request));
  mixed r;

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
