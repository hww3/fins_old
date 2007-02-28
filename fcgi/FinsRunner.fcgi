#!/usr/local/bin/pike -M/export/home/hww3/Fins/lib -P/export/home/hww3/Fins/fcgi
#define RUN_THREADED 1

inherit "runner";

constant my_version = "0.1";

string project_dir = "/export/home/hww3/Fins/FinScribe";
string config_name = "dev";

string session_storagedir = "/tmp/finsrunner_storage";
#ifdef LOGGING
string logfile_path = "/tmp/finsrunner.log";
#endif
string session_cookie_name = "PSESSIONID";
int session_timeout = 3600;

int start_listener(int port)
{
  int sock;

  if(!port)
  {
    f = Stdio.stdin.dup();
    sock = f->query_fd();
  }
  else
  {
    sock = Public.Web.FCGI.open_socket(":" + port, 128);
  }
#ifdef RUN_THREADED
  for (int i = 0; i < 8; i++) {
    Thread.Thread(request_loop, sock, i);
  }
  return (-1);
#else 
  request_loop(sock, 0);
  return 0;
#endif
}

void request_loop(int sock, int id)
{
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
    mixed e;

    if(e = catch(request_id = Fins.FCGIRequest(request)))
    {
#ifdef RUN_THREADED
      key = lock->lock();
#endif
      request->real_write("Status: 500 Server Error\r\n");
      request->real_write("Content-type: text/html\r\n\r\n");
      request->real_write("<h1>Error 500: Internal Server Error</h1>");
      request->real_write("The server was unable to parse your request.\n");
      request->real_write("<p>" + describe_backtrace(e));                  
      request->finish();
#ifdef RUN_THREADED
      key = 0;
#endif
      continue;
    }

    handle_request(request_id);

  } while(!shutdown);
}
