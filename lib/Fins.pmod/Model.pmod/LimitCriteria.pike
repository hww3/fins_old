int start, limit;

static string criteria = "";

string _sprintf(mixed ...args)
{
   return "LimitCriteria(" + start + ", " + limit + ")";
}
static void create(int _limit, int|void _start)
{
   limit = _limit;

   if(_start) start= _start;
}

string get(string|void name, object|void datao)
{
   return datao->context->personality->get_limit_clause(limit, start);
}

string get_criteria_type()
{
  return "LIMIT";
}
