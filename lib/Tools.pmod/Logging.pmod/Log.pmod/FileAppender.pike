inherit Tools.Logging.Log.Logger;


object output;

void create(mapping|void config)
{
  if(!config || !config->file)
  {
    throw(Error.Generic("Configuration File must be specified.\n"));
  }
  else
    output = Stdio.File(config->file, "cwa");

//  werror("output: %O\n", output);
}

mixed write(mixed ... args)
{
  return output->write(@args);
}  

string _sprintf(mixed ... args)
{
  return sprintf("appender(%O)", output);
}
