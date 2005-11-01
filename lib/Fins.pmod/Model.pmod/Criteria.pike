

static string criteria = "";

string _sprintf(mixed ...args)
{
   return "Criteria(" + criteria + ")";
}
static void create(string _criteria)
{
   criteria = _criteria;
}

string get()
{
   return criteria;
}