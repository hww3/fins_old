static mapping loggers = ([]);

string config_file_path;
mapping config_values = ([]);
mapping appenders = ([]);
mapping config_variables = ([]);
static array _rk;
static array _rv;

object default_logger = Tools.Logging.Log.Logger();
//! 
//!  configuration file is standard ini-style.
//!
//!  [logger.logger_name] <-- configures a logger named "logger_name"
//!  appender=appender_name <-- use the appender "appender_name"
//!
//!  [appender.appender_name] <-- configures an appender named "appender_name"
//!  class=Some.Pike.Class <-- use the specified pike class for appending
//!
//!  example: Tools.Logging.Log.FileAppender uses argument "file" to specify logging file
//!
//!  if the configuring application specifies any, you may use substitution variables
//!  in the form ${varname} in your configuration values.
//!
static void create()
{
  create_default_appender();
}

static void create_default_appender()
{
  appenders->default = Tools.Logging.Log.ConsoleAppender();
}

object get_default_logger()
{
	return default_logger;
}

void set_config_variables(mapping vars)
{
   config_variables =  mkmapping(("${" + indices(vars)[*])[*] + "}", values(vars));
   _rk = indices(config_variables);
   _rv = values(config_variables);
    //werror("%O\n", config_variables);
}

void set_config_file(string configfile)
{
  if(!file_stat(configfile))
  {
    throw(Error.Generic("Configuration file " + configfile + " does not exist.\n"));
  }
  else
  {
    config_file_path = configfile;
  }

  load_config_file();
  if(config_values["logger.default"])
  {
    default_logger->configure(config_values["logger.default"]);
    Tools.Logging.Log.configure(config_values["logger.default"]);
  }
}

void load_config_file()
{
  string fc = Stdio.read_file(config_file_path);

  // the "spec" says that the file is utf-8 encoded.
  fc=utf8_to_string(fc);

  config_values = Public.Tools.ConfigFiles.Config.read(fc);  
}

Tools.Logging.Log.Logger get_logger(string loggername)
{
 // werror("get_logger(%s)\n", loggername);
  if(!loggers[loggername]) 
    loggers[loggername] = create_logger(loggername);

  return loggers[loggername] || loggers->default;
}

Tools.Logging.Log.Logger create_logger(string loggername)
{
  object l = create_logger_from_config(loggername);

  // go with a default.
  if(!l) {	
    werror("no defined logger " + loggername + ", using default.");
   l = Tools.Logging.Log.Logger();
  }
  return l;
}

Tools.Logging.Log.Logger create_logger_from_config(string loggername)
{
  // get the nearest logger configuration.
  mapping cx;
  string my_logger_name;

  if(!(cx = config_values["logger." + loggername]))
  {
    array ln = indices(config_values);
    ln = sort(filter(ln, lambda(string x)
      {  return has_prefix("logger." + loggername, x + "."); }
      ));

    if(sizeof(ln)) my_logger_name = ln[-1];
    cx = config_values[my_logger_name];
  }

  if(!cx) return 0;

  // if the logger we're using doesn't have a level specified, we use the level of the next
  // lowest specified logger. if one doesn't exist, we use that of the default logger.
  if(!cx->level)
  {
    string nlevel;
    int gotlevel;

    array x = loggername/".";

    for(int i = sizeof(x)-1; i >= 0; i--)
    {
      string y = x[0 .. i] * ".";
//      werror("checking " + y + "\n");
      if(has_index(config_values["logger." + y] || ([]), "level"))
      {
        nlevel = config_values["logger." + y]->level; 
        gotlevel=1;
        // werror("got level %s\n", nlevel); break;
      }
    }
    if(!gotlevel) nlevel = config_values["logger.default"]->level;
    cx->level = nlevel;
  }
  cx->name = loggername;

  cx = insert_config_variables(cx);

  object l = Tools.Logging.Log.Logger(cx);
  
  return l;
}

array get_appenders(array config)
{
  if(!config) return ({ appenders["default"] });  

  array a = ({});

  //werror("get_appenders(%O)\n", config);

  foreach(config;; string appender_config)
  {
    object ap = get_appender(appender_config);
    if(ap)
      a += ({ ap });
  }

  return a;
}

object get_appender(string config)
{
  if(!appenders[config])
  {
    mapping c = config_values["appender." + config];
  
    if(!c) return 0;

    c = insert_config_variables(c);

    object ap;
    program apc = master()->resolv(c["class"]);
    if(!apc) 
    {
      throw(Error.Generic("Appender type " + c["class"] + " does not exist.\n"));
    }

    ap = apc(c);

    appenders[config] = ap;
  }

  return appenders[config];
}

mapping insert_config_variables(mapping c)
{
    if(_rk)
 	  foreach(c; string k; string v)
	  {
	 	 c[k] = replace(v, _rk, _rv);
	  }
	//werror("%O\n", c);
	return c;
}
