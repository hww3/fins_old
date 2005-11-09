inherit "module";
inherit "caudiumlib";
inherit "socket";

constant cvs_version= "$Id: fins_application.pike,v 1.1 2005-11-09 21:38:46 hww3 Exp $";
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

static int do_stat = 1;

string loaderstub = "Fins.Application load_application(string finsdir, string project, string config_name){  Fins.Application application;  application = Fins.Loader.load_app(combine_path(finsdir, project), config_name); return application;}";


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
    add_module_path(combine_path(QUERY(finsdir), "lib"));
  else
  {
    report_error("Fins: No Fins directory specified.\n");
    return;
  }

  program loader;
  mixed e;
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
  }
  application = a;
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
    return application->handle_request(id);
  }
  else return 0;
}

string query_name()
{
  return sprintf("<i>%s</i> mounted on <i>%s</i>", query("appname"),
		 query("mountpoint"));
}

