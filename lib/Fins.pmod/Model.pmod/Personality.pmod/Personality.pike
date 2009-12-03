object log = Tools.Logging.get_logger("model.personality");
object sql;
object context;

int use_datadir;
string datadir;

mapping get_field_info(string table, string field, mapping|void info);

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

array(mapping) list_fields(string table)
{
   array x = sql->list_fields(table);
   return map(x, map_field, table);
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

mapping map_field(mapping t, string table)
{
  log->debug("mapping field %O.", t);
  mapping field = ([]);

  field->name = t->name;

  if(!t->flags)
    t->flags = ([]);

  field->primary_key = t->flags->primary_key;

  if(this->get_field_info)
  { 
    mapping x = this->get_field_info(t->table, t->name, t);
    if(t->type != "unknown")
      m_delete(x, "type");

	t = t + x;
  }

  if(t->default)
    field->default = t->default;
  if(t->type_class)
    field->type_class = t->type_class;

  log->debug("Field %s.%s is a %s.", t->table, t->name, t->type); 

//  werror("mapping field %O\n", t);
  switch(lower_case(t->type))
  {
    case "string":
    case "var string":
    case "char":
    case "varchar":
    case "text":
      if(t->default && sizeof(t->default)) field->default = t->default;
      field->type = "string";
	  if((int)t->length)
        field->length = t->length;
      else
      {
        if(t->type == "text")
          field->length = 1024;
      }
      break;
    case "time":
      field->type = "time";
      break;
    case "date":
      field->type = "date";
    case "datetime":
      field->type = "datetime";
      break;
    case "timestamp":
      field->type = "timestamp";
      break;
    case "integer":
    case "long":
      field->type = "integer";
      break;
    case "float":
      field->type = "float";
      break;
    case "blob":
      field->type = "binary_string";
	  if((int)t->length)
        field->length = t->length;
      else
      {
	     if(t->type == "blob")
	       field->length = 32200;
	  }
      break;
    case "mediumblob":
      field->type = "binary_string";
	  if((int)t->length)
        field->length = t->length;
      else
      {
	     if(t->type == "blob")
	       field->length = 1664400;
	  }
      break;
    default:
      throw(Error.Generic("unknown field type " + t->type + ".\n"));
  }

  field->unique = t->unique;
  field->not_null = t->flags->not_null;

  return field;
}

int(0..1) transaction_supported()
{
  return 0;
}

void begin_transaction()
{
  throw(Fins.Errors.ModelError("Transactions are not supported by this database engine.\n"));
}

void rollback_transaction()
{
  throw(Fins.Errors.ModelError("Transactions are not supported by this database engine.\n"));
}

void commit_transaction()
{
  throw(Fins.Errors.ModelError("Transactions are not supported by this database engine.\n"));
}