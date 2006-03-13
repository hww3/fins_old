

static array acriteria = ({});

string _sprintf(mixed ...args)
{
   return "CompoundCriteria(" + get() + ")";
}

static void create(array(.Criteria) _criteria)
{
   acriteria = _criteria;
}

string get(string|void name, void|int datao)
{
   return (acriteria->get(name, datao))*" ";
}

string get_criteria_type()
{
  return "COMPOUND";
}
