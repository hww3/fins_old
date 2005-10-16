Fins.Application load_app(string app_dir)
{
  string cn;
  Fins.Application a;

  if(!file_stat(app_dir)) 
    throw(Error.Generic("Application directory " + app_dir + " does not exist.\n"));

  add_program_path(app_dir + "/classes"); 

  cd(app_dir);

  Fins.Configuration config = load_configuration(app_dir);

  program p;

  add_constant("app", a);

  cn = "application";
  p = (program)(cn);

  a = p(config);

  return a;
}

Fins.Configuration load_configuration(string app_dir)
{
  return Fins.Configuration();
}
