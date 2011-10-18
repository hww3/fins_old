import Tools.Logging;
import Fins;
inherit FinsBase : base;
inherit Fins.Helpers.Macros.JavaScript;
inherit Fins.Helpers.Macros.Basic;
inherit Fins.Helpers.Macros.Scaffolding;

Tools.Logging.Log.Logger log = get_logger("fins.view");

//! the default class to be used for templates in this application
program default_template = Fins.Template.Simple;
program default_string_template = Fins.Template.StringSimple;

//! the default template data object class for use in this application
program default_data = Fins.Template.TemplateData;

//! the default template context class to be used in this application
program default_context = Fins.Template.TemplateContext;

static mapping templates = ([]);
static mapping simple_macros = ([]);

//! the base View class

//!
static void create(object app)
{
	base::create(app);
    
	load_macros();
}

static void load_macros()
{
  foreach(glob("simple_macro_*", indices(this)); ; string mf)
  {
    log->debug("loading macro %O", mf[13..]);
    add_simple_macro(mf[13..], this[mf]);
  }
}

//!
public void add_simple_macro(string name, function macrocode)
{
  simple_macros[name] = macrocode;
}

//!
public function get_simple_macro(string name)
{
  return simple_macros[name];
}

//!
public string render_partial(string view, mapping data, 
                                 string|void collection_name, mixed|void collection, void|Fins.Request request)
{
//werror("render_partial(%O)\n", request);
	string result = "";
	object v = get_view(view);

	if(collection_name)
	{
		if(request)
                  v->data->set_request(request);
		foreach(collection;mixed i; mixed c)
		{
			mapping d = data + ([]);
			d[collection_name] = c;
                        d->id = i;

			v->data->set_data(d);
			result += v->render();
		}
	}
        else
	{
		if(request)
                  v->data->set_request(request);
		v->data->set_data(data);
		result += v->render();
	}	

	return result;
}

//! create a view using the template program specified. 
//! @param templateType
//!      a program implementing Fins.Template.Template
//!
//!  @param tn
//!     a string passed to the constructor of the template program.
//!     the meaning of this value will vary depending on the template
//!     implementation. often, this is the name of the template to load,
//!     or it may be the actual content of the template, for example in 
//!     @[Fins.Template.StringSimple].
public Template.View low_get_view(program templateType, string tn)
{
  object t;

  t = low_get_template(templateType, tn);

  object d = default_data();

  d->set_data((["config": config])); 

  return Template.View(t, d);
}

//! get a view using the default string template type. 
//!
//! @param ts
//!   a string to be used as the template data
//!
//! app config is added as a value to the template data object as the value "config".
public Template.View get_string_view(string ts)
{
  return low_get_view(default_string_template, ts);
}

//! get a view using the default template type. 
//!
//! @param tn
//!   a string containing the name of the template to load. how this is loaded is dependent on
//!   the behavior of the specified default template type
//!
//! app config is added as a value to the template data object as value "config".
public Template.View get_view(string tn)
{
  return low_get_view(default_template, tn);
}

//!
public Template.Template low_get_template(program templateType, string templateName, void|object context, int|void is_layout)
{
  object t;

// werror("low_get_template(%O, %O, %O, %O)\n", templateType, templateName, context, is_layout);

  if(!context) 
  {
    context = default_context();
    context->application = app;
	context->view = this;
  }

  if(!templateName || !stringp(templateName))
    throw(Error.Generic("get_template(): template name not specified.\n"));

  if(!templates[templateType])
  {
    templates[templateType] = ([]);
  }

  if(!(t = templates[templateType][templateName]))
  {
    t = templateType(templateName, context, is_layout);

    if(!t)
    {
      throw(Error.Generic("get_template(): unable to load template " + templateName + "\n"));
    }

    templates[templateType][templateName] = t;
  }

//  if(t) werror("success.\n");

  return t;

}

//!
public int flush_template(string templateName)
{
   foreach(templates;; mapping templateT)
   if(templateT[templateName])
   {
      m_delete(templateT, templateName);
      return 1;
   }
   return 0;
}

//!
public int flush_templates()
{
  templates = ([]);
}

