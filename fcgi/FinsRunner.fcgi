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

int start_listener()
{

    f = Stdio.stdin.dup();

  #ifdef RUN_THREADED
  	for (int i = 0; i < 8; i++) {
  		Thread.Thread(request_loop, f->query_fd(), i);
  	}
  	return (-1);
  #else 
  	request_loop(f->query_fd(),0);
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

          handle_request(request_id);

	} while(!shutdown);
}
