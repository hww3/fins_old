//! a field representing a day in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! (note that this is not a recommended way, as it's slow and 
//! the parsing accuracy is not guaranteed.

inherit .Field;

constant type = "Date";

program unit_program = Calendar.Day;
function unit_parse = Calendar.ISO.dwim_day;
string output_unit_format = "%Y-%M-%D";
int null;
mixed default_value;
string name;

//! @param _default
//! default may be either a Calendar object, a calendar class
//! or a function that returns a calendar object.
//! if either a class or a function is set as default, the 
//! function will be called or the class will be instantiated
//! at the time of the query, useful for datestamps.
static void create(string _name, int(0..1) _null, mixed|void _default)
{
   name = _name;
   null = _null;
   if(_default != UNDEFINED) 
     default_value = _default;
   else default_value = .Undefined;

   ::create();

}

object decode(string value, void|.DataObjectInstance i)
{
   return Calendar.parse(output_unit_format, value);
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  return "'" + value->format_ymd() + "'";
}

mixed validate(mixed value, void|.DataObjectInstance i)
{
   if(value == .Undefined && !null && default_value == .Undefined)
   {
     throw(Error.Generic("Field " + name + " cannot be null; no default value specified.\n"));
   }

   else if (value == .Undefined && !null && default_value!= .Undefined)
   {
     if(functionp(default_value) || programp(default_value))
       return default_value();
     else return default_value;
   }

   else if (value == .Undefined)
   {
     return .Undefined;
   }

   if(intp(value))
   {
      return unit_program("unix", value);
   }
   if(stringp(value))
   {
     return unit_parse(value);
   }
   if(objectp(value) && Program.implements(object_program(value), unit_program))
   {
     return value;
   }
   else
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}


string get_editor_string(void|mixed value, void|.DataObjectInstance i)
{
	string rv = "";
	
	foreach(({"month", "month_day", "year"});; string part)
	{
		if(i)
  		  rv += "<input type=\"hidden\" name=\"\"__old_value_" + name + "__" + part + "\" value=\"" + value[part + "_no"]() + "\">";
		rv += "<input type=\"text\" name=\"_" + name + "__" + part + "\" value=\"" + (i?value[part + "_no"]():"") + "\">";
	}

	return rv;
}


mixed from_form(mapping value, void|.DataObjectInstance i)
{
	return Calendar.now();
}
