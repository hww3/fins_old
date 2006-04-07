inherit .Personality;

int use_datadir;
string datadir;

int initialize()
{
  sql->query("PRAGMA full_column_names=1");

  if((int)(context->app->config["model"]["datadir"]))
  {
    use_datadir = 1;
    datadir = context->app->config["model"]["datadir"];
  }

  return 1;
}


string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + limit + (start?(" OFFSET " + ((start-1)||"0")):"");
}


