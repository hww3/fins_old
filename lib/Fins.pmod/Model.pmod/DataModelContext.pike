//!
int debug = 0;

//!
object repository;

//!
object cache;

//! 
object personality;

//!
object app;

//!
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

program get_personality()
{
  if(!sql) throw(Error.Generic("No SQL connection defined.\n"));

  return .Personality[type()];
}

int initialize()
{
  program p = get_personality();
  if(!p) throw(Error.Generic("Unknown database type. No personality.\n"));

  personality = p(sql);

  personality->initialize();
}
