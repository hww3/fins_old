//! retrieves a value from a mapping given a dot separated variable name. 
//! 
//! @returns 
//!  the variable (or zero if not present)
mixed get_var_value(string varname, mixed var)
{
  mixed myvar = var;

//  TODO: this is an incompatible change where we assume that values 
//  that do not start with $ are constants, otherwise we look them up.
//  if(varname[0] != '$') return varname;
//  else varname = varname[1..];

  // we can employ the "fly by the seat of the pants" method, because 
  // if we fail to get a value somewhere along the way, we want an error
  // to be thrown.
  foreach(varname/".";; string vn)
  {
    myvar = myvar[vn];
  }

  return myvar;
}
