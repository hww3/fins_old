static mapping loggers = ([]);

string config_file_path;
mapping config_values = ([]);
mapping appenders = ([]);

static void create()
{
  create_default_appender();
  create_logger("default");
}

static void create_default_appender()
{
  appenders->default = Tools.Logging.Log.FileAppender();
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
 werror("get_logger(%s)\n", loggername);
  if(!loggers[loggername]) 
    loggers[loggername] = create_logger(loggername);

  return loggers[loggername] || loggers->default;
}

Tools.Logging.Log.Logger create_logger(string loggername)
{
  object l = create_logger_from_config(loggername);

  // go with a default.
  if(!l) l = Tools.Logging.Log.Logger();
  return l;
}

Tools.Logging.Log.Logger create_logger_from_config(string loggername)
{
  mapping cx = config_values["logger." + loggername];

  if(!cx) return 0;

  object l = Tools.Logging.Log.Logger(cx);
  
  array appenders = get_appenders(arrayp(cx->appender)?cx->appender:({cx->appender}));
  l->set_appenders(appenders);
  return l;
}

array get_appenders(array config)
{
  if(!config) return ({ appenders["default"] });  

  array a = ({});

  werror("get_appenders(%O)\n", config);

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
