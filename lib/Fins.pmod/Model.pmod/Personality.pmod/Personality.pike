object sql;
object context;

int use_datadir;
string datadir;

static void create(object s, object c)
{
  sql = s;
  context = c;
}

int initialize()
{
  return 1;
}

string get_serial_insert_value()
{
	return "NULL";
}


string make_fn(string s)
{
  return  (string)hash(s + time());
}

string quote_binary(string s)
{
  if(!use_datadir)
    return replace(s, ({"%", "'", "\000"}), ({"%25", "%27", "%00"}));
  else
  {
    string fn = make_fn(s);
    string mfn = Stdio.append_path(datadir, fn);
    Stdio.write_file(mfn, s);
    return fn;
  }
}

string unquote_binary(string s)
{
  if(!use_datadir)
    return replace(s, ({"%25", "%27", "%00"}), ({"%", "'", "\000"}));

  else
  {
    return Stdio.read_file(Stdio.append_path(datadir, s));
  }
}


