//! formats a string using named parameters, in the format
//! of %{param} where "param" is a key in the data
//! set being used for replacements. Additionally, if a 
//! parameter contains a colon (:), anything following the colon
//! will be considered a formatting option to sprintf for the data.
//! If no formatting options are specified, the data will be cast 
//! to a string and be inserted into the final string as if %s were 
//! passed in @[sprintf](). If formatting options are specified,
//! the data will be passed as-is.
//!
//! @param format
//!   format string, containing replacement fields in the form
//!   of %{param}
//!
//! @param data
//!  a mapping with data to be replaced
//!
//! @example
//! > Tools.String.named_sprintf("Hello, %{name}. Lunch will be $%{cost:.2f}.",
//!              (["name": "James", "planet": "Mars", "cost": 2.5])); 
//! (2) Result: "Hello, James. Lunch will be $2.50."
//!
string named_sprintf(string format, mapping data)
{
  return named_sprintf_func(format)(data);
}

//! generates a function that takes a single argument, a mapping
//! containing replacement values for the format string provided 
//! as the argument to this function. Useful for caching the 
//! generated function for speed.
//!
//! the generated function uses sprintf to format the data, which
//! are assumed to be strings, or castable to strings.
function named_sprintf_func(string format)
{
  // parse format for values like %{name}.

  array keys = ({});
  String.Buffer current_tag = String.Buffer();
  int in_tag;
  String.Buffer xformed = String.Buffer();

  for(int i=0; i<sizeof(format); i++)
  {
    int c = format[i];

    if(c == '%')
    {
      if(in_tag)
      {
        throw(Error.Generic("invalid character '%' in format string at character " + i + "."));
      }
      else if(format[i+1] == '{')
     {
       in_tag = 1;
       i++;
       continue;
     }
     else
     {
       xformed += "%";
     }
    }
    else if(in_tag)
    {
      if(c == '}')
      {
        string tag = current_tag->get();
        string format;
        array x = tag / ":";
        if(sizeof(x) > 1)
        {
          tag = x[0];
          format  = x[1];
        }
        if(format) xformed += ("%" + format);
        else xformed += "%s";
        keys+=({sprintf((format?"":"(string)") + "d[%O]", tag)});
        in_tag = 0;
      }
      else
      {
        current_tag += format[i..i];
      }
    }
    else
    {
      xformed += format[i..i];
    }
  }

  string func = "string p(mapping d){return sprintf(" + 
        sprintf("%O", xformed->get()) + "," + keys*", " + ");}";
  return compile(func)()->p;
}

