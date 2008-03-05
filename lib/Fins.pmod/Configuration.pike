string app_dir;
string app_name;
string config_file;
static mapping values;

//!
static void create(string appdir, string|mapping _config_file)
{
  app_dir = appdir;

  if(appdir)
    app_name = ((appdir/"/")-({""}))[-1];

  if(stringp(_config_file))
  {
    config_file = _config_file;
    string fc = Stdio.read_file(config_file);

    // the "spec" says that the file is utf-8 encoded.
    fc=utf8_to_string(fc);

    values = Public.Tools.ConfigFiles.Config.read(fc);
  }
  else if(mappingp(_config_file))
  {
    values = _config_file;
  }
}

void set_value(string section, string item, mixed value)
{
  if(!values[section])
    values[section] = ([]);

  values[section][item] = (string)value;

  Public.Tools.ConfigFiles.Config.write_section(config_file, section, values[section]);
}

//! returns a string containing the first occurrance of a configuration 
//! variable item in configuration section "section".
string get_value(string section, string item)
{
  string val;

  if(!values[section])
  {
    throw(Error.Generic("Unable to find configuration section " + section + ".\n"));
  }

  else if(!values[section][item] && zero_type(values[section][item]))
  {
    throw(Error.Generic("Item " + item + " in configuration section " + section + " does not exist.\n"));
  }

  else if(arrayp(values[section][item]))
  {
    return values[section][item][0];
  }

  else return values[section][item];
}


//! returns an array containing all occurrances of a configuration 
//! variable item in configuration section "section".
array get_value_array(string section, string item)
{
  array val;

  if(!values[section])
  {
    throw(Error.Generic("Unable to find configuration section " + section + ".\n"));
  }

  else if(!values[section][item] && zero_type(values[section][item]))
  {
    throw(Error.Generic("Item " + item + " in configuration section " + section + " does not exist.\n"));
  }

  else if(arrayp(values[section][item]))
  {
    values[section][item];
  }

  else return ({ values[section][item] }); 
}

//!
mixed `[](string arg)
{
  //      werror("GOT %O\n", arg);
  return values[arg];

}

int(0..1) _is_type(string t)
{
  int v=0;

  switch(t)
  {
    case "mapping":
      v = 1;
    break;
  }

  return v;
}

