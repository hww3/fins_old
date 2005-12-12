inherit .Relationship;

mixed default_value = .Undefined;
int null = 0;
.Criteria criteria;

static void create(string _name, string _myfield, string _otherobject, void|.Criteria _criteria, void|int _null)
{
  name = _name;
  field_name = _myfield;
  otherobject = _otherobject;
  criteria = _criteria;
  null = _null;
}

// value should be the value of the link field, which is the primary key of the 
// other object we're about to get.
mixed decode(string value, void|.DataObjectInstance i)
{
  return i->master_object->context->repository["find_by_id"](otherobject, (int)value);
}

// value should be a dataobject instance of the type we're looking to set.
string encode(int|.DataObjectInstance value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(intp(value)) return (string)value;

  if(value->is_new_object())
  {
    value->save();
  }
    
  return (string)value->get_id();
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
   if(intp(value)) return value;

   if(value == .Undefined && !null && default_value == .Undefined)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if (value == .Undefined && !null && default_value!= .Undefined)
   {
     return default_value;
   }

   else if (value == .Undefined)
   {
     return .Undefined;
   }

   else if(value->get_type() != otherobject)
     throw(Error.Generic(sprintf("Got %O object, expected %s.\n", value->get_type(), otherobject)));

   return value;
}
