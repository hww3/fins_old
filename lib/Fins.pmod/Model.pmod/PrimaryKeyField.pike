inherit .Field;

string name;

static void create(string _name)
{
   name = _name;
   ::create();
}

mixed get_id(void|.DataObjectInstance i)
{
  mixed v;
  if(v=i->get(name))
    return v;
  else if(context->sql->master_sql->insert_id)
    return decode(context->sql->master_sql->insert_id());
  else if(context->sql->master_sql->last_insert_rowid)
    return decode(context->sql->master_sql->last_insert_rowid());
}

int decode(string value, void|.DataObjectInstance i)
{
   return (int)value;
}

string encode(mixed|void value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
    return "NULL";

  return (string)value;
}

mixed validate(mixed|void value, void|.DataObjectInstance i)
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
