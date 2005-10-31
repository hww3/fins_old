inherit .Field;

string name;

static void create(string _name)
{
   name = _name;
   ::create();
}

int get_id()
{
  return decode(context->sql->master_sql->insert_id());
}

int decode(string value)
{
   return (int)value;
}

string encode(mixed|void value)
{
  value = validate(value);

  if(value == .Undefined)
    return "NULL";

  return (string)value;
}

mixed validate(mixed|void value)
{
   if(value == .Undefined)
   {
     return .Undefined;
   }

   if(!intp(value))
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}
