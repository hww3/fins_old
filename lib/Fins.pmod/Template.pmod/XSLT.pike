//! Beginning of an XSLT templating system.

inherit .Template;

#if constant(Public.Parser.XML2)

import Public.Parser;

string templatename;
XML2.Stylesheet stylesheet;

static void create(string template)
{
   templatename = template + ".xslt";
   compile_template();
}

static void compile_template()
{
   string template = load_template(templatename);

   // first, we should parse the template to form an xml node object.

   XML2.Node n = XML2.parse_xml(template);
   
   XML2.Stylesheet s = XML2.parse_xslt(n);
 
   stylesheet = s;   
   
}

public string get_type()
{
   string s;

   s = stylesheet->media_type();

   if(s)
     return s;
   else return ::get_type();
}

public string render(.TemplateData d)
{   
   XML2.Node n;
   mapping dta;
   
   if(!d->get_data()["node"] || !objectp(d->get_data()["node"]))
   {
      throw(Error.Generic("Template.XSLT: no node to render.\n"));
   }
   else
   {
      dta = d->get_data();
      n = dta["node"];
      m_delete(dta, "node");
   }
   
   
   // This is ugly, but we have to do it, otherwise we can't cache templates.
   Thread.Mutex lock = Thread.Mutex();
   Thread.MutexKey key = lock->lock();
   
   mixed e = catch
   {
   
      stylesheet->set_attributes(dta);
      n = stylesheet->apply(n);
   };
   
   key = 0;
   
   if(e)
   {
      throw(e);
   }
   
   if(dta->output_encoding && intp(dta->output_encoding))
   {
      return stylesheet->output(n, dta->output_encoding);
   }
   else
   {
      return stylesheet->output(n);
   }
   
}

#endif /* constant(Public.Parser.XML2) */
