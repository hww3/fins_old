inherit .Personality;

int use_datadir;
string datadir;

int initialize()
{

  if(!Sql.Provider.SQLite.__version || (float)(Sql.Provider.SQLite.__version) < 1.8)
    error("Your version of SQL.Provider.SQLite is too old. You must use at least version 1.8.\n");

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


