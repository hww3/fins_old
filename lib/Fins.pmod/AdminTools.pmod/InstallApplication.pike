import Tools.Logging;

array args;

void create(array _args)
{
  Log.info("InstallApplication module loading");

  if(!sizeof(_args))
  {
    Log.error("InstallApplication requires the name of the application package to install.");
    exit(1);
  }

  else args = _args;
}

int run()
{
  Log.info("InstallApplication module running.");

  program p = compile_string("inherit Fins.PackageInstaller;");
  return p()->main(sizeof(args), args);
}
