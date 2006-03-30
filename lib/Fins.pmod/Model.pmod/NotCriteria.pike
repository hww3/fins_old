inherit .Criteria;

.Criteria ncriteria;

static void create(.Criteria c)
{
  ncriteria = c;
}

string get(string|void name, void|int datao)
{
   return "! (" + (ncriteria->get(name, datao)) + ")";
}

string get_criteria_type()
{
  return "NOT";
}
