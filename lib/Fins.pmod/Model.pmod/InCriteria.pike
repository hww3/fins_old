
//!

static string criteria = "";

string _sprintf(mixed ...args)
{
   return "Criteria(" + criteria + ")";
}

//!
static void create(array values)
{
   values = values + ({});
   foreach(values;int i;string v)
   {
     values[i] = "'" + v + "'";
   }
   criteria = sprintf("IN(%s)", values*",");
}

//!
string get(string|void name, object|void datao)
{
   return name + " " + criteria;
}

//!
string get_criteria_type()
{
  return "IN";
}
