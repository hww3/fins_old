import Tools.Logging;
import Fins;
inherit FinsBase : base;
inherit Fins.Helpers.Macros.JavaScript;
inherit Fins.Helpers.Macros.Basic;
inherit Fins.Helpers.Macros.Scaffolding;

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
    Log.debug("loading macro %O", mf[13..]);
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
                                 string|void collection_name, mixed|void collection)
{
	string result = "";
	object v = get_view(view);

	if(collection_name)
	{
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
		v->data->set_data(data);
		result += v->render();
	}	

	return result;
}

//!
public Template.View low_get_view(program templateType, string tn)
{
  object t;

  t = low_get_template(templateType, tn);

  object d = default_data();

  d->set_data((["config": config])); 

  return Template.View(t, d);
}

public Template.View get_string_view(string ts)
{
  return low_get_view(default_string_template, ts);
}

public Template.View get_view(string tn)
{
  return low_get_view(default_template, tn);
}

//!
public Template.Template low_get_template(program templateType, string templateName, void|object context, int|void is_layout)
{
  object t;
  if(!context) 
  {
    context = default_context();
    context->application = app;
	context->view = this;
  }

  if(!templateName || !sizeof(templateName))
    throw(Error.Generic("get_template(): template name not specified.\n"));

  if(!templates[templateType])
  {
    templates[templateType] = ([]);
  }

  if(!templates[templateType][templateName])
  {
    t = templateType(templateName, context, is_layout);

    if(!t)
    {
      throw(Error.Generic("get_template(): unable to load template " + templateName + "\n"));
    }

    templates[templateType][templateName] = t;
  }

  return templates[templateType][templateName];

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

