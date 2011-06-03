inherit .Field;

int len;
int null;
string name;
string default_value;

constant type = "String";

string get_editor_string(void|string value, void|.DataObjectInstance i)
{
  if(!value && zero_type(value)) value = "";

  if(i)
  {
    if(len < 60) return ("<input type=\"hidden\" name=\"__old_value_" + name + "\" value=\"" + value + "\">" "<input type=\"text\" size=\"" + len + "\" name=\"" + name + "\" value = \"" + value + "\">");
    else return ("<textarea name=\"" + name  + "\" rows=\"5\" cols=\"80\">" + value + "</textarea>" "<input type=\"hidden\" name=\"__old_value_" + name + "\" value=\"" + value + "\">" );
  }
  else
  {
    if(len < 60) return ("<input type=\"text\" size=\"" + len + "\" name=\"" + name + "\" value = \"\">");
    else return ("<textarea name=\"" + name  + "\" rows=\"5\" cols=\"80\"></textarea>");
	 
  }
}

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
   {  //werror("default value %s\n", default_value);
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
   if(len && sizeof(value) > len)
   {
      throw(Error.Generic("Value is too long; maximum length is " + len + ".\n"));
   }
   
   return value;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value, i);
//werror("validated value " + value + "\n");
  if(value == .Undefined)
    return "NULL";
  else
    return "'" + context->quote(value) + "'";
}
