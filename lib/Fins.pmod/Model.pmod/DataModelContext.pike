
Sql.Sql sql;

string _sprintf(mixed ... args)
{
  return "DataModelContext(" + sql->host_info() + ")";
}

string quote(string s)
{
   return sql->quote(s);
}

string type()
{
  return (sprintf("%O", object_program(sql->master_sql))/".")[-1];
}

int debug = 0;

object repository;

program personality()
{
  if(!sql) throw(Error.Generic("No SQL connection defined.\n"));

  return Fins.Model.Personality[type()];
}

int initialize()
{
  program p = personality();
  if(!p) throw(Error.Generic("Unknown database type. No personality.\n"));

  object dp = p(sql);

  dp->initialize();
}
