inherit .Appender;

object output = Stdio.stdout;

static void create(mapping|void config)
{
  if(!config) config = ([]);
  ::create(config);
}
