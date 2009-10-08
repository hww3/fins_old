inherit .Personality;


string quote_binary(string s)
{
  return sql->quote(s);
}

string unquote_binary(string s)
{
  return s;
}

string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + (start?(((start-1)||"0") + ", "):"") + limit;
}

mapping get_field_info(string table, string field)
{  
  mapping m = ([]);

  array r = sql->query("SHOW FIELDS FROM " + table + " LIKE '" + field + "'"); 
  if(!sizeof(r)) throw(Error.Generic("Field " + field + " does not exist in " + table + ".\n"));

  if(has_prefix(r[0]->Type, "timestamp")) m->type = "timestamp";
  else m->type = r[0]->Type;
  if(r[0]->Key && r[0]->Key == "UNI") m->unique = 1;

  return m;
}

int(0..1) transaction_supported()
{
//
// TODO: not strictly true, we need to do more here.
//
  return 1;
}

void begin_transaction()
{
  context->sql->query("START TRANSACTION");
}

void rollback_transaction()
{
  context->sql->query("ROLLBACK");
}

void commit_transaction()
{
  context->sql->query("COMMIT");
}