inherit .Field;

int len;
int null;
mixed default_value;
string name;

constant type = "Float";

void create(string _name, int _len, int(0..1) _null, int|void _default)
{
   name = _name;
   len = _len;
   null = _null;
   if(_default != UNDEFINED) 
     default_value = _default;
   else default_value = .Undefined;

   ::create();
}

int decode(string value, void|.DataModelInstance i)
{
   return (float)value;
}

string encode(mixed value, void|.DataModelInstance i)
{
  value = validate(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  return (string)value;
}

mixed validate(mixed value, void|.DataModelInstance i)
{
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

   if(!floatp(value))
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}