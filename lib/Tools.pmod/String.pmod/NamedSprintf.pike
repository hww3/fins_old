//! formats a string using named parameters, in the format
//! of %{param} where "param" is a key in the data
//! set being used for replacements.
//!
//! @param format
//!   format string, containing replacement fields in the form
//!   of %{param}
//!
//! @param data
//!  a mapping with data to be replaced
//!
//! @example
//!  Tools.String.named_sprintf("Welcome, %{name}", (["name": "bob"]));
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
        xformed += "%s";
        keys+=({sprintf("(string)d[%O]", current_tag->get())});
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
