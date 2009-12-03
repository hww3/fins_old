inherit .Personality;

int use_datadir;
string datadir;

mapping indexes = ([]);

int initialize()
{

#if constant(Sql.Provider.SQLite)
error("SQL.Provider.SQLite is not supported.\n");
#endif

  sql->query("PRAGMA full_column_names=1");

  if((int)(context->model->config["model"]["datadir"]))
  {
    use_datadir = 1;
    datadir = context->model->config["model"]["datadir"];
  }

  return 1;
}


string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + limit + (start?(" OFFSET " + ((start-1)||"0")):"");
}

mapping get_field_info(string table, string field, mapping info)
{  
  if(!indexes[table])
    load_indexes(table);

  mapping i = indexes[table];
  mapping m = ([]);

  foreach(i;; mapping ind)
  {
    if(ind->name == field) 
    {
      if(ind->unique == "1") m->unique = 1;
    }
  }

  if(info && (<"datetime", "timestamp", "date", "time">)[info->type])
  {
	switch(upper_case(info->default))
	{
		case "CURRENT_TIME":
		case "CURRENT_DATE":
		case "CURRENT_TIMESTAMP":
		werror("******\n******\n******\n");
			m->default = Fins.Model.Undefined;
			m->type_class = Fins.Model.SqliteDateTimeField;
	}
  }

  return m;
}

void load_indexes(string table)
{
  array x = sql->query("PRAGMA index_list(" + table + ")");

  if(!indexes[table]) indexes[table] = ([]);

  if(x) foreach(x;; mapping m)
  {
    array ii = sql->query("PRAGMA index_info(" + m->name + ")");
    foreach(ii;; mapping ir)
    {
      indexes[table][m->name] = ir + (["unique": m->unique]);
    }
  }
}

int(0..1) transaction_supported()
{
  return 1;
}

void begin_transaction()
{
  context->sql->query("BEGIN TRANSACTION");
}

void rollback_transaction()
{
  context->sql->query("ROLLBACK");
}

void commit_transaction()
{
  context->sql->query("COMMIT");
}