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
  array r = sql->query("SHOW FIELDS FROM " + table + " LIKE '" + field + "'"); 
  if(!sizeof(r)) throw(Error.Generic("Field " + field + " does not exist in " + table + ".\n"));
  if(has_prefix(r[0]->Type, "timestamp")) r[0]->type = "timestamp";
  else r[0]->type = r[0]->Type;

  return r[0];
}
