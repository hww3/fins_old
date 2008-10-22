inherit .Criteria;

string operator;
mixed value;

static void create(string _operator, mixed _value)
{
  operator = _operator;
  value = _value;
}

//!
string get(string|void name, object datao)
{
  return sprintf("%s %s %s", name, operator, datao->fields[name]->encode(value));
}
