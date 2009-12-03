//! a special date time field that causes the field to be skipped during a default update so that 
//! sqlite will insert the current date/time/timestamp

inherit .DateTimeField;

string encode(mixed value, void|.DataObjectInstance i)
{
  value = validate(value, i);

  if(value == .Undefined)
  {
    return 0;
  }

  if(stringp(value)) return sprintf("'%s'", value);

  return "'" + value->format_time() + "'";
}

mixed validate(mixed value, void|.DataObjectInstance i)
{
werror("%O\n", i);
   if(value == .Undefined && !null && default_value == .Undefined && !i->is_new_object())
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
