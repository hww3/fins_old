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


