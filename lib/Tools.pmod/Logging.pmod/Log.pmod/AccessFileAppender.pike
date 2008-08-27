inherit Tools.Logging.Log.Logger;
inherit .Appender;

object output;

string format = "%{remote_host} - %{user} [%{mday:02d}/%{month}/%{year}:%{hour:02d}:%{min:02d}:%{sec:02d} %{timezone:+05d}] \"%{method} %{request} %{protocol}\" %{code} %{size}";

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

