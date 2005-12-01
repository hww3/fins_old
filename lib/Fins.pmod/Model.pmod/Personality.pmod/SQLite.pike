inherit .Personality;

int initialize()
{
  sql->query("PRAGMA full_column_names=1");

  return 1;
}
