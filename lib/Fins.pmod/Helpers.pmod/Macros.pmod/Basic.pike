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
if(!r)
{
  return args["string"];
}
else
	return Locale.translate(r->get_project(), r->get_lang(), 
					(int)args["id"], args["string"]);
}

//! args: var
string simple_macro_humanize(Fins.Template.TemplateData data, mapping|void args)
{
//	werror("humanize: %O\n", args->var);
  return Tools.Language.Inflect.humanize(args->var || "");
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

//! populate a data field with a mapping containing available language codes (keys) and native names (values)
//!
//! args: name
string simple_macro_available_languages(Fins.Template.TemplateData data, mapping|void args)
{
    // we do this to force a language update, if it hasn't happened already.
    string lang = data->get_request()->get_lang();
    data->get_data()[args->name] = data->get_request()->fins_app->available_languages();	
	return "";
}

//! produce a drop down language selector
//!
//! args: text
string simple_macro_language_selector(Fins.Template.TemplateData data, mapping|void args)
{
	String.Buffer buf = String.Buffer();

    // we do this to force a language update, if it hasn't happened already.
    string lang = data->get_request()->get_lang();
 	mapping l = data->get_request()->fins_app->available_languages();	

	buf += "<form id=\"language_form\">\n";
        buf += (args->text || "Language: ");
        buf += "<input type=\"hidden\" name=\"qd\" value=\"" + time() + "\">";
	buf += "<select name=\"_lang\" ";
	buf += "onChange=\"document.getElementById('language_form').submit();\"";
	buf += ">\n";

	foreach(l; string k; string v)
	{
           if(k == lang)
		buf += "<option selected=\"1\" value=\"" + k + "\">" + v + "</option>\n";
           else
		buf += "<option value=\"" + k + "\">" + v + "</option>\n";
	}

	buf += "</select>\n</form>\n";

	return buf->get();
}



//! args: controller, action, args 
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_link(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
  object request = data->get_request();
  string event = "index";
  if(args->action)
    event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = data->get_request()->fins_app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_link: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_link: action " + args->action + " can not be resolved.\n"));

  array uargs;

  if(args->args)
    uargs = ((string)args->args)/"/";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");

  string url = data->get_request()->fins_app->url_for_action(action, uargs, args);

  return "<a href=\"" + url + "\">";
}

//! args: controller, action, args, method, enctype
//!
//! any arguments other than those above will be considered variables to 
//! be added to the url above.
string simple_macro_action_form(Fins.Template.TemplateData data, mapping|void args)
{
  object controller;
  object request = data->get_request();
  string event = "index";
  if(args->action)
    event = args->action;
//  if(!event) throw(Error.Generic("action_form: event name must be provided.\n"));

  controller = request->controller;
  if(args->controller)
    controller = data->get_request()->fins_app->get_controller_for_path(args->controller, controller);
  if(!controller) throw(Error.Generic("action_form: controller " + args->controller + " can not be resolved.\n"));

  mixed action = controller[event];
  if(!action) throw(Error.Generic("action_form: action " + args->action + " can not be resolved.\n"));

  array uargs;

  if(args->args)
    uargs = args->args/"/";

  string other = "";

  if(args->method) other += " method=\"" + args->method + "\"";
  if(args->enctype) other += " method=\"" + args->enctype + "\"";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");
  m_delete(args, "method");
  m_delete(args, "enctype");

  string url = data->get_request()->fins_app->url_for_action(action, uargs, args);

  return "<form action=\"" + url + "\"" + other + ">";
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

  if(args->args)
    uargs = args->args/"/";

  m_delete(args, "controller");
  m_delete(args, "action");
  m_delete(args, "args");

  string url = data->get_request()->fins_app->url_for_action(action, uargs, args);

  return url;
}

//! args: none required, arg "mandatory" may be specified
//!
//! generates an input tag with any args passed along
//!  and a value in the request's variables mapping used to fill the default value
string simple_macro_input(Fins.Template.TemplateData data, mapping|void args)
{
//werror("******* input\n");
  object request = data->get_request();
  string event = args->action;
//  if(!event) throw(Error.Generic("action_link: event name must be provided.\n"));
  mixed v;

  if(!args) args = ([]);

  if(args->name && (v = request->variables[args->name]))
    args->value = v;

  String.Buffer buf = String.Buffer();
  buf->add("<input");
  foreach(args;string s;string v)
  { 
    buf->add(" " + s + "=\"" + v + "\""); 
  }
  buf->add("/>");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }

  return buf->get();
}

