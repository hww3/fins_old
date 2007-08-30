import Tools.Logging;

Fins.Application load_app(string app_dir, string config_name)
{
  string cn;
  Fins.Application a;

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

  object o;
  if(o = master()->resolv(config->app_name + ".Model"))
    Fins.Model.set_model_module(o);
  if(o = master()->resolv(config->app_name + ".Objects"))
    Fins.Model.set_object_module(o);

  program p;

  cn = "application";
  p = (program)(cn);

  a = p(config);

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
