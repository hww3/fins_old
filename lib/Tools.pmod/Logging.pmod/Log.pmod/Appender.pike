object output;
string format = "%{hour:02d}:%{min:02d}:%{sec:02d} %{level} - %{msg}";
function format_function;

static void create(mapping config)
{
  if(config->format)
    format = config->format;

  format_function = Tools.String.named_sprintf_func(format + "\n");
}

mixed write(mapping args)
{
  return output->write(format_function(args) );
}

string _sprintf(mixed ... args)
{
  return sprintf("appender(%O)", output);
}

