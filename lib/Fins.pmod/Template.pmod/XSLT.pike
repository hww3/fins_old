//! Beginning of an XSLT templating system.

inherit Fins.Template;

#if constant(Public.Parser.XML2)

import Fins.Template;
import Public.Parser;

string templatename;
XML2.Stylesheet stylesheet;

static void create(string template)
{
   templatename = template;
   compile_template();
}

static void compile_template()
{
   string template = load_template(templatename);

   // first, we should parse the template to form an xml node object.
   
   XML2.Node n = XML2.parse_xml(template);
   
   s = XML2.parse_stylesheet(n);
 
   stylesheet = s;   
   
}

public string render(TemplateData d)
{   
   XML2.Node n;
   
   if(!d->get_data()["node"] || !objectp(d->get_data()["node"]))
   {
      throw(Error.Generic("Template.XSLT: no node to render.\n"));
   }
   
   mapping dta = d->get_data();
   m_delete(dta, "node");
   
   // This is ugly, but we have to do it, otherwise we can't cache templates.
   Thread.Mutex lock = Mutex.Lock();
   Thread.MutexKey key = lock->lock();
   
   mixed e = catch
   {
   
      stylesheet->set_attributes(dta);
      n = stylesheet->apply(d->get_data()["node"]);
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