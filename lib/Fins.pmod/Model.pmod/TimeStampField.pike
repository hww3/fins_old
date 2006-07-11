//! a field representing a day and time in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! (note that this is not a recommended way, as it's slow and 
//! the parsing accuracy is not guaranteed.

inherit .DateField;

constant type = "TimeStamp";

program unit_program = Calendar.Second;
function unit_parse = Calendar.ISO.dwim_time;
string output_unit_format = "%Y%M%D%h%m%s";

static void create(string _name, int(0..1) _null)
{
   name = _name;
   null = _null;
   field_name = translate_fieldname();

}


string encode(mixed value, void|.DataObjectInstance i)
{
    return "NULL";
}


mixed validate(mixed value, void|.DataObjectInstance i)
{
  throw(Error.Generic("TimeStamp fields cannot be set.\n"));
}

object decode(string value, void|.DataObjectInstance i)
{
  werror("decoding " + value + "\n");
}
