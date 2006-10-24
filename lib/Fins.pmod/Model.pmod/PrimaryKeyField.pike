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
  // if we don't have an id set, we should get it.
  catch(v=i->get(name));

  if(v)
    return v;
  if(context->personality->get_last_insert_id)
  {
//	werror("context->personality->get_last_insert_id\n");
    return decode(context->personality->get_last_insert_id(this, i));
  }
  if(context->sql->master_sql->insert_id)
  {
//    werror("context->sql->master_sql->insert_id\n");
    return decode(context->sql->master_sql->insert_id());
  }
  if(context->sql->master_sql->last_insert_rowid)
  {
//    werror("context->sql->master_sql->last_insert_rowid\n");
    return decode(context->sql->master_sql->last_insert_rowid());
  }
}

int decode(string value, void|.DataObjectInstance i)
{
   return (int)value;
}

string encode(mixed|void value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
    return context->personality->get_serial_insert_value();

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
