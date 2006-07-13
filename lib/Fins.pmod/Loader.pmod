import Tools.Logging;

Fins.Application load_app(string app_dir, string config_name)
{
  string cn;
  Fins.Application a;

  if(!file_stat(app_dir)) 
    throw(Error.Generic("Application directory " + app_dir + " does not exist.\n"));

  add_program_path(combine_path(app_dir, "classes")); 
  add_module_path(combine_path(app_dir, "modules")); 

  Fins.Configuration config = load_configuration(app_dir, config_name);

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
