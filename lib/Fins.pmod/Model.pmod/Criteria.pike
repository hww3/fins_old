
//!

static string criteria = "";

string _sprintf(mixed ...args)
{
   return "Criteria(" + criteria + ")";
}

//!
static void create(string _criteria)
{
   criteria = _criteria;
}

//!
string get(string|void name, object|void datao)
{
   return criteria;
}

//!
string get_criteria_type()
{
  return "GENERIC";
}
