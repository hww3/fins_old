inherit "module";
inherit "caudiumlib";
inherit "socket";

constant cvs_version= "$Id: fins_application.pike,v 1.5 2007-04-04 04:03:06 hww3 Exp $";
constant thread_safe=1;


#include <module.h>
#include <caudium.h>
#include <stat.h>

constant module_type = MODULE_LOCATION;
constant module_name = "Fins Application";
constant module_doc  = "This module serves a fins application.";
constant module_unique = 0;

#define TRACE_ENTER(A,B) do{if(id->misc->trace_enter)id->misc->trace_enter((A),(B));}while(0)
#define TRACE_LEAVE(A) do{if(id->misc->trace_leave)id->misc->trace_leave((A));}while(0)


int redirects, accesses, errors, dirlists;
int puts, deletes, mkdirs, moves, chmods, appes;

int running_isolated = 0;
object findprog_handler;
Thread.Queue queue;
Thread.Thread handler_thread;

static int do_stat = 1;

string loaderstub = #"
import Tools.Logging; 
Fins.Application load_application(string finsdir, string project, string config_name){  \n
Fins.Application application;  application = Fins.Loader.load_app(combine_path(finsdir, project), config_name);
  // Log.loglevel = Log.INFO|Log.WARN|Log.ERROR|Log.CRITICAL;
 return application;}
";


string status()
{
  return ("<h2>Accesses to this filesystem</h2>"+
	  (redirects?"<b>Redirects</b>: "+redirects+"<br>":"")+
	  (accesses?"<b>Normal files</b>: "+accesses+"<br>"
	   :"No file accesses<br>")+
	  (QUERY(put)&&puts?"<b>Puts</b>: "+puts+"<br>":"")+
	  (QUERY(put)&&QUERY(appe)&&appes?"<b>Appends</b>: "+appes+"<br>":"")+
	  (QUERY(method_mkdir)&&mkdirs?"<b>Mkdirs</b>: "+mkdirs+"<br>":"")+
	  (QUERY(method_mv)&&moves?
	   "<b>Moved files</b>: "+moves+"<br>":"")+
	  (QUERY(method_chmod)&&chmods?"<b>CHMODs</b>: "+chmods+"<br>":"")+
	  (QUERY(delete)&&deletes?"<b>Deletes</b>: "+deletes+"<br>":"")+
	  (errors?"<b>Permission denied</b>: "+errors
	   +" (not counting .htaccess)<br>":"")+
	  (dirlists?"<b>Directories</b>:"+dirlists+"<br>":""));
}

void create()
{
  defvar("mountpoint", "/", "Mount point", TYPE_LOCATION, 
	 "This is where the module will be inserted in the "+
	 "namespace of your server.");

  defvar("finsdir", "NONE", "Fins Framework Directory", TYPE_DIR,
         "The directory that Fins is installed in."
        );

  defvar("appname", "default", "Application Name", TYPE_STRING,
         "The name of the application to run."
        );

  defvar("configname", "dev", "FinsApp Configuration Name", TYPE_STRING,
         "The name of the application configuration file to use."
        );

  defvar("run_isolated", 0, "Run application in isolation?", TYPE_FLAG,
         "Should the Fins application be run in isolation? This allows"
         "multiple instances of the same Fins application to run "
         "concurrently, however it uses threads, and has implications "
         "for applications that spawn new threads."
        );

  
}

object application;

string path;
int dirperm, fileperm, default_umask;

void start (int cnt, object conf) {
    module_dependencies(conf, ({ "123session" }));

  if(!QUERY(finsdir) || has_prefix(QUERY(finsdir), "NONE"))
  {
    return;
  }

  if(!QUERY(appname)) 
  {
    report_error("Fins: No application specified.\n");
    return;
  }

  if(!QUERY(configname)) 
  {
    report_error("Fins: No configuration specified.\n");
    return;
  }

  if(QUERY(finsdir))
  {
    object findprog_handler;

    if(QUERY(run_isolated) &&  master()->findprog_handler)
    {
      werror("Running Isolated...\n");
      running_isolated++;
      findprog_handler = master()->findprog_handler();
      master()->add_handler_for_key(this, findprog_handler);
      findprog_handler->pike_module_path = master()->pike_module_path;
      findprog_handler->pike_include_path = master()->pike_include_path;
      findprog_handler->pike_program_path = master()->pike_program_path;
      findprog_handler->add_program_path("whee");
    }
    else
    {
       findprog_handler = master();
    }

    findprog_handler->add_module_path(combine_path(QUERY(finsdir), "lib"));
    werror("added to module path: %O\n", combine_path(QUERY(finsdir), "lib"));
  }
  else
  {
    report_error("Fins: No Fins directory specified.\n");
    return;
  }


  if(running_isolated)
  {
    Thread.Thread(low_load_app);
  }
  else
    call_out(low_load_app, 0.1);

}

void low_load_app()
{
  program loader;
  mixed e;
  if(running_isolated)
  {
    master()->add_thread_for_key(this, master()->current_thread());
  }

  master()->set_inhibit_compile_errors(0);
  e = catch(loader = compile_string(loaderstub));

  if(e)
  {
    report_error("Fins: Unable to create application loader. FinsDir probably not configured properly.\n");
    werror(describe_backtrace(e));
  }

  if(!loader)
  {
    report_error("Fins: No loader!\n");
    return;
  }
  object al = loader();

  object a;

  e = catch {
    a = al->load_application(QUERY(finsdir), QUERY(appname), QUERY(configname));
  };

  if(e)
  {
    report_error("Fins: An error occurred while loading the application " + QUERY(appname) + ".\n");
    werror(describe_backtrace(e));
    return;
  }
  application = a;

  if(running_isolated)
  {
    queue = Thread.Queue();
    handler_thread = Thread.Thread(worker_thread);
  }

}

void worker_thread()
{
  master()->add_thread_for_key(this, master()->current_thread());

  mixed err;

  do
  {
    object id;
    err = catch 
    {
      id = queue->read();
      if(!id)
      {
        werror("shutting down worker thread.\n");
        return;
      }
      mixed res = application->handle_request(id);
      id->misc->__fins_response = res;
      id->misc->__fins_waiter->signal();


    };

    if(err)
    {
      id->misc->__fins_err = err;
      id->misc->__fins_waiter->signal();
    }

  } while(1);

  // TODO: we need to figure out how to shut down the worker
  //       when the module is reloaded.

}

void stop()
{
  if(queue) queue->write(0);
}

string query_location()
{
  return QUERY(mountpoint);
}

mixed find_file( string f, object id )
{
  TRACE_ENTER("find_file(\""+f+"\")", 0);
  if(application)
  {
    if(running_isolated)
    {
      object lock = Thread.Mutex();
      object key = lock->lock();
      id->misc->__fins_waiter = Thread.Condition();
      queue->write(id);
      id->misc->__fins_waiter->wait(key);
      if(id->misc->__fins_err)
        throw(id->misc->fins_err);
      return id->misc->__fins_response;
    }
    else
      return application->handle_request(id);
  }
  else return 0;
}

string query_name()
{
  return sprintf("<i>%s</i> mounted on <i>%s</i>", query("appname"),
		 query("mountpoint"));
}

