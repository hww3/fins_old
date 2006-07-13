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

//!
public void add(string err)
{
  errors += ({ err });

  error_message = error_message += err;
}
