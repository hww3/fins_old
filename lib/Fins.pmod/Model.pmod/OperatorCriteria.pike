inherit .Criteria;

string operator;
mixed value;

static void create(string _operator, mixed _value)
{

}

//!
string get(string|void name, object datao)
{
  return sprintf("%s %s %s", name, operator, datao->fields[name]->make_qualifier(value));
//   return sprintf("%s LIKE '%s'", name, criteria);
}
