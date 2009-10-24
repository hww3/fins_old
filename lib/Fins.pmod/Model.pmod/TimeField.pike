//! a field representing a day and time in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! (note that this is not a recommended way, as it's slow and 
//! the parsing accuracy is not guaranteed.

inherit .DateField;

constant type = "Time";

program unit_program = Calendar.Second;
function unit_parse = Calendar.ISO.dwim_time;
string output_unit_format = "%h:%m:%s";


string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  if(stringp(value)) return sprintf("'%s'", value);

  return "'" + value->format_tod() + "'";
}

string get_display_string(void|mixed value, void|.DataObjectInstance i)
{
	if(value && objectp(value))
    	return value->format_tod();
	else return (string)value;
}

string get_editor_string(void|mixed value, void|.DataObjectInstance i)
{
	werror("TimeField.get_editor_string(%O, %O)\n", value, i);
  string rv = "";
  if(i) rv +=("<input type=\"hidden\" name=\"__old_value_" + name + "\" value=\"" + 
				(value?value->format_tod():"") + "\">" );
  rv += "<input type=\"text\" name=\"" + name + "\" value=\"";
  if(i) rv+=(value?value->format_tod():"");
  rv += "\">";

  return rv;
}
