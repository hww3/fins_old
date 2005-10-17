static mapping templates = ([]);

public .Template get_template(program templateType, string templateName)
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
    t = templateType(templateName);
  
    if(!t)
    {
      throw(Error.Generic(get_template(): unable to load template " + templateName + "\n"));
    }

    templates[templateType][templateName] = t;
  }

  return templates[templateType][templateName];

}
