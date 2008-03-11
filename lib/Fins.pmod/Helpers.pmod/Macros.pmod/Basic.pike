inherit .Base;

//!
string simple_macro_sessionid(Fins.Template.TemplateData data, mapping|void args)
{
  return data->get_request()->misc->session_id;
}

//! args id, string
string simple_macro_LOCALE(Fins.Template.TemplateData data, mapping|void args)
{
	object r = data->get_request();
	
//	werror("project: %O, language: %O", r->get_project(), r->get_lang());
	return Locale.translate(r->get_project(), r->get_lang(), (int)args["id"], args["string"]);
}

//! args: var
string simple_macro_humanize(Fins.Template.TemplateData data, mapping|void args)
{
  return Tools.Language.Inflect.humanize(get_var_value(args->var, data->get_data())||"");
}

//! args: 
string simple_macro_dump_data(Fins.Template.TemplateData data, mapping|void args)
{
  return sprintf("%O\n", mkmapping(indices(data->get_data()), values(data->get_data())));
}

//! args: 
string simple_macro_dump_id(Fins.Template.TemplateData data, mapping|void args)
{
  return sprintf("%O\n", mkmapping(indices(data->get_request()), values(data->get_request())));
}

//! args: name
string simple_macro_available_languages(Fins.Template.TemplateData data, mapping|void args)
{
    data->get_data()[args->name] = data->get_request()->fins_app->get_languages();	
	return "";
}


//! args: controller, action, args 
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_link(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
  object request = data->get_request();
  string event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = data->get_request()->fins_app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_link: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_link: action " + args->action + " can not be resolved.\n"));

  array uargs;
  mapping vars;

  if(args->args)
    uargs = args->args/"/";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");

  if(sizeof(args)) 
  {
    vars = args;  
    foreach(args; string k; string v)
    {
      v = get_var_value(v, data->get_data()) || "";
      args[k] = v;
    }
// werror("data: %O\n", data->get_data());
  }

  string url = data->get_request()->fins_app->url_for_action(action, uargs, vars);

  return "<a href=\"" + url + "\">";
}

//! args: controller, action, args 
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_url(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
//werror("******* action_url\n");
  object request = data->get_request();
  string event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = data->get_request()->fins_app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_link: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_link: action " + args->action + " can not be resolved.\n"));
//werror("********* action: %O\n", action);
  array uargs;
  mapping vars = ([]);

  if(args->args)
    uargs = get_var_value(args->args, data->get_data())/"/";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");

  if(sizeof(args)) 
  {
    vars = args;  
    foreach(args; string k; string v)
    {
      v = get_var_value(v, data->get_data()) || "";
      vars[k] = v;
    }
// werror("data: %O\n", data->get_data());
  }

  string url = data->get_request()->fins_app->url_for_action(action, uargs, vars);

  return url;
}


//! args: var
string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(get_var_value(args->var, data->get_data())||"");
}

//! args: var
//! if var is not provided, it is assumed to be "msg".
string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    if(!args->var) args->var = "$msg";
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

//! args: var
string simple_macro_describe_object(Fins.Template.TemplateData data, mapping|void args)
{
  mixed v = get_var_value(args->var, data->get_data());

  if(objectp(v) && v->describe) return v->describe();
  else return sprintf("%O\n", v);
}

//! args: var
string simple_macro_describe(Fins.Template.TemplateData data, mapping|void args)
{
  string key = get_var_value(args->key, data->get_data());
  mixed value = get_var_value(args->var, data->get_data());
  string rv = "";

    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(0, key, value);
    else if(objectp(value))
      rv += describe_object(0, key, value);

  return rv;
}
