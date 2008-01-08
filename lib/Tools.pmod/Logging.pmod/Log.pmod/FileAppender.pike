inherit Tools.Logging.Log.Logger;
inherit .Appender;

object output;

void create(mapping|void config)
{
  if(!config || !config->file)
  {
    throw(Error.Generic("Configuration File must be specified.\n"));
  }
  else
    output = Stdio.File(config->file, "cwa");

  ::create(config);
}

