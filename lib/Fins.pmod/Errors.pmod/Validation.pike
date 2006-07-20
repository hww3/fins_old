inherit global.Error.Generic;

//!
constant error_type = "validation";

//!
constant is_validation_error = 1;

private array errors = ({});

//!
public array validation_errors()
{
  return errors;
}


//! add an error to the object.
//!
//! if a and b are provided, a is the field that is associated with the error
//! and b is the description of the problem. the field name will be "humanized".
//!
//! if a alone is provided, it is the error string (usually one not associated 
//! with a single field.)
public void add(string a, string|void b)
{
  string e; 

  if(b)
    e = Tools.Language.Inflect.humanize(a) + " " + b;
  else
    e = a;
  errors += ({ e });

  error_message = error_message += (e + "\n");
}
