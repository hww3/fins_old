inherit .DateField;

//! a field representing a day and time in a database.
//! values that may be passed include a calendar object,
//! an integer (which will be interpreted as a unix timestamp)
//! or a string, which will be parsed for a workable date format
//! @note 
//!  that this is not a recommended way, as it's slow and 
//!  the parsing accuracy is not guaranteed.

constant type = "DateTime";
int includetime = 1;
program unit_program = Calendar.Second;
function unit_parse = Calendar.ISO.dwim_time;
string output_unit_format = "%Y-%M-%D %h:%m:%s";

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value);

  if(value == .Undefined)
  {
    return "NULL";
  }

  if(stringp(value)) return sprintf("'%s'", value);
  return "'" + value->format_time() + "'";
}

string describe(mixed v, void|.DataObjectInstance i)
{
  return v->format_time();
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


        if(includetime)
        {
  	  rrv += " &nbsp; ";
          vals = ({});
          foreach(({"hour_no", "minute_no", "second_no"});; string part)
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
		  case "hour_no":
		    from = 0; to = 23;
		    break;
		  case "minute_no":
		    from = 0; to = 59;
		    break;
		  case "second_no":
		    from = 0; to = 59;
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

	rrv += (vals * " : ");
      }
      return rrv;
}


mixed from_form(mapping value, void|.DataObjectInstance i)
{
  object c = Calendar.dwim_time(sprintf("%04d-%02d-%02d %02d:%02d:%02d", (int)value->year_no,
                (int)value->month_no, (int)value->month_day, (int)value->hour_no, (int)value->minute_no, (int)value->second_no));
        return c;
}




