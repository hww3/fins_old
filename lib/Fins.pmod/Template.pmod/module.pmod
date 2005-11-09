static mapping templates = ([]);
static mapping simple_macros = ([]);

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
public .Template get_template(program templateType, string templateName, void|object context)
{
  object t;
  
  if(!sizeof(templateName))
    throw(Error.Generic("get_template(): template name not specified.\n"));

  if(!templates[templateType])
  {
    templates[templateType] = ([]);
  }

  if(!templates[templateType][templateName])
  {
    t = templateType(templateName, context);
  
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
