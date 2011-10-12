//! an object which provides context to the JSON rendering process.
//! 
//! filters may either be a multiset containing a list of filters to 
//! exclude from the rendered json, or a function that takes the 
//! field name and value of a field and returns true to exclude the
//! value from the rendered json.
//!
//! if a given program does not have a specified filter, then the default
//! filter will be returned.
protected multiset|function default_filter=(<>);

protected mapping(program:multiset|function) program_filters = ([]);

//!
void set_filter_for_program(program p, multiset|function f)
{
  program_filters[p] = f;
}

//!
multiset get_filter_for_program(program p)
{
  return program_filters[p] || default_filter || (<>);
}

//!	
void set_default_filter(multiset|function f)
{ 
  default_filter = f;
}
	
//!
multiset get_default_filter()
{ 
  return default_filter || (<>);
}

