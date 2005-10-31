inherit .Field;

int len;
int null;
string name;
string default_value;

constant type = "String";

void create(string _name, int _len, int(0..1) _null, string|void _default)
{
   name = _name;
   len = _len;
   null = _null;
   default_value = _default;
   ::create();
}

mixed validate(mixed value, void|.DataObjectInstance i)
{
   if(value == .Undefined && !null && !default_value)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if(value == .Undefined && !null && default_value)
   {
     return default_value;
   }
 
   else if(value == .Undefined)
   {
     return .Undefined;
   }

   if(!stringp(value))
   {
      if(catch(value = (string)value))
      {
         throw(Error.Generic("Unable to cast " + basetype(value) + " to a string.\n"));
      }
   }
   if(sizeof(value) > len)
   {
      throw(Error.Generic("Value is too long; maximum length is " + len + ".\n"));
   }
   
   return value;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);
  if(value == .Undefined)
    return "NULL";
  else
    return "'" + context->quote(value) + "'";
}
