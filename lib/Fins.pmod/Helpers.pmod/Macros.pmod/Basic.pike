inherit .Base;

string simple_macro_sessionid(Fins.Template.TemplateData data, mapping|void args)
{
  return data->get_request()->misc->session_id;
}

//! args: var
string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(get_var_value(args->var, data->get_data())||"");
}

//! args: var
string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    return (get_var_value(args->var, data->get_flash())||"");
}

//! args: var
string simple_macro_sizeof(Fins.Template.TemplateData data, mapping|void args)
{
    return (string)(sizeof(get_var_value(args->var, data->get_data())||({})));
}

//! args: var, splice, final
string simple_macro_implode(Fins.Template.TemplateData data, mapping|void args)
{
  mixed v = get_var_value(args->var, data->get_data());

  if(!arrayp(v))
    return "invalid type for " + args->var;

  string retval = "";

  if(args->nice)
  {
    retval = String.implode_nicely(v, args->nice);
  }
  else
  {
    retval = v*args->final;
  }
  
  return retval;
}
	
//! args: var
string simple_macro_boolean(Fins.Template.TemplateData data, mapping|void args)
{
        mixed v = get_var_value(args->var, data->get_data());
                if (intp(v))
                {
                        return (v != 0)?"Yes":"No";
                }
                else if(stringp(v))
                {
                        return ((int)v != 0)?"Yes":"No";
                }
                else
                {
                        return "invalid type for boolean ";
                }
}

//! args: var, format
//! where format is a Calendar object format type; default is ext_ymd.
string simple_macro_format_date(Fins.Template.TemplateData data, mapping|void arguments)
{
  if(arguments->var)
  {
    object p = get_var_value(arguments->var, data->get_data());

    if(!p) return "";

    if(! arguments->format) arguments->format="ext_ymd";

    return p["format_" + arguments->format]();

  }
}

