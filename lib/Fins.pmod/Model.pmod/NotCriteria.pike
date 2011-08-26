inherit .Criteria;

.Criteria|string ncriteria;

static void create(.Criteria|string c)
{
  ncriteria = c;
}

string get(string|void name, void|int datao)
{
   if(stringp(ncriteria))
      return "NOT (" + ncriteria + ")";
   else
     return "NOT (" + (ncriteria->get(name, datao)) + ")";
}

string get_criteria_type()
{
  return "NOT";
}
