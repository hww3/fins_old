inherit .CompoundCriteria;

//!
string get(string|void name, void|int datao)
{
   return "(" + ((acriteria->get(name, datao))*" AND ") + ")";
}

//!
string get_criteria_type()
{
  return "AND";
}
