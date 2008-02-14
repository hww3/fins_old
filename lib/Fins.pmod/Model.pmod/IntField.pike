inherit .Field;

int len;
int null;
mixed default_value;
string name;

constant type = "Integer";

// note should we have validation here?
string get_editor_string(void|string value, void|.DataObjectInstance i)
{
  if(!value && zero_type(value)) value = "";

  if(i)
  {
    return ("<input type=\"hidden\" name=\"__old_value_" + name + "\" value=\"" + value + "\">" "<input type=\"text\" size=\"" + len + "\" name=\"" + name + "\" value = \"" + value + "\">");
  }
  else
  {
    return ("<input type=\"text\" size=\"" + len + "\" name=\"" + name + "\" value = \"\">"); 
  }
}

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

int decode(string value, void|.DataObjectInstance i)
{
   return (int)value;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  return (string)value;
}

mixed validate(mixed value, void|.DataObjectInstance i)
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

  else if(stringp(value))
  {
    int v;
    if(!sscanf(value, "%d", v))
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
    else return v;
  }

  else if(!intp(value))
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}