//! args: none required, args "mandatory", "default_value", "options"  may be specified
//!
//! options may point to an array of strings or an array of 2 element arrays, where the first element
//! is the value name and the second element is the value to display to the user in the drop-down.
//!
//! generates a select tag with any args passed along
//!  and a value in the request's variables mapping used to fill the default value
string simple_macro_select(Fins.Template.TemplateData data, mapping|void args)
{
  object request = data->get_request();
  string event = args->action;
  mixed v;
  String.Buffer buf = String.Buffer();

  if(!args) args = ([]);

  if(args->name && (v = request->variables[args->name]))
    args->value = v;

  array valid_options = args->options;
  string value = args->value || args->default_value;

  m_delete(args, "value");
  m_delete(args, "default_value");
  m_delete(args, "options");

  buf->add("<select");

  foreach(args; string s;string v)
  { 
    buf->add(" " + s + "=\"" + v + "\""); 
  }

  buf->add("/>\n");

  foreach(valid_options;; string|array vo)
  {
    string dn = ""; // display name
    string vn = ""; // value name

    if(arrayp(vo)) { dn = vo[1]; vn = vo[0]; }
    else 
    {
      vn = vo;
      dn = vo;
      buf->add("<option value=\"" + vn + "\"");

      if(vn == value)
        buf->add(" selected=\"1\"");

      buf->add(">");
      buf->add(dn);
      buf->add("</option>\n");
    }  
  }
  

  buf->add("</select>\n");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }
  return buf->get();
}


//! args: none required, arg "mandatory" may be specified
//!
//! generates a textarea with any args passed along
//!  and a value in the request's variables mapping used to fill the default value
string simple_macro_textarea(Fins.Template.TemplateData data, mapping|void args)
{
  object request = data->get_request();
  string event = args->action;
  mixed v;

  if(!args) args = ([]);

  if(args->name && (v = request->variables[args->name]))
    args->value = v;

  string value = args->value || "";
  m_delete(args, "value");

  String.Buffer buf = String.Buffer();
  buf->add("<textarea");
  foreach(args;string s;string v)
  { 
    buf->add(" " + s + "=\"" + v + "\""); 
  }
  buf->add("/>");
  buf->add(value);  
  buf->add("</textarea>");

  if(args->mandatory && lower_case(args->mandatory) != "false")
  {
	if(!args->value || !sizeof(args->value))
	{
		buf->add("<font class=\"mandatory\" *</font>");
	}
  }

  return buf->get();
}

//! args: var
string simple_macro_autoformat(Fins.Template.TemplateData data, mapping|void args)
{
    return replace(args->var||"", ({"\n\n", "\n"}), ({"<p/>", "<br/>"}));
}

//! args: var
string simple_macro_capitalize(Fins.Template.TemplateData data, mapping|void args)
{
    return String.capitalize(args->var||"");
}

//! args: var
//! if var is not provided, it is assumed to be "msg".
string simple_macro_flash(Fins.Template.TemplateData data, mapping|void args)
{
    if(!args->var) args->var = "msg";
    return (data->get_flash()[args->var]||"");
}

//! args: var
string simple_macro_sizeof(Fins.Template.TemplateData data, mapping|void args)
{
    return (string)(sizeof(args->var ||({})));
}

//! args: var, splice, final
string simple_macro_implode(Fins.Template.TemplateData data, mapping|void args)
{
  mixed v = args->var;

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
        mixed v = args->var;
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
  mixed v = args->var;

  if(objectp(v) && v->describe) return v->describe();
  else return sprintf("%O\n", v);
}

//! args: var
string simple_macro_describe(Fins.Template.TemplateData data, mapping|void args)
{
  string key = args->key;
  mixed value = args->var;
  string rv = "";

    if(stringp(value) || intp(value))
      rv += value; 
    else if(arrayp(value))
      rv += describe_array(0, key, value);
    else if(objectp(value))
      rv += describe_object(0, key, value);

  return rv;
}

//! display a calendar object as a distance in the past in a friendly manner 
//!
//! args: var
string simple_macro_friendly_date(Fins.Template.TemplateData data, mapping|void args)
{
  return Tools.String.friendly_date(args->var);
}


//! display a calendar object in a friendly manner using a format appropriate to the
//! time interval the calendar object represents (week, month, second, etc)
//!
//! args: var
string simple_macro_describe_date(Fins.Template.TemplateData data, mapping|void args)
{
  return Tools.String.describe_date(args->var);
}

//! display a calendar object as a date and time in a friendly manner
//!
//! args: var
string simple_macro_describe_datetime(Fins.Template.TemplateData data, mapping|void args)
{
  if(args->var && args->var->format_ext_time_short)
    return args->var->format_ext_time_short();
  else return "N/A";
}

//! provides the context root of this application, if any
//!
string simple_macro_context_root(Fins.Template.TemplateData data, mapping|void args)
{
  return data->get_request()->fins_app->context_root;
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
