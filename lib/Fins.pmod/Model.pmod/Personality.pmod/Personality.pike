import Tools.Logging;

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

// there's little agreement here, so we'll have to override this everwhere.
// start is the starting point from which to begin the limit, where the first record is record 1.
string get_limit_clause(int limit, int|void start)
{
  return "";
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

mapping map_field(mapping t)
{
  Log.debug("mapping field %O.", t);
  mapping field = ([]);

  field->name = t->name;
  field->primary_key = t->flags->primary_key;

  switch(t->type)
  {
    case "string":
    case "char":
    case "varchar":
    case "text":
      if(t->default && sizeof(t->default)) field->default = t->default;
      field->type = "string";
      field->length = t->length;
      break;
    case "datetime":
      field->type = "datetime";
      break;
    case "integer":
    case "long":
      if(t->default) field->default = (int)t->default;
      field->type = "integer";
      break;
    case "blob":
      field->type = "binary_string";
      break;
    default:
      throw(Error.Generic("unknown field type " + t->type + ".\n"));
  }

  field->not_null = t->flags->not_null;

  return field;
}
