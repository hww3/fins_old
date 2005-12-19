object sql;

static void create(object s)
{
  sql = s;
}

int initialize()
{
  return 1;
}

string get_serial_insert_value()
{
	return "NULL";
}