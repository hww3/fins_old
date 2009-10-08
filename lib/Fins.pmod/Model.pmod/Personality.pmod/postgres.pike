inherit .Personality;

string get_serial_insert_value()
{
	return "DEFAULT";
}

string get_last_insert_id(object field, object i)
{
	string t, f;
	
	t = i->master_object->table_name;
	f = field->field_name;
	

	array a = sql->query("select currval('" + t + "_" + f + "_seq')");

   return a[0]["currval"];
}


string get_limit_clause(int limit, int|void start)
{
  return "LIMIT " + limit + (start?(" OFFSET " + start):"");
}


int(0..1) transaction_supported()
{
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