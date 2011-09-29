object output;
string format = "%{hour:02d}:%{min:02d}:%{sec:02d} %{level} - %{name}: %{msg}";
function format_function;

static void create(mapping config)
{
  if(config->format)
    format = config->format;

  format_function = Tools.String.named_sprintf_func(format + "\n");
}

//! creates the parent folder for file if it doesn't exist.
void make_log_directory(string file)
{
  string dirname = dirname(file);
  Stdio.Stat fss = file_stat(dirname);
  if(!fss)
  {
    .module.info("creating directory " + dirname);
    Stdio.mkdirhier(dirname);
  }
}

mixed write(mapping args)
{
  return output->write(encode_string(format_function(args) ));
}

string _sprintf(mixed ... args)
{
  return sprintf("appender(%O)", output);
}


// we shouldn't assume the output should be utf8, but it will allow us to avoid
// errors when trying to write log messages with wide strings.
string encode_string(string input)
{
  return string_to_utf8(input);
}
