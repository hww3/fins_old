static mapping loggers = ([]);

string config_file_path;
mapping config_values = ([]);
mapping appenders = ([]);
mapping config_variables = ([]);
static array _rk;
static array _rv;

int is_configed = 0;

mapping _default_config_variables = (["host": gethostname(), 
				"pid": (string)getpid(), 
				"user": getpwuid(System.getuid())[0] ]);

mapping _default_logger_config = (["appender": "default", "level": "DEBUG"]);

object default_logger = Tools.Logging.Log.Logger();


//! 
//!  configuration file is standard ini-style.
//!
//!  [logger.logger_name] <-- configures a logger named "logger_name"
//!
//!  level=DEBUG|INFO|WARN|ERROR <-- optional log level for this logger
//!
//!  appender=appender_name <-- use the appender "appender_name", may be specified multiple times
//!
//!  class=Some.Pike.Class <-- use the specified pike class for appending,
//!    defaults to Tools.Logging.Log.Logger
//!
//!  additivity=false <-- do not use the parent configuration as a basis for this logger's configuration files to override.
//!
//!  [appender.appender_name] <-- configures an appender named "appender_name"
//!
//!  class=Some.Pike.Class <-- use the specified pike class for appending
//!
//!  example: Tools.Logging.Log.FileAppender uses argument "file" to specify logging file
//!
//!  if the configuring application specifies any, you may use substitution variables
//!  in the form ${varname} in your configuration values. By default, "host", "user" and "pid"
//!  are available.
//!
//! @note
//!  regardless of configuration, a default logger will always be available.
//!  a configuration file may specify an alternate default logger configuration
//!  by using a config section called [default.logger].
static void create()
{
  create_default_appender();
  config_values["logger.default"] = _default_logger_config;
  config_variables = _default_config_variables;
}

static void create_default_appender()
{
  appenders->default = Tools.Logging.Log.ConsoleAppender();
}

//! returns the default logger, which will always be available,
//! and which outputs to the console (unless this configuration is specifically
//! altered in the configuration file.)
object get_default_logger()
{
  	  return default_logger;
}

//! sets available configuration substitution variables, in addition to the standard
//! values of "host", "pid" and "user".
void set_config_variables(mapping vars)
{
   config_variables =  _default_config_variables + mkmapping(("${" + indices(vars)[*])[*] + "}", values(vars)); 
}

// specifies a configuration file to be used, which will be loaded and parsed.
void set_config_file(string configfile)
{
  default_logger->info("setting configuration file using " + configfile);
  if(!file_stat(configfile))
  {
    throw(Error.Generic("Configuration file " + configfile + " does not exist.\n"));
  }
  else
  {
    config_file_path = configfile;
  }

  load_config_file();

  if(!config_values["logger.default"])
    config_values["logger.default"] = _default_logger_config;

  if(config_values["logger.default"])
  {
    default_logger->configure(config_values["logger.default"]);
    Tools.Logging.Log.configure(config_values["logger.default"]);
  }
  
  is_configed = 1;
}

void load_config_file()
{
  string fc = Stdio.read_file(config_file_path);

  // the "spec" says that the file is utf-8 encoded.
  fc=utf8_to_string(fc);

  config_values = Public.Tools.ConfigFiles.Config.read(fc);  
}

//! get a logger for loggername
//!
//! by default, this call will always return a logger object. if the requested 
//! logger is not found, the default logger will be returned.
//!
//! @param loggername
//!   may be a string, in which the logger is directly specified,
//!   or a program, in which case the logger name will be the 
//!   lower-cased full name of the program (as determined by the %O parameter to @[sprintf()], 
//!   with any "/" converted to ".".
//!
//! @param no_default_logger
//!   if specified, this flag will cause this call to return '0' if no logger
//!   with the requested name could be found.
//!
//! @example
//!   get_logger(Protocols.HTTP.client) 
//!
//! would request the logger named "protocols.http.client".
//! 
//! @note 
//!  loggers returned by this method are shared copies.
Tools.Logging.Log.Logger get_logger(string|program loggername, int|void no_default_logger)
{

  if(programp(loggername))
    loggername = replace(lower_case(sprintf("%O", loggername)), "/", ".");
 // werror("get_logger(%s)\n", loggername);
  if(!loggers[loggername]) 
    loggers[loggername] = create_logger(loggername);

  return loggers[loggername] || get_default_logger();
}

Tools.Logging.Log.Logger create_logger(string loggername)
{
  object l = create_logger_from_config(loggername);

#if 0
  // go with a default.
  if(!l) {	
    default_logger->debug("no defined logger " + loggername + ", using default.");
   l = Tools.Logging.Log.Logger((["name":loggername]));
  }
#endif /* 0 */
  return l;
}

mapping build_logger_config(string loggername)
{
  mapping cx = ([]);
  mapping _cx;
  string cn;
  int isroot;

  if(!is_configed) 
    default_logger->warn("logging system has not been configured yet. only default logger is available.");

  // first, find the nearest logger in the hierarchy.

  if(!(_cx = config_values["logger." + loggername]))  // if we don't have an exact match   
  {
    array ln = indices(config_values);

    // get the closest match.

    // generate a list of parts.
    array lp = ((loggername/".")-({""}));

    for(int x = sizeof(lp); x > 1; x--)
    {
      string acn = lp[0..x-1]*".";
//      werror("does logger config %O exist? ", acn);
      if(config_values["logger." + acn])
      {
//         werror("yes!\n");
         cn = acn;
         if(x==1) isroot = 1;
      }
//      else werror("no!\n");
    }
  }
  else cx=_cx, cn = loggername;

  if(!cn) cn = "default";
  mapping tc = config_values["logger." + cn];

  // do we want to blend in the previous higher level logger configuration in?
  if(cn!= "default" && !(tc->additivity && lower_case(tc->additivity) == "false"))
  {
    if(isroot)
    {
      default_logger->debug("additivity is true, but we're the root logger, merging defaults.");
      cx = config_values["logger.default"] + cx;
    }
    else
    {
      // generate the parent logger name.
      array cnp = (cn/".") - ({""});
      string pln = cnp[0..sizeof(cnp)-2] * ".";
      if(pln!=loggername)
      {
      	default_logger->debug("additivity is true, blending settings from parent logger %O", pln);
        mapping lc = build_logger_config(pln);
        cx = lc + cx;
      }
    }
  }

  cx += (config_values["logger." + cn]);
  cx["_name"] = cn;

  return cx;
}

string get_default_level()
{
  return (config_values["logger.default"]->level) || "INFO";
}

Tools.Logging.Log.Logger create_logger_from_config(string loggername)
{
  // get the nearest logger configuration.
  mapping cx;

  cx = build_logger_config(loggername);

  if(!cx) return 0;

  // werror("config: %O\n", cx);

  cx->name = loggername;

  cx = insert_config_variables(cx);

  if(!cx->level) 
  {
    string default_level = get_default_level();
    default_logger->warn("no log level set for logger " + cx->name +". using default level " + default_level + ".");
    cx->level = default_level;
  }

  program loggerclass;
  if(cx->class)
  {
    program lc = master()->resolv(cx["class"]);
    if(lc) loggerclass = lc;
    else
      throw(Error.Generic("Logger type " + cx["class"] + " does not exist.\n"));
      
  }
  if(!loggerclass)
    loggerclass = Tools.Logging.Log.Logger;
  
  object l = loggerclass(cx);
  
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
  foreach(c; string k; string v)
  {
    if(v)
      c[k] = replace(v, indices(config_variables), values(config_variables));
  }

  return c;
}
