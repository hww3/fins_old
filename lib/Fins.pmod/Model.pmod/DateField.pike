//! a field representing a day in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! (note that this is not a recommended way, as it's slow and 
//! the parsing accuracy is not guaranteed.

inherit .Field;

constant type = "Date";

int includetime=0;
program unit_program = Calendar.Day;
function unit_parse = Calendar.ISO.dwim_day;
string output_unit_format = "%Y-%M-%D";
int null;
mixed default_value;
string name;

function encode_get = encode;
function validate_get = validate;

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
   { 
     default_value = _default;
   }
   else default_value = .Undefined;

   ::create();

}

object decode(string value, void|.DataObjectInstance i)
{
   object x;
   catch {
     x = Calendar.parse(output_unit_format, value);
   };
   return x;
}

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value, i);

  if(value == .Undefined)
  {
    return "NULL";
  }

  if(stringp(value)) return sprintf("'%s'", value);

  return "'" + value->format_ymd() + "'";
}

string describe(mixed v, void|.DataObjectInstance i)
{
  v->format_ymd();
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

	// uuuugly!
     if(default_value == "NULL")
       return .Undefined;
     else return default_value;
   }

   else if (value == .Undefined || value == "")
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

   if(objectp(value) && value->is_timerange)
   {
     return value;
   }

   if(objectp(value) && Program.implements(object_program(value), unit_program))
   {
     return value;
   }

   if(objectp(value) && Program.implements(object_program(value), Calendar.TimeRange))
   {
     return value;
   }

   else
   {
      throw(Error.Generic("Cannot set " + name + " using " + basetype(value) + ".\n"));
   }
   
   return value;
}

string get_display_string(void|mixed value, void|.DataObjectInstance i)
{
	if(value && objectp(value))
    	return value->format_ymd();
	else return (string)value;
}

string get_editor_string(void|mixed value, void|.DataObjectInstance i)
{
        string rrv = "";
        int def = 0;
        array vals = ({});

        if(!value)
        { 
          def = 1; 
          value = Calendar.now();
        }
        foreach(({"month_no", "month_day", "year_no"});; string part)
        {
	        string rv = "";
		string current_val = 0;
		int from, to;

                if(value)
                {
		  current_val = value[part]();
		}

		switch(part)
		{
		  case "month_no":
		    from = 1; to = 12;
		    break;
		  case "year_no":
		    object cy;
		    if(current_val) cy = Calendar.ISO.Year(current_val); else cy = Calendar.ISO.Year();
		    from = (cy - 80)->year_no(); to = (cy + 20)->year_no();
		    break;
		  case "month_day":
		    from = 1; to = 31;
		    break;
		}
		rv += "<select name=\"_" + name + "__" + part + "\">\n";
		for(int i = from; i <= to; i++) 
                  rv += "<option " + ((int)current_val == i?"selected":"") + ">" + i + "\n";
		rv += "</select>\n";

		if(!def)
                  rv += "<input type=\"hidden\" name=\"\"__old_value_" + name + "__" + part + "\" value=\"" + current_val + "\">";
	
		vals += ({rv});
        }

	rrv += (vals * " / ");

      return rrv;
}


mixed from_form(mapping value, void|.DataObjectInstance i)
{
  object c = Calendar.dwim_time(sprintf("%04d-%02d-%02d", (int)value->year_no, (int)value->month_no, (int)value->month_day));
        return c;
}


string make_qualifier(mixed v)
{
	if(objectp(v))
	{
		if(v->is_second)
		   return field_name + " = " + encode_get(v);
		else if(v->beginning && v->end)
		{
			return "(" + field_name  + " >= " + encode_get(v->beginning()) + " AND " + field_name + " < " + encode_get(v->end()) + ")";
		}
	}
	else
  		return field_name + "=" + encode_get(v);
}


