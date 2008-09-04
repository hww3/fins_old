import Tools.Logging;

string newappname;

string locale_contents = 
#"<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>
<project name=\"__APPNAME__\">
 <baselang>eng</baselang>
 <xmlpath>translations/%L/__APPNAME__.xml</xmlpath>
 <nocopy/>
</project>
";

string config_contents = 
#"# this is a Fins Application configuration file.
#
[model]
class=model
debug=1
#datasource=mysql://user:pass@host/db

[controller]
class=controller
reload=1

[view]
class=view
reload=1

[application]
class=application
";

string log_config_contents = 
#"
[logger.default]
appender=default_console
appender=default_debuglog

[logger.access]
appender=access_log
class=Tools.Logging.Log.AccessLogger

[appender.default_console]
class=Tools.Logging.Log.ConsoleAppender

[appender.default_debuglog]
class=Tools.Logging.Log.FileAppender
file=${appdir}/logs/debug.log

[appender.access_log]
file=${appdir}/logs/access.log
class=Tools.Logging.Log.AccessFileAppender
";

string model_contents =
#"
inherit Fins.FinsModel;

";

string view_contents = 
#"
inherit Fins.FinsView;
";

string application_contents =
#"
inherit Fins.Application;
";

string controller_contents =
#"
inherit Fins.FinsController;
void index(object id, object response, mixed ... args)
{
  string req = sprintf(\"%O\", mkmapping(indices(id), values(id)));
  string con = master()->describe_object(this);
  string method = function_name(backtrace()[-1][2]);
  object v = view->get_view(\"internal:index\");

  v->add(\"appname\", \"__APPNAME__\");
  v->add(\"request\", req);
  v->add(\"controller\", con);
  v->add(\"method\", method);

  response->set_view(v);
}
";

string start_contents =
#"#!/bin/sh

  PIKE_ARGS=\"\"

  if [ x$FINS_HOME != \"x\" ]; then
    PIKE_ARGS=\"$PIKE_ARGS -M$FINS_HOME/lib\"
  else
    echo \"FINS_HOME is not defined. Define if you have Fins installed outside of your standard Pike module search path.\"
  fi

  cd `dirname $0`/../..
  exec pike $PIKE_ARGS -x fins start __APPNAME__ $*
";


string fins_contents =
#"#!/bin/sh

  PIKE_ARGS=\"\"

  if [ x$FINS_HOME != \"x\" ]; then
    PIKE_ARGS=\"$PIKE_ARGS -M$FINS_HOME/lib\"
  else
    echo \"FINS_HOME is not defined. Define if you have Fins installed outside of your standard Pike module search path.\"
  fi

  ARG0=$1
  if [ x$ARG0 = \"x\" ]; then
    echo \"$0: no command given.\"
    exit 1
  fi
  shift 1

  cd `dirname $0`/../..
  exec pike $PIKE_ARGS -x fins $1 __APPNAME__ $2 $3 $4
";

void create(array args)
{
  Log.info("CreateApplication module loading");

  if(!sizeof(args))
  {
    Log.error("CreateApplication requires the name of the application to create.");
    exit(1);
  }

  else newappname = args[0];
}

int run()
{
  Log.info("CreateApplication module running.");

  Log.info("Creating application %s in %s.", newappname, getcwd());

  // first, create the directory for the app.
  mkdir(newappname);
  cd(newappname);
  
  // now, let's create the subfolders.
  foreach(({"classes", "config", "modules", "templates", "static", "logs", "bin", "translations", "translations/eng"});; string dir)
    mkdir(dir);
 
  // now, we create the configfiles, one each for dev, test, prod.
  cd("config");

  foreach(({"dev", "test", "prod"});; string tier)
  {
    Stdio.write_file(tier + ".cfg", customize("#\n# this is the configuration for " + upper_case(tier) + ".\n#\n" + config_contents));
    Stdio.write_file("log_" + tier + ".cfg", customize("#\n# this is the logging configuration for " + upper_case(tier) + ".\n#\n" + log_config_contents));
  }

  Stdio.write_file("locale.xml", customize(locale_contents));

  cd("../classes");
  Stdio.write_file("application.pike", customize(application_contents));
  Stdio.write_file("model.pike", customize(model_contents));
  Log.info("Be sure to edit config/*.cfg to specify the application's datasource");
  Stdio.write_file("view.pike", customize(view_contents));
  Stdio.write_file("controller.pike", customize(controller_contents));

  // next, we prepare the modules, mostly used by the model.
  cd("../modules");
  mkdir(newappname + ".pmod");
  cd(newappname + ".pmod");
  mkdir("Objects.pmod");
  mkdir("Model.pmod");  
//  Stdio.write_file("Repo.pmod", customize(repo_contents));

  cd("../..");

  cd ("bin");
  Stdio.write_file("start.sh", customize(start_contents));
  Stdio.write_file("fins.sh", customize(fins_contents));
  Process.system("chmod a+rx start.sh");
  
  return 0;
}

string customize(string c)
{
  return replace(c, ({"__APPNAME__"}), ({newappname}));
}
