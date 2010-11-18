import Tools.Logging;

//! @param app_dir
//!   the full path to the application directory.
object load_app(string app_dir, string config_name)
{
  string cn;
  object a;

  if(!file_stat(app_dir)) 
    throw(Error.Generic("Application directory " + app_dir + " does not exist.\n"));

  master()->add_program_path(combine_path(app_dir, "classes")); 
  master()->add_module_path(combine_path(app_dir, "modules")); 

  string logcfg = combine_path(app_dir, "config", "log_" + config_name+".cfg");
  Tools.Logging.set_config_variables((["appdir": app_dir, "config": config_name ]));

  Log.info("Loading log configuration from " + logcfg + ", if present.");

  if(file_stat(logcfg))
    Tools.Logging.set_config_file(logcfg);

  Fins.Configuration config = load_configuration(app_dir, config_name);
  Log.info("Preparing to load application " + config->app_name + ".");

  program p;

  cn = "application";
mixed err = catch 
{
  p = master()->cast_to_program(cn);
  a = p(config);
};
if(err)
  Log.error("error occurred while loading the application.", Error.mkerror(err));
  return a;
}

Fins.Configuration load_configuration(string app_dir, string config_name)
{
  string config_file = combine_path(app_dir, "config", config_name+".cfg");

  Log.debug("config file: " + config_file);

  Stdio.Stat stat = file_stat(config_file);
  if(!stat || stat->isdir)
    throw(Error.Generic("Unable to load configuration file " + config_file + "\n"));

  return Fins.Configuration(app_dir, config_file);
}
